# -*- coding: utf-8 -*-
"""
Builds the website pages in the website/ folder from tools/site_content.py
Run:  python tools/build_site.py
The full URLs (__SITE_URL__ and __REPO_URL__) are filled in automatically at publish time in .github/workflows/pages.yml
"""
import json, os, html, sys, re, hashlib, base64
sys.path.insert(0, os.path.dirname(__file__))
from site_content import C, G, LANGS, VERSION, BRAND, GUIDE_PUBLISHED, SITE_UPDATED, SITE_VERIFICATION

ROOT = os.path.join(os.path.dirname(__file__), "..", "website")
SITE = "__SITE_URL__"
REPO = "__REPO_URL__"
DL = REPO + "/releases/latest/download/DualPrint.zip"
e = html.escape

def path_of(lang):           # Page path relative to the site root
    return "" if lang == "en" else lang + "/"

def guide_path(lang):
    return "guide/" if lang == "en" else lang + "/guide/"

def guide_url(lang):
    return SITE + "/" + guide_path(lang)

def url_of(lang):
    return SITE + "/" + path_of(lang)

ICONS = ["M6 9V3h12v6M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M6 14h12v7H6z",  # printer
         "M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9zM14 3v6h6M9 15h6",                          # pdf/file
         "M4 7h16M4 12h10M4 17h6",                                                                              # names
         "M3 7h18v13H3zM8 7V4h8v3",                                                                             # several
         "M6 2h9l5 5v15H6zM9 13h6M9 17h6",                                                                      # paper
         "M12 8v4l3 2M21 12a9 9 0 1 1-3-6.7M21 3v5h-5",                                                         # history
         "M12 2v4M12 18v4M4.9 4.9l2.8 2.8M16.3 16.3l2.8 2.8M2 12h4M18 12h4M4.9 19.1l2.8-2.8M16.3 7.7l2.8-2.8",  # background
         "M3 5h12M9 3v2M5 9c1.5 4 4.5 7 9 9M13 9c-1 3-3.5 6-8 8M14 21l4-9 4 9M15.5 18h5",                       # languages
         "M12 3l1.9 4.6L18.5 9l-4.6 1.9L12 15.5l-1.9-4.6L5.5 9l4.6-1.4zM19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"]  # easy setup (sparkle)

def svg(d, size=22):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
            f'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{d}"/></svg>')

APP_LANGS = {"en", "ar", "es", "fr", "de"}   # App UI languages (app screenshots)
FEAT_KEEP = [8, 0, 1, 3, 6, 7]   # Features shown (keep it short)
FAQ_KEEP = [0, 1, 2, 5]           # FAQ entries shown

def vis(text, rtl):
    """Escapes visible text; in Arabic, isolates English phrases between «» so they do not get jumbled"""
    t = e(text)
    if rtl:
        t = re.sub(r'«([^»]*[A-Za-z][^»]*)»', r'«<bdi>\1</bdi>»', t)
        t = re.sub(r'(\S+_\d{4}-\d{2}-\d{2}_[\d-]+\.pdf)', r'<bdi dir="ltr">\1</bdi>', t)   # File names
    return t

def footer_text(text, rtl):
    """Footer line; in Arabic, isolates Latin words (product names) so the parentheses do not get reordered"""
    t = e(text)
    if rtl:
        t = re.sub(r'([A-Za-z][A-Za-z0-9]*)', r'<bdi>\1</bdi>', t)
    return t

def verification_meta():
    """Search engine site-verification tags (Search Console etc.); nothing when the token is empty"""
    return "".join(f'<meta name="{n}" content="{e(v)}">\n' for n, v in SITE_VERIFICATION.items() if v.strip())

def h1_lines(text):
    """Large headline: each sentence on its own line (Apple style)"""
    parts = [x for x in re.split(r'(?<=\.)\s+', text) if x]
    return '<br>'.join(e(x) for x in parts)

# 'mp-lang' is the localStorage key for the visitor's chosen language. It is kept from the
# 2.x site on purpose (F005): renaming it would forget every saved choice.
PAGE_JS = '''<script>
(function () {
  var d = document.documentElement; d.classList.add('js');
  var nav = document.querySelector('.nav');
  function edge() { nav.classList.toggle('scrolled', window.scrollY > 4); }
  edge(); window.addEventListener('scroll', edge, { passive: true });
  var items = document.querySelectorAll('.reveal');
  if (!('IntersectionObserver' in window)) { items.forEach(function (el) { el.classList.add('in'); }); return; }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); } });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
  items.forEach(function (el, i) {
    var sib = el.parentElement ? Array.prototype.indexOf.call(el.parentElement.children, el) : 0;
    el.style.transitionDelay = Math.min(sib, 4) * 60 + 'ms';
    io.observe(el);
  });
  document.querySelectorAll('.lang .menu a, .foot .langs a').forEach(function (a) {
    a.addEventListener('click', function () { try { localStorage.setItem('mp-lang', a.getAttribute('hreflang')); } catch (e) {} });
  });
  document.querySelectorAll('.lang').forEach(function (m) {
    document.addEventListener('pointerdown', function (e) { if (m.open && !m.contains(e.target)) m.open = false; });
  });
})();
</script>'''


def page(lang):
    c = dict(C[lang])
    shot = lang if lang in APP_LANGS else "en"   # The app itself has no Russian, so the Russian page shows the English screenshot
    c["faqs"] = [c["faqs"][i] for i in FAQ_KEEP]
    rel = "" if lang == "en" else "../"
    alternates = "\n".join(f'<link rel="alternate" hreflang="{l}" href="{url_of(l)}">' for l in LANGS)
    alternates += f'\n<link rel="alternate" hreflang="x-default" href="{url_of("en")}">'
    cur = ' aria-current="page"'
    langmenu = "".join(
        f'<a href="{rel}{path_of(l)}" hreflang="{l}" lang="{l}"{cur if l == lang else ""}>{e(C[l]["name"])}</a>'
        for l in LANGS)
    ld_app = {
        "@context": "https://schema.org", "@type": "SoftwareApplication",
        "name": BRAND, "operatingSystem": "Windows 10, Windows 11",
        "applicationCategory": "BusinessApplication", "applicationSubCategory": "Printing",
        "softwareVersion": VERSION, "description": c["desc"], "url": url_of(lang), "downloadUrl": DL,
        "image": SITE + f"/assets/screenshot-{shot}.png", "inLanguage": lang,
        "license": "https://opensource.org/licenses/MIT", "isAccessibleForFree": True,
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
        "featureList": [t for t, _ in c["feats"]],
    }
    ld_faq = {"@context": "https://schema.org", "@type": "FAQPage",
              "mainEntity": [{"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in c["faqs"]]}
    chev = '<span class="chev" aria-hidden="true">›</span>' if c["dir"] == "ltr" else '<span class="chev" aria-hidden="true">‹</span>'
    specs = "".join(f'<div class="spec reveal"><strong>{e(v)}</strong><span>{e(t)}</span></div>' for v, t in c["specs"])
    steps = "".join(f'<li class="tile reveal"><span class="num">{i+1}</span><h3>{e(t)}</h3><p>{e(d)}</p></li>' for i, (t, d) in enumerate(c["steps"]))
    feats = "".join(f'<div class="tile feat reveal">{svg(ICONS[i], 28)}<h3>{vis(c["feats"][i][0], c["dir"] == "rtl")}</h3><p>{vis(c["feats"][i][1], c["dir"] == "rtl")}</p></div>' for i in FEAT_KEEP)
    uses = "".join(f'<div class="tile dark reveal"><h3>{e(t)}</h3><p>{e(d)}</p></div>' for t, d in c["uses"])
    rtl = c["dir"] == "rtl"
    faqs = "".join(f'<details><summary><span>{vis(q, rtl)}</span><span class="plus" aria-hidden="true"></span></summary><p>{vis(a, rtl)}</p></details>' for q, a in c["faqs"])
    og_alt = "".join(f'<meta property="og:locale:alternate" content="{C[l]["locale"]}">' for l in LANGS if l != lang)
    autolang = ""
    if lang == "en":
        codes = [l for l in LANGS if l != "en"]
        autolang = ("<script>(function(){try{var s=localStorage.getItem('mp-lang');if(s)return;"
                    "var l=(navigator.language||'').slice(0,2).toLowerCase();"
                    f"if({json.dumps(codes)}.indexOf(l)>-1)location.replace(l+'/');}}catch(e){{}}}})();</script>\n")
    fonts = ('<link rel="preconnect" href="https://fonts.googleapis.com">\n<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
             '<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">') if lang == "ar" else ""
    return add_csp(f"""<!doctype html>
<html lang="{lang}" dir="{c['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="google-site-verification" content="kWrWM9pZ7TwlqT1FOuEBg3BxNEHowVKEepRebHDUjxc">
<title>{e(c['title'])}</title>
<meta name="description" content="{e(c['desc'])}">
<meta name="keywords" content="{e(c['keywords'])}">
<meta name="robots" content="index, follow">
{verification_meta()}<link rel="canonical" href="{url_of(lang)}">
{alternates}
<meta property="og:type" content="website">
<meta property="og:site_name" content="{BRAND}">
<meta property="og:title" content="{e(c['title'])}">
<meta property="og:description" content="{e(c['desc'])}">
<meta property="og:url" content="{url_of(lang)}">
<meta property="og:image" content="{SITE}/assets/screenshot-{shot}.png">
<meta property="og:image:width" content="1620">
<meta property="og:image:height" content="1245">
<meta property="og:locale" content="{c['locale']}">
{og_alt}
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#f5f5f7" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)">
<meta name="color-scheme" content="light dark">
<link rel="icon" href="{rel}assets/favicon.svg" type="image/svg+xml">
{fonts}
<link rel="stylesheet" href="{rel}assets/style.css">
<script type="application/ld+json">{json.dumps(ld_app, ensure_ascii=False)}</script>
<script type="application/ld+json">{json.dumps(ld_faq, ensure_ascii=False)}</script>
<script type="application/ld+json">{json.dumps({"@context": "https://schema.org", "@type": "WebSite", "name": BRAND, "url": url_of(lang), "inLanguage": lang}, ensure_ascii=False)}</script>
</head>
<body>
{autolang}<header class="nav">
  <div class="wrap navbar">
    <a class="brand" href="{rel}{path_of(lang)}" aria-label="{BRAND}">{svg(ICONS[0], 18)}<span>{BRAND}</span></a>
    <nav class="links">
      <a href="#how">{e(c['nav_how'])}</a><a href="#features">{e(c['nav_features'])}</a><a href="#faq">{e(c['nav_faq'])}</a><a href="{rel}{guide_path(lang)}">{e(G[lang]['nav'])}</a>
    </nav>
    <details class="lang"><summary aria-label="{e(c['langlabel'])}">{svg("M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3.6 9h16.8M3.6 15h16.8M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18", 15)}<span>{e(c['name'])}</span></summary><div class="menu">{langmenu}</div></details>
    <a class="navbtn" href="{DL}">{e(c['dl'])}</a>
  </div>
</header>

<main>
<section class="hero">
  <div class="wrap">
    <p class="eyebrow">{e(c['eyebrow'])}</p>
    <h1 class="reveal">{h1_lines(c['h1'])}</h1>
    <p class="lead">{e(c['sub'])}</p>
    <div class="actions">
      <a class="btn" href="{DL}">{e(c['dl'])}</a>
      <a class="link" href="#how">{e(c['learn'])} {chev}</a>
    </div>
    <p class="note">{e(c['dl_note']).replace('Windows 10 / 11', '<bdi dir="ltr">Windows 10 / 11</bdi>')} · <bdi dir="ltr">v{VERSION}</bdi></p>
  </div>
  <figure class="shot reveal"><img src="{rel}assets/screenshot-{shot}.png" width="1620" height="1245" alt="{e(c['alt'])}" loading="eager" fetchpriority="high"></figure>
</section>

<section class="specs-band">
  <div class="wrap specs">{specs}</div>
</section>

<section id="how" class="band light">
  <div class="wrap">
    <h2 class="reveal">{e(c['how_title'])}</h2>
    <ol class="tiles three">{steps}</ol>
    <p class="guide-link"><a class="link" href="{rel}{guide_path(lang)}">{e(G[lang]['h1'])} {chev}</a></p>
  </div>
</section>

<section id="features" class="band">
  <div class="wrap">
    <h2 class="reveal">{e(c['feat_title'])}</h2>
    <div class="tiles four">{feats}</div>
  </div>
</section>

<section class="band black">
  <div class="wrap">
    <h2 class="reveal">{e(c['use_title'])}</h2>
    <div class="tiles three">{uses}</div>
  </div>
</section>

<section id="faq" class="band light">
  <div class="wrap narrow">
    <h2 class="reveal">{e(c['faq_title'])}</h2>
    <div class="faq">{faqs}</div>
  </div>
</section>

<section class="band final">
  <div class="wrap">
    <h2 class="reveal">{e(c['cta_title'])}</h2>
    <p class="sublead">{e(c['cta_text'])}</p>
    <div class="actions">
      <a class="btn" href="{DL}">{e(c['dl'])}</a>
      <a class="link" href="{REPO}">{e(c['gh'])} {chev}</a>
    </div>
  </div>
</section>
</main>

<footer class="foot">
  <div class="wrap">
    <p class="langs">{langmenu}</p>
    <p><bdi dir="{c['dir']}">{footer_text(c['footer'], c['dir'] == 'rtl')}</bdi> · <bdi><a href="{REPO}/blob/main/LICENSE">{e(c.get('license', 'MIT License'))}</a></bdi> · <bdi><a href="{REPO}">GitHub</a></bdi> · <bdi><a href="{rel}{guide_path(lang)}">{e(G[lang]['nav'])}</a></bdi></p>
  </div>
</footer>
{PAGE_JS}
</body>
</html>
""")


def guide_page(lang):
    c = C[lang]; g = G[lang]; rtl = c["dir"] == "rtl"
    rel = "../" if lang == "en" else "../../"
    shot = lang if lang in APP_LANGS else "en"
    chev = '<span class="chev" aria-hidden="true">›</span>' if not rtl else '<span class="chev" aria-hidden="true">‹</span>'
    cur = ' aria-current="page"'
    langmenu = "".join(f'<a href="{rel}{guide_path(l)}" hreflang="{l}" lang="{l}"{cur if l == lang else ""}>{e(C[l]["name"])}</a>' for l in LANGS)
    alternates = "\n".join(f'<link rel="alternate" hreflang="{l}" href="{guide_url(l)}">' for l in LANGS)
    alternates += f'\n<link rel="alternate" hreflang="x-default" href="{guide_url("en")}">'
    why = "".join(f"<p>{vis(t, rtl)}</p>" for t in g["why"])
    steps = "".join(f'<li><h3>{vis(t, rtl)}</h3><p>{vis(d, rtl)}</p></li>' for t, d in g["steps"])
    faqs = "".join(f'<details><summary><span>{vis(q, rtl)}</span><span class="plus" aria-hidden="true"></span></summary><p>{vis(a, rtl)}</p></details>' for q, a in g["faq"])
    ld = [
        {"@context": "https://schema.org", "@type": "Article", "headline": g["h1"], "description": g["desc"],
         "inLanguage": lang, "url": guide_url(lang), "image": SITE + f"/assets/screenshot-{shot}.png",
         "datePublished": GUIDE_PUBLISHED, "dateModified": SITE_UPDATED,
         "author": {"@type": "Organization", "name": BRAND}, "publisher": {"@type": "Organization", "name": BRAND},
         "about": {"@type": "SoftwareApplication", "name": BRAND, "operatingSystem": "Windows 10, Windows 11"}},
        {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": BRAND, "item": url_of(lang)},
            {"@type": "ListItem", "position": 2, "name": g["nav"], "item": guide_url(lang)}]},
        {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}} for q, a in g["faq"]]},
    ]
    ldtags = "\n".join(f'<script type="application/ld+json">{json.dumps(x, ensure_ascii=False)}</script>' for x in ld)
    fonts = ('<link rel="preconnect" href="https://fonts.googleapis.com">\n<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
             '<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">') if lang == "ar" else ""
    return add_csp(f"""<!doctype html>
<html lang="{lang}" dir="{c['dir']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="google-site-verification" content="kWrWM9pZ7TwlqT1FOuEBg3BxNEHowVKEepRebHDUjxc">
<title>{e(g['title'])}</title>
<meta name="description" content="{e(g['desc'])}">
<meta name="robots" content="index, follow">
{verification_meta()}<link rel="canonical" href="{guide_url(lang)}">
{alternates}
<meta property="og:type" content="article">
<meta property="og:site_name" content="{BRAND}">
<meta property="og:title" content="{e(g['title'])}">
<meta property="og:description" content="{e(g['desc'])}">
<meta property="og:url" content="{guide_url(lang)}">
<meta property="og:image" content="{SITE}/assets/screenshot-{shot}.png">
<meta property="og:locale" content="{c['locale']}">
<meta name="twitter:card" content="summary_large_image">
<meta name="color-scheme" content="light dark">
<link rel="icon" href="{rel}assets/favicon.svg" type="image/svg+xml">
{fonts}
<link rel="stylesheet" href="{rel}assets/style.css">
{ldtags}
</head>
<body>
<header class="nav">
  <div class="wrap navbar">
    <a class="brand" href="{rel}{path_of(lang)}" aria-label="{BRAND}">{svg(ICONS[0], 18)}<span>{BRAND}</span></a>
    <nav class="links"><a href="{rel}{path_of(lang)}">{e(g['back'])}</a></nav>
    <details class="lang"><summary aria-label="{e(c['langlabel'])}">{svg("M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3.6 9h16.8M3.6 15h16.8M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18", 15)}<span>{e(c['name'])}</span></summary><div class="menu">{langmenu}</div></details>
    <a class="navbtn" href="{DL}">{e(c['dl'])}</a>
  </div>
</header>
<main>
<article class="article">
  <div class="wrap narrow">
    <nav class="crumbs" aria-label="breadcrumb"><a href="{rel}{path_of(lang)}">{BRAND}</a> {chev} <span>{e(g['nav'])}</span></nav>
    <h1>{e(g['h1'])}</h1>
    <p class="lead">{vis(g['lead'], rtl)}</p>
    <p><a class="btn" href="{DL}">{e(g['cta'])}</a></p>
    <h2>{e(g['why_t'])}</h2>
    {why}
    <h2>{e(g['steps_t'])}</h2>
    <ol class="gsteps">{steps}</ol>
    <figure class="gshot"><img src="{rel}assets/screenshot-{shot}.png" width="1620" height="1245" alt="{e(c['alt'])}" loading="lazy"></figure>
    <h2>{e(g['tip_t'])}</h2>
    <p>{vis(g['tip'], rtl)}</p>
    <h2>{e(c['faq_title'])}</h2>
    <div class="faq">{faqs}</div>
    <div class="gcta">
      <a class="btn" href="{DL}">{e(g['cta'])}</a>
      <a class="link" href="{rel}{path_of(lang)}">{e(g['back'])} {chev}</a>
    </div>
  </div>
</article>
</main>
<footer class="foot">
  <div class="wrap">
    <p class="langs">{langmenu}</p>
    <p><bdi dir="{c['dir']}">{footer_text(c['footer'], c['dir'] == 'rtl')}</bdi> · <bdi><a href="{REPO}">GitHub</a></bdi></p>
  </div>
</footer>
{PAGE_JS}
</body>
</html>
""")


def add_csp(doc):
    """Strict Content-Security-Policy: only scripts inline in the page are allowed (by hash)"""
    hashes = []
    for body in re.findall(r'<script>(.*?)</script>', doc, re.S):
        h = base64.b64encode(hashlib.sha256(body.encode('utf-8')).digest()).decode()
        hashes.append(f"'sha256-{h}'")
    csp = ("default-src 'self'; script-src " + " ".join(hashes) + "; style-src 'self' https://fonts.googleapis.com; "
           "font-src https://fonts.gstatic.com; img-src 'self' data:; connect-src 'none'; object-src 'none'; "
           "base-uri 'self'; form-action 'none'; upgrade-insecure-requests")
    meta = (f'<meta http-equiv="Content-Security-Policy" content="{csp}">\n'
            '<meta name="referrer" content="strict-origin-when-cross-origin">\n')
    return doc.replace('<meta charset="utf-8">\n', '<meta charset="utf-8">\n' + meta, 1)

CSS = """:root{--bg:#fff;--gray:#f5f5f7;--tile:#fff;--text:#1d1d1f;--muted:#6e6e73;--line:#d2d2d7;--blue:#0071e3;--blue2:#0077ed;--link:#0066cc;
--nav:rgba(251,251,253,.72);--menu:rgba(255,255,255,.78);--ease:cubic-bezier(.22,1,.36,1)}
@media (prefers-color-scheme:dark){:root{--bg:#000;--gray:#161617;--tile:#1d1d1f;--text:#f5f5f7;--muted:#a1a1a6;--line:#424245;--link:#2997ff;
--nav:rgba(22,22,23,.72);--menu:rgba(40,40,42,.78)}}
*{box-sizing:border-box}
html{scroll-behavior:smooth;-webkit-text-size-adjust:100%;font-size:100%}
body{margin:0;background:var(--bg);color:var(--text);
 font-family:-apple-system,BlinkMacSystemFont,system-ui,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
 font-size:1.0625rem;line-height:1.5;letter-spacing:0;-webkit-font-smoothing:antialiased;font-optical-sizing:auto;
 transition:background-color .4s ease,color .4s ease}
html[lang=ar] body{font-family:"IBM Plex Sans Arabic",-apple-system,system-ui,"Segoe UI",Tahoma,sans-serif;line-height:1.65}
a{color:var(--link);text-decoration:none}a:hover{text-decoration:underline}
img{max-width:100%;height:auto;display:block}
:focus-visible{outline:2px solid var(--blue);outline-offset:3px;border-radius:6px}
.wrap{max-width:64rem;margin:0 auto;padding:0 1.375rem}.narrow{max-width:47.5rem}

/* ---- nav: translucent material, content scrolls underneath (skill §12) ---- */
.nav{position:sticky;top:0;z-index:10;background:var(--nav);
 -webkit-backdrop-filter:saturate(180%) blur(20px);backdrop-filter:saturate(180%) blur(20px)}
.nav::after{content:"";position:absolute;inset:auto 0 -12px 0;height:12px;pointer-events:none;opacity:0;
 background:linear-gradient(to bottom,rgba(0,0,0,.06),transparent);transition:opacity .3s ease}
.nav.scrolled::after{opacity:1}
.navbar{height:3rem;display:flex;align-items:center;gap:1.375rem;font-size:.75rem;letter-spacing:.01em}
.brand{display:flex;align-items:center;gap:.45rem;color:var(--text);font-weight:600;font-size:.9375rem;letter-spacing:-.01em}.brand:hover{text-decoration:none}
.links{display:flex;gap:1.375rem;margin-inline-start:auto}.links a{color:var(--text);opacity:.8;transition:opacity .2s}.links a:hover{opacity:1;text-decoration:none}
.lang{position:relative}.lang summary{list-style:none;cursor:pointer;display:flex;align-items:center;gap:.35rem;padding:.3rem .7rem;border-radius:980px;border:1px solid var(--line);font-size:.75rem;color:var(--text)}.lang summary:hover{background:rgba(127,127,127,.1)}.lang summary::-webkit-details-marker{display:none}
.lang .menu{position:absolute;inset-inline-end:-.5rem;top:2.25rem;min-width:10rem;padding:.4rem;border-radius:1rem;
 background:var(--menu);-webkit-backdrop-filter:blur(30px) saturate(180%);backdrop-filter:blur(30px) saturate(180%);
 box-shadow:0 1px 0 rgba(255,255,255,.35) inset,0 18px 50px rgba(0,0,0,.18);transform-origin:top right}
html[dir=rtl] .lang .menu{transform-origin:top left}
.lang[open] .menu{animation:materialize .32s var(--ease) both}
@keyframes materialize{from{opacity:0;transform:scale(.94);filter:blur(6px)}to{opacity:1;transform:none;filter:none}}
.lang .menu a{display:block;padding:.5rem .75rem;border-radius:.6rem;color:var(--text);font-size:.875rem}
.lang .menu a:hover,.lang .menu a[aria-current]{background:rgba(127,127,127,.14);text-decoration:none}
.navbtn{white-space:nowrap;background:var(--blue);color:#fff;border-radius:980px;padding:.25rem .8rem;font-size:.75rem}
.navbtn:hover{background:var(--blue2);text-decoration:none}

/* ---- press feedback: instant, on pointer-down (skill §1) ---- */
.btn,.navbtn,.link,.faq summary,.lang summary{transition:transform .1s ease-out,background-color .2s,opacity .2s;-webkit-tap-highlight-color:transparent}
.btn:active,.navbtn:active{transform:scale(.97)}
.link:active,.lang summary:active{opacity:.55}
.faq summary:active{transform:scale(.995)}

/* ---- hero ---- */
.hero{background:var(--gray);text-align:center;padding:4.5rem 0 0;overflow:hidden}
.eyebrow{font-size:1.0625rem;font-weight:600;color:var(--muted);margin:0 auto .6rem;max-width:40rem;letter-spacing:.005em}
h1,h2{text-wrap:balance}
h1{font-size:clamp(2.5rem,7vw,5rem);line-height:1.05;font-weight:700;letter-spacing:-.025em;margin:0 auto 1rem;max-width:55rem}
.lead{font-size:clamp(1.1875rem,2.4vw,1.5rem);line-height:1.38;letter-spacing:-.005em;color:var(--muted);max-width:44rem;margin:0 auto 1.75rem}
html[lang=ar] h1,html[lang=ar] h2,html[lang=ar] .lead{letter-spacing:0}
html[lang=ar] h1{line-height:1.22}html[lang=ar] h2{line-height:1.28}
.actions{display:flex;flex-direction:column;gap:1.1rem;justify-content:center;align-items:center}
.btn{display:inline-block;background:var(--blue);color:#fff;border-radius:980px;padding:.75rem 1.5rem;font-size:1.0625rem;font-weight:500}
.btn:hover{background:var(--blue2);text-decoration:none}
.link{font-size:1.1875rem;display:inline-block}.chev{display:inline-block;margin-inline-start:.1rem}
.note{color:var(--muted);font-size:.875rem;letter-spacing:.01em;margin:1.1rem 0 3rem}
.shot{margin:0 auto;max-width:61.25rem;padding:0 1.375rem}
.shot img{border-radius:1.125rem 1.125rem 0 0;box-shadow:0 -2px 50px rgba(0,0,0,.12);border:1px solid rgba(127,127,127,.12);border-bottom:0}

/* ---- specs ---- */
.specs-band{border-bottom:1px solid var(--line)}
.specs{display:grid;grid-template-columns:repeat(4,1fr);text-align:center;padding:2.75rem 1.375rem}
.spec strong{display:block;font-size:clamp(2rem,4.5vw,3rem);font-weight:700;letter-spacing:-.02em;line-height:1.1}
.spec span{display:block;color:var(--muted);font-size:.9375rem;letter-spacing:.005em;margin-top:.4rem}

/* ---- bands & tiles ---- */
.band{padding:6rem 0;text-align:center}.band.light{background:var(--gray)}
h2{font-size:clamp(2rem,5vw,3.5rem);line-height:1.08;font-weight:700;letter-spacing:-.02em;margin:0 0 .9rem}
.sublead{font-size:1.3125rem;line-height:1.38;color:var(--muted);margin:0 auto 3rem;max-width:40rem}
.band h2+.tiles{margin-top:3rem}
.tiles{list-style:none;padding:0;margin:0;display:grid;gap:1.25rem;text-align:start}
.tiles.three{grid-template-columns:repeat(3,1fr)}.tiles.four{grid-template-columns:repeat(3,1fr)}
.tile{background:var(--tile);border-radius:1.75rem;padding:2rem 1.75rem}
.band:not(.light):not(.black) .tile{background:var(--gray)}
.num{font-size:2.75rem;font-weight:700;letter-spacing:-.02em;color:var(--blue);line-height:1;display:block;margin-bottom:1.1rem}
.tile h3{font-size:1.3125rem;line-height:1.2;letter-spacing:-.01em;margin:0 0 .5rem;font-weight:600}
.tile p{margin:0;color:var(--muted);font-size:1.0625rem}
.feat svg{color:var(--blue);margin-bottom:1.1rem}
.band.black{background:#000;color:#f5f5f7}.band.black h2{color:#f5f5f7}
.tile.dark{background:#1d1d1f}.tile.dark h3{color:#f5f5f7}.tile.dark p{color:#a1a1a6}

/* ---- faq ---- */
.faq{text-align:start;margin-top:2.5rem;border-top:1px solid var(--line)}
.faq details{border-bottom:1px solid var(--line)}
.faq summary{list-style:none;cursor:pointer;display:flex;justify-content:space-between;align-items:center;gap:1.25rem;padding:1.375rem 0;font-size:1.1875rem;font-weight:600;letter-spacing:-.005em}
.faq summary::-webkit-details-marker{display:none}
.plus{position:relative;flex:none;width:.875rem;height:.875rem}
.plus:before,.plus:after{content:"";position:absolute;inset:.375rem 0 auto 0;height:2px;background:var(--muted);border-radius:2px;transition:transform .35s var(--ease)}
.plus:after{transform:rotate(90deg)}.faq details[open] .plus:after{transform:rotate(0)}
.faq bdi{white-space:nowrap}
.faq p{margin:0 0 1.5rem;color:var(--muted);font-size:1.0625rem}
.faq details[open] p{animation:fadeup .35s var(--ease) both}
@keyframes fadeup{from{opacity:0;transform:translateY(-4px)}to{opacity:1;transform:none}}
.final h2{font-size:clamp(2.25rem,6vw,4rem)}

/* ---- guide link + guide page ---- */
.guide-link{margin:2.5rem 0 0}
.article{padding-block:3.5rem 5rem}
.article .wrap{text-align:start}
.crumbs{font-size:.875rem;color:var(--muted);margin-bottom:1.5rem}.crumbs a{color:var(--muted)}
.article h1{font-size:clamp(2rem,5vw,3.25rem);line-height:1.1;margin:0 0 1rem}
.article .lead{margin:0 0 1.75rem;text-align:start}
.article h2{font-size:clamp(1.5rem,3vw,2rem);margin:3rem 0 1rem;text-align:start}
.article p{font-size:1.125rem;line-height:1.7;margin:0 0 1rem;max-width:44rem}
.gsteps{list-style:none;counter-reset:s;padding:0;margin:0;display:grid;gap:.75rem}
.gsteps li{counter-increment:s;background:var(--gray);border-radius:1.25rem;padding:1.25rem 1.5rem 1.25rem 4.25rem;position:relative}
html[dir=rtl] .gsteps li{padding:1.25rem 4.25rem 1.25rem 1.5rem}
.gsteps li::before{content:counter(s);position:absolute;inset-inline-start:1.25rem;top:1.15rem;width:2rem;height:2rem;border-radius:50%;background:var(--blue);color:#fff;display:grid;place-items:center;font-weight:700}
.gsteps h3{margin:0 0 .3rem;font-size:1.1875rem}.gsteps p{margin:0;color:var(--muted);font-size:1.0625rem}
.gshot{margin:2rem 0 0}.gshot img{border-radius:1rem;border:1px solid var(--line)}
.gcta{display:flex;flex-wrap:wrap;gap:1.25rem;align-items:center;margin-top:3rem}
/* ---- footer ---- */
.foot{background:var(--gray);color:var(--muted);font-size:.75rem;letter-spacing:.01em;padding:1.25rem 0 2.1rem;border-top:1px solid var(--line)}
.foot p{margin:.6rem 0}.foot a{color:var(--text)}
.foot .langs{display:flex;flex-wrap:wrap;gap:.4rem 1.1rem;padding-bottom:.75rem;border-bottom:1px solid var(--line)}

/* ---- reveal on scroll: transform + opacity only (skill §11) ---- */
.js .reveal{opacity:0;transform:translateY(1.25rem);transition:opacity .7s var(--ease),transform .7s var(--ease)}
.js .reveal.in{opacity:1;transform:none}

/* ---- responsive ---- */
@media (max-width:56rem){.tiles.four{grid-template-columns:repeat(2,1fr)}}
@media (max-width:46rem){
  .links,.navbtn{display:none}.lang{margin-inline-start:auto}
  .hero{padding-top:3rem}.band{padding:4rem 0}
  .tiles.three,.tiles.four{grid-template-columns:1fr}
  .specs{grid-template-columns:repeat(2,1fr);row-gap:1.75rem}
  .tile{border-radius:1.375rem;padding:1.6rem 1.4rem}
  .shot{padding:0 .75rem}.shot img{border-radius:.75rem .75rem 0 0}
}

/* ---- accessibility preferences (skill §14) ---- */
@media (prefers-reduced-motion:reduce){
  html{scroll-behavior:auto}
  .js .reveal{transform:none;transition:opacity .2s ease}
  .lang[open] .menu,.faq details[open] p{animation:fade .2s ease both}
  @keyframes fade{from{opacity:0}to{opacity:1}}
  .btn:active,.navbtn:active,.faq summary:active{transform:none}
}
@media (prefers-reduced-transparency:reduce){
  .nav{background:var(--bg);-webkit-backdrop-filter:none;backdrop-filter:none}
  .lang .menu{background:var(--bg);-webkit-backdrop-filter:none;backdrop-filter:none}
}
@media (prefers-contrast:more){
  :root{--muted:var(--text);--line:currentColor}
  .nav{background:var(--bg);border-bottom:1px solid var(--text)}
  .tile{border:1px solid var(--text)}
}
"""

FAVICON = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="16" fill="#5B45E6"/><g fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 26V14h24v12M20 44h-4a4 4 0 0 1-4-4V30a4 4 0 0 1 4-4h32a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4h-4M20 36h24v14H20z"/></g></svg>"""

def main():
    os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
    for lang in LANGS:
        d = ROOT if lang == "en" else os.path.join(ROOT, lang)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "index.html"), "w", encoding="utf-8", newline="\n") as f:
            f.write(page(lang))
        gd = os.path.join(ROOT, guide_path(lang))
        os.makedirs(gd, exist_ok=True)
        with open(os.path.join(gd, "index.html"), "w", encoding="utf-8", newline="\n") as f:
            f.write(guide_page(lang))
    with open(os.path.join(ROOT, "assets", "style.css"), "w", encoding="utf-8", newline="\n") as f:
        f.write(CSS)
    with open(os.path.join(ROOT, "assets", "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(FAVICON)
    # sitemap with language links
    urls = []
    for lang in LANGS:
        alts = "".join(f'<xhtml:link rel="alternate" hreflang="{l}" href="{url_of(l)}"/>' for l in LANGS)
        alts += f'<xhtml:link rel="alternate" hreflang="x-default" href="{url_of("en")}"/>'
        urls.append(f"<url><loc>{url_of(lang)}</loc><lastmod>{SITE_UPDATED}</lastmod>{alts}<changefreq>monthly</changefreq><priority>{'1.0' if lang == 'en' else '0.9'}</priority></url>")
    for lang in LANGS:
        alts = "".join(f'<xhtml:link rel="alternate" hreflang="{l}" href="{guide_url(l)}"/>' for l in LANGS)
        alts += f'<xhtml:link rel="alternate" hreflang="x-default" href="{guide_url("en")}"/>'
        urls.append(f"<url><loc>{guide_url(lang)}</loc><lastmod>{SITE_UPDATED}</lastmod>{alts}<changefreq>monthly</changefreq><priority>0.8</priority></url>")
    with open(os.path.join(ROOT, "sitemap.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" '
                'xmlns:xhtml="http://www.w3.org/1999/xhtml">\n' + "\n".join(urls) + "\n</urlset>\n")
    with open(os.path.join(ROOT, "robots.txt"), "w", encoding="utf-8") as f:
        f.write(f"User-agent: *\nAllow: /\nSitemap: {SITE}/sitemap.xml\n")
    with open(os.path.join(ROOT, "404.html"), "w", encoding="utf-8") as f:
        # Real 404 status from GitHub Pages + noindex; the visitor sees a short message, then goes home
        f.write(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
                f'<meta name="robots" content="noindex"><title>Page not found – {BRAND}</title>'
                f'<meta http-equiv="refresh" content="5; url={SITE}/">'
                f'<body style="font-family:system-ui,sans-serif;text-align:center;padding:4rem 1rem">'
                f'<h1>Page not found</h1><p>This page does not exist. Taking you to the {BRAND} home page…</p>'
                f'<p><a href="{SITE}/">Go to {BRAND} now</a></p></body></html>\n')
    print("Website built in", os.path.abspath(ROOT))

if __name__ == "__main__":
    main()
