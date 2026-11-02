# T009 — Indexability audit: website and repo

| | |
|---|---|
| Project | `multiprint` |
| Task | T009: "seo must make sure that search engines can see the website and the repo" |
| Author | seo-specialist |
| Date | Nov 3, 2026 12:53 AM (Riyadh) |
| Mode | Read-only audit. Nothing edited, committed or changed in any account. |
| Live site | https://eslamfariedshawky.github.io/dualprinter/ (en, ar, ru, de, es, fr + `/guide/` per language = 12 pages) |
| Repo | https://github.com/eslamfariedshawky/dualprinter |

## Verdict

**Search engines can crawl and index the website now.** It has no technical blockers: every page returns 200, robots allows everything, the sitemap is valid and complete, and canonical/hreflang/lang are correct on all 12 pages. Nothing is indexed yet (expected, published today).

**The repo is the weak point.** Its About box is empty (no description, no website, no topics), and the README tells readers the site link "is in the About box". So right now **nothing on GitHub links to the site**, and Google has no path to discover it except a sitemap submission. The fix is the Owner pasting three fields (section 5). It needs no code change.

## 1. Pass/fail table

### Crawlability

| Check | Result | Evidence |
|---|---|---|
| All 12 pages return 200 | PASS | `/`, `/ar/`, `/ru/`, `/de/`, `/es/`, `/fr/` and each `.../guide/` → `200 text/html` |
| robots.txt allows crawling | PASS | `User-agent: *` / `Allow: /` |
| robots.txt points to the sitemap at the live URL | PASS | `Sitemap: https://eslamfariedshawky.github.io/dualprinter/sitemap.xml` |
| sitemap.xml valid, absolute live URLs | PASS | `200 application/xml`, sitemaps.org namespace, 12 `<loc>` with absolute `https://…/dualprinter/…` |
| sitemap lists every page with hreflang alternates | PASS | 12/12 URLs, each with 7 `xhtml:link` (6 languages + `x-default`) |
| sitemap `<lastmod>` | MINOR | Missing. Google ignores `changefreq`/`priority` but uses `lastmod`. |
| No `noindex` meta | PASS | Every content page has `<meta name="robots" content="index, follow">` |
| No `X-Robots-Tag` header | PASS | Not present in the response headers (`Server: GitHub.com`) |
| 404 page works | PASS | `/does-not-exist/` → **HTTP 404**, `noindex`, then an instant meta refresh to the home page. Search engines see a real 404 (no soft-404). Minor UX point: the visitor gets no "page not found" message. |
| Unreplaced placeholders | PASS | No `__SITE_URL__` or `__REPO_URL__` in any live page, robots or sitemap |

### Indexability per page

| Page | `lang`/`dir` | Title (chars) | Description (chars) | Canonical self, absolute | hreflang (7, x-default) | OG url/image | JSON-LD | H1 |
|---|---|---|---|---|---|---|---|---|
| `/` | en ltr | 58 PASS | 158 MINOR | PASS | PASS | PASS | App, FAQ, WebSite | 1 |
| `/ar/` | ar **rtl** | 56 PASS | 135 PASS | PASS | PASS | PASS | App, FAQ, WebSite | 1 |
| `/ru/` | ru ltr | 55 PASS | 156 MINOR | PASS | PASS | en screenshot (by design) | App, FAQ, WebSite | 1 |
| `/de/` | de ltr | 55 PASS | 141 PASS | PASS | PASS | PASS | App, FAQ, WebSite | 1 |
| `/es/` | es ltr | 51 PASS | 160 MINOR | PASS | PASS | PASS | App, FAQ, WebSite | 1 |
| `/fr/` | fr ltr | 57 PASS | 156 MINOR | PASS | PASS | PASS | App, FAQ, WebSite | 1 |
| `/guide/` | en ltr | 53 PASS | 158 MINOR | PASS | PASS | PASS | Article, App, Breadcrumb, FAQ | 1 |
| `/ar/guide/` | ar **rtl** | 52 PASS | 138 PASS | PASS | PASS | PASS | Article, App, Breadcrumb, FAQ | 1 |
| `/ru/guide/` | ru ltr | 57 PASS | 146 PASS | PASS | PASS | en screenshot (by design) | Article, App, Breadcrumb, FAQ | 1 |
| `/de/guide/` | de ltr | 55 PASS | 162 MINOR | PASS | PASS | PASS | Article, App, Breadcrumb, FAQ | 1 |
| `/es/guide/` | es ltr | 57 PASS | 155 PASS | PASS | PASS | PASS | Article, App, Breadcrumb, FAQ | 1 |
| `/fr/guide/` | fr ltr | 52 PASS | 151 PASS | PASS | PASS | PASS | Article, App, Breadcrumb, FAQ | 1 |

Notes:
- All 12 titles are unique. All hreflang sets are reciprocal and identical to the sitemap. `og:locale` matches each language.
- All JSON-LD blocks parse as valid JSON. They are honest: no `aggregateRating` or `review`, and the price is `0`, which is true.
- Every `<img>` has `alt`. Home pages link to `guide/` and to all languages, so internal linking is fine.
- "MINOR" descriptions run 1–7 characters over the 155 target. Google may cut the last word in the snippet. This does not affect indexing.
- The `Article` JSON-LD has no `datePublished`/`dateModified`. Google recommends both for articles.
- `<meta name="keywords">` is ignored by Google. It is harmless and can stay.

### Is it indexed?

| Query (WebSearch, Nov 3, 2026) | Result |
|---|---|
| `site:eslamfariedshawky.github.io/dualprinter` | **0 results**. Not indexed yet (expected, published today). |
| `"eslamfariedshawky/dualprinter"` | **0 results** for the repo. |

Side finding for F005: the same searches show the name **"dualPrint" is already used** by an unrelated GitHub project (`Cuperino/dualPrint`, a manual-duplex helper), a Mac app on Softpedia and a SourceForge project. "Dual printer" results are dominated by dual-extruder 3D printers. So after the rename, the brand alone will not rank us. The titles must keep the descriptive phrases ("print to two/multiple printers at once", "save PDF"), which they already do.

### Repo discoverability

| Check | Result | Evidence (live repo page) |
|---|---|---|
| Description set | **FAIL** | Page shows "No description, website, or topics provided"; meta description is GitHub's generic "Contribute to … development" |
| Website link set | **FAIL** | Empty |
| Topics set | **FAIL** | 0 topics |
| README clear H1 | PASS | `# MultiPrint`, followed by a clear one-line value statement |
| README keywords | PASS | "print to all your printers at once", "PDF copy", "virtual printer", Word/Excel, Windows |
| README links to the site | **FAIL** | Says "the link is in the *About* box". The About box is empty, so there is no link at all. |

## 2. Fixes ranked by impact

| # | Fix | Impact | Who | When |
|---|---|---|---|---|
| 1 | Fill the repo About box: description, website, topics (text in section 5) | High: gives the site its only inbound link, makes the repo searchable on GitHub and Google | Owner (GitHub setting) | **do now** (2 minutes; update the website field again at rename) |
| 2 | Add Google Search Console verification meta tag to the generator; Owner verifies, submits sitemap, requests indexing (section 3) | High: fastest route to indexing | seo-specialist (tag in `tools/build_site.py`) + Owner (account) | **fold into F005** (see section 4 for why) |
| 3 | README: replace "the link is in the About box" with the direct site URL | Medium: link plus a clear path for readers. GitHub marks README links `nofollow`, but crawlers still discover through them. | tech-writer / seo | **fold into F005** (README is rewritten there, and the URL changes) |
| 4 | Add `<lastmod>` (build date) to every sitemap `<url>` | Low–medium: helps recrawl after the rename | seo-specialist (generator) | **fold into F005** |
| 5 | Add `datePublished` / `dateModified` to the guide `Article` JSON-LD | Low | seo-specialist (generator) | **fold into F005** |
| 6 | Trim 6 meta descriptions to ≤ 155 characters (en home, en guide, ru home, es home, fr home, de guide) | Low (snippet cut only) | seo-specialist (`tools/site_content.py`) | **fold into F005** (every description is rewritten for "DualPrint" anyway) |
| 7 | Optional: 404 page shows a short "Page not found → home" message instead of an instant redirect | Low (UX) | seo-specialist / frontend-dev | **fold into F005** |

No "do now" code change is worth an extra push/deploy cycle before F005. Only fix 1 (an Owner setting) should happen now.

## 3. Owner steps to get indexed (do these after the rename; see section 4)

**Google Search Console** (the Owner's Google account):
1. Open https://search.google.com/search-console → **Add property** → choose **URL prefix** (not Domain; we don't own `github.io`).
2. Enter exactly `https://eslamfariedshawky.github.io/dualprint/` (with the trailing slash, the final URL).
3. Choose **HTML tag**. Copy only the `content="…"` value and send it to the CEO. **Don't click Verify yet.**
4. The team adds `<meta name="google-site-verification" content="…">` to every page head through the generator. This is an approved change, then a deploy. The token is not a secret, so it is safe to commit.
5. After the deploy, click **Verify**.
6. Go to **Sitemaps** → enter `sitemap.xml` → **Submit**. Expected status: "Success", 12 discovered URLs.
7. Go to **URL inspection** → paste the home URL → **Request indexing**. Repeat for `…/ar/` and `…/guide/`. One per language is optional; the sitemap covers the rest. There is a daily quota, so don't spam it.
8. Check **Pages** (indexing report) after 3–7 days.

**Bing Webmaster Tools** (also feeds DuckDuckGo, Yahoo and Ecosia):
1. Open https://www.bing.com/webmasters → sign in → **Import from Google Search Console**. This copies the verified site and its sitemap. No extra tag is needed.
2. If the import is not offered, add the site manually with the same URL and submit `…/dualprint/sitemap.xml`.

**IndexNow:** not worth it now. Google does not use it. Bing gets the same effect from the GSC import and the sitemap. With 12 pages that rarely change, an automatic ping in `pages.yml` would add a key file and a CI step for very little gain. Revisit only if the site grows or updates often.

**Optional, for `/ru/`:** Yandex is a major engine for Russian searchers. Yandex Webmaster (https://webmaster.yandex.com) also accepts a meta-tag verification (`yandex-verification`) and a sitemap. Add it in the same generator change if the Owner wants Russian reach.

## 4. Rename impact (`dualprinter` → `dualprint`) and timing

**Timing: set up Search Console after the rename, as part of F005.** Reasons:
- A URL-prefix property is bound to the path. A property for `/dualprinter/` would become useless at the rename, and GSC's "Change of address" tool only works for Domain properties, which we can't have on `github.io`.
- The verification tag needs a site change and deploy anyway, and F005 already rebuilds and redeploys every page.
- Nothing is indexed yet, so waiting loses nothing. **Exception:** if the rename slips more than about 2 weeks, set up GSC on `/dualprinter/` now and add a second property at rename.
- Do the repo About box (fix 1) now, and change its website field at rename. GitHub does **not** update it for you.

**What the rename does to SEO:**
- The repo URL is safe: GitHub redirects `github.com/…/dualprinter` → `…/dualprint` permanently, as long as **nobody ever creates a new repo named `dualprinter`** (F005 AC-8.2).
- The site URL breaks: `…github.io/dualprinter/` returns 404, because GitHub Pages has no server redirects (F005 AC-8.3).
- `pages.yml` regenerates canonical, hreflang, og:url, sitemap and robots with the new base URL automatically (`configure-pages` `base_url`). No hand edits are needed.

**About the "redirect page at the old URL" idea:** the only repo that can serve `/dualprinter/` is a repo named `dualprinter`. Re-creating it would **break GitHub's repo redirect**, which is worth more than a day-old, unindexed site. Don't do it.
- If the old URL does get shared or indexed before the rename, there is a safe alternative. The Owner creates a user-site repo `eslamfariedshawky.github.io` with a folder `dualprinter/` that holds one small page per old URL (12 + 404), each with:
  ```html
  <meta name="robots" content="noindex">
  <link rel="canonical" href="https://eslamfariedshawky.github.io/dualprint/<same path>">
  <meta http-equiv="refresh" content="0; url=https://eslamfariedshawky.github.io/dualprint/<same path>">
  ```
  A user site serves paths that no project repo claims, so this needs no `dualprinter` repo. It is an Owner account action plus a publish, so it needs separate approval. Test it on one URL first. **Recommendation today: not needed.**

**Checklist at rename (F005 release):**
1. Owner renames the repo **before** the 3.0.0 tag (F005 question 3, option A).
2. Owner updates the About **website** field to `https://eslamfariedshawky.github.io/dualprint/` and swaps the description and topics to the DualPrint versions (section 5).
3. The Website workflow runs. Verify the live `robots.txt` → `…/dualprint/sitemap.xml`, the sitemap `<loc>`s, and the canonical/hreflang on all 12 pages. Grep for `dualprinter` and the placeholders: expect 0.
4. GSC setup (section 3) on `/dualprint/`, then Bing import.
5. Keep one "formerly MultiPrint" mention per language (F005 AC-5.2) for search continuity.
6. Update any external links the Owner has posted (forums, social) to the new URL.

## 5. Paste-ready repo text (GitHub → repo → About ⚙)

**Now (current name):**

- **Description** (212 chars):
  `MultiPrint – free, open-source Windows 10/11 app that prints to two or more printers at once. One virtual printer sends each job to all selected printers and auto-saves a PDF copy to a folder. Works from any app.`
- **Website:** `https://eslamfariedshawky.github.io/dualprinter/`
  - Tick "Use your GitHub Pages website" if the box is shown; it fills in the same URL.
- **Topics** (18):
  `windows` `windows-10` `windows-11` `printing` `printer` `printers` `multiple-printers` `virtual-printer` `print-to-pdf` `pdf` `save-pdf` `print-automation` `print-management` `print-spooler` `office-tools` `powershell` `open-source` `multiprint`

**After the rename (F005):**

- **Description** (215 chars):
  `DualPrint (formerly MultiPrint) – free, open-source Windows 10/11 app that prints to two or more printers at once and auto-saves a PDF copy. One virtual printer sends each job to all selected printers, from any app.`
- **Website:** `https://eslamfariedshawky.github.io/dualprint/`
- **Topics:** the same list, but replace `multiprint` with `dualprint` (keep `multiprint` too if you want 19 topics; the max is 20).
