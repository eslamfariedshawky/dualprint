# F005: One name everywhere, DualPrint

| | |
|---|---|
| Feature | F005 |
| Project | `multiprint` (repo `github.com/eslamfariedshawky/dualprinter`) |
| Task | T008 (spec) |
| Author | product-manager |
| Status | Approved by the Owner (Nov 3, 2026 12:55 AM, with all recommendations) · Revision 1 |
| Proposed version | 3.0.0 (Owner question 2) |

> Owner's request (verbatim): "the repo is dual print the program is multiprint we need to make it only one ... dualprint and also changed it in the program too"

---

## 1. Problem

The product has two names. The GitHub repo is `dualprinter` and the data folder is `C:\DualPrint`, but the program, exe, UI, website, docs and download are all called **MultiPrint**. That confuses users: they download "MultiPrint" from a "dualprinter" site and then find a `C:\DualPrint` folder. It also splits search results across two names.

The history makes this harder. The product started as **DualPrint** (1.x), was renamed to **MultiPrint**, and v2.2.5 (MultiPrint) was published today. The running code still contains upgrade logic that treats every "DualPrint" identifier as old and removes it:

- `src/MultiPrint.ps1:29` sets `$OldTaskName = 'DualPrint Watcher'`.
- `src/MultiPrint.ps1:447-455` (`Stop-Watchers`) stops and unregisters that task and kills `powershell.exe` processes that run `DualPrint\DualPrint.ps1 -Watch`.
- `src/MultiPrint.ps1:141` also holds the mutex `Local\DualPrintWatcher` as a "legacy" lock.
- `src/MultiPrint.ps1:1712-1713` (`Update-WatcherIfNeeded`) re-registers the service whenever a task named `DualPrint Watcher` exists.

A search-and-replace from "MultiPrint" to "DualPrint" would turn the new service's own names into the "old" names. The new version would then stop, unregister or block its own print service. Users would also be left with two services, or none.

## 2. Goals

1. **One name.** "DualPrint" is the only product name users see: the exe and its file properties, the UAC prompt, window titles, the UI in all 5 app languages, the website in all 6 site languages, the download file, the docs, the release and the GitHub repo.
2. **Safe upgrade from MultiPrint v2.2.5.** Printers, settings, language, history and PDF output folders are kept. The MultiPrint service is stopped and removed, and it never runs at the same time as the DualPrint service.
3. **No regression for old DualPrint 1.x installs.** The existing clean-up of the 1.x service keeps working, and it must not hit the new DualPrint service.
4. **One download link** that matches the name. The site links to `DualPrint.zip`.

## 3. Non-goals (out of scope)

- Any new feature, UI redesign or behavior change other than the naming and the upgrade safety listed here.
- Moving the data folder. It stays at `C:\DualPrint`, which already matches the new name.
- Rewriting history. CHANGELOG entries for 2.2.5 and earlier keep the names they had.
- An in-app "MultiPrint is now DualPrint" announcement. The release notes and README cover that.
- Renaming or moving PDF files or folders that users already have, such as `Documents\MultiPrint PDFs`.
- A new logo or icon. `assets/icon.ico` is not text-based and stays.
- Renaming the local company folder `projects/multiprint` or the board project id. That is company housekeeping, not product scope. See note N3 for the CEO.
- Code signing, or any new paid or external service.

## 4. Users

| User | What they need from this change |
|---|---|
| **New user** | Finds "DualPrint" on the site, downloads `DualPrint.zip`, installs, and sees one name everywhere. |
| **MultiPrint v2.2.5 user** (published today, likely few) | Runs `DualPrint.exe` once and everything keeps working under the new name, with no double printing. |
| **Old DualPrint 1.x user** (if any remain) | Runs `DualPrint.exe` and the 1.x service is cleaned up, as it is today. |
| **Owner / maintainer** | Builds, releases and publishes the site with one consistent name, and knows exactly which repo setting to change and when. |

## 5. Names: current and required

These are the user-visible results. The architect picks the exact internal identifiers, under the rules in §6.

| Item | Today (v2.2.5) | Required after F005 |
|---|---|---|
| Product name (UI, titles, message boxes) | MultiPrint | **DualPrint** |
| Download file | `MultiPrint.zip` | `DualPrint.zip` |
| Exe in the zip | `MultiPrint.exe` | `DualPrint.exe` |
| Installed exe | `C:\DualPrint\MultiPrint.exe` | `C:\DualPrint\DualPrint.exe` |
| Exe properties (Title, Description, Product, Company, Copyright) | MultiPrint | DualPrint |
| Data folder | `C:\DualPrint` | unchanged |
| Scheduled task (visible in Task Scheduler) | `MultiPrint Watcher` | A name that starts with "DualPrint" and is **not** `DualPrint Watcher` (see §6, rule R1) |
| Single-instance mutex | `Local\MultiPrintWatcher` | A new DualPrint name that is **not** `Local\DualPrintWatcher` (see R1) |
| AppUserModelID | `MultiPrint.App` | A DualPrint value, e.g. `DualPrint.App` |
| Default PDF folder for **new** printers | `Documents\MultiPrint PDFs` | `Documents\DualPrint PDFs` |
| ACL repair log | `%TEMP%\MultiPrint-acl.txt` | `%TEMP%\DualPrint-acl.txt` |
| Source files | `src/MultiPrint.ps1` | `src/DualPrint.ps1` (renamed with `git mv` so history is kept) |
| Settings footer label | `MultiPrint 2.0` (hard-coded and wrong) | `DualPrint <running version>` |
| Repo / site | `dualprinter` / `.../dualprinter/` | `dualprint` / `.../dualprint/` (Owner action, Owner question 3) |

## 6. Upgrade-safety rules (apply to every story)

- **R1. No name collisions with 1.x.** The new service's task name and mutex must differ from every legacy identifier: `DualPrint Watcher`, `Local\DualPrintWatcher`, `MultiPrint Watcher` and `Local\MultiPrintWatcher`. *Why:* if the new task were called `DualPrint Watcher`, the 1.x clean-up would delete it. If the new mutex were `Local\DualPrintWatcher`, a still-running 1.x service would look like "our service is running" and the new watcher would exit. Recommendation for the architect: use clearly new names, for example task `DualPrint Service` and mutex `Local\DualPrintService`.
- **R2. Legacy detection checks what something runs, not only its name.** A legacy process is `MultiPrint.exe --watch`, or `powershell.exe` running `DualPrint\DualPrint.ps1 -Watch`. The code must never stop `DualPrint.exe --watch` as "legacy". It may still restart it as part of its own re-registration, as it does today.
- **R3. Legacy services are removed, not just stopped.** The `MultiPrint Watcher` task restarts every minute and retries up to 999 times, so stopping it is not enough. It must be unregistered.
- **R4. The new watcher holds every legacy lock.** While the DualPrint service runs, it holds `Local\MultiPrintWatcher` and `Local\DualPrintWatcher` (the second is already held today). Then if an old exe is launched later, its service exits immediately instead of printing twice.
- **R5. No data migration is needed and none may be lost.** `printers.json`, `settings.json`, `history.jsonl`, `log.txt`, `SumatraPDF.exe`, `queues\*`, the Windows printers and their ports all stay where they are, unchanged.
- **R6. Every exception is commented in the code.** Each remaining "MultiPrint" string in source exists only for legacy compatibility and has a comment saying so.

---

## 7. User stories and acceptance criteria

### US-1. Fresh install
*As a new user, I want to download and install DualPrint and see only that name, so that I know exactly what I installed.*

- **AC-1.1** Given a PC that has never had MultiPrint or DualPrint, when I download `DualPrint.zip` from the latest release and extract it, then it contains `DualPrint.exe`, and no file or folder in the zip has "MultiPrint" in its name.
- **AC-1.2** Given I run `DualPrint.exe`, when Windows shows the administrator (UAC) prompt, then the program name shown is "DualPrint".
- **AC-1.3** Given I pick a language and create my first printer, when setup finishes, then `C:\DualPrint\DualPrint.exe` exists, a scheduled task whose name starts with "DualPrint" (and complies with R1) runs `C:\DualPrint\DualPrint.exe --watch`, and the sidebar shows "Service running".
- **AC-1.4** Given a fresh install, when I look in `C:\DualPrint` and Task Scheduler, then there is no `MultiPrint.exe` and no task with "MultiPrint" in its name.
- **AC-1.5** Given I open the add-printer dialog and select the PDF destination, when I look at the default PDF folder, then it is `Documents\DualPrint PDFs`.
- **AC-1.6** Given `C:\DualPrint\DualPrint.exe`, when I open Properties, then the Details tab shows "DualPrint" for file description, product name and copyright, and the file version is the release version (e.g. 3.0.0.0).
- **AC-1.7** Given DualPrint is running, when I look at the taskbar, then its taskbar entry is grouped under the new DualPrint AppUserModelID.

### US-2. Upgrade from MultiPrint v2.2.5
*As a MultiPrint v2.2.5 user, I want to run the new DualPrint once and keep all my printers and history, so that the name changes and nothing else does.*

Setup for every AC below: MultiPrint v2.2.5 is installed with at least 2 virtual printers (one with a PDF destination), some print history, a non-English language chosen, and the `MultiPrint Watcher` task running `C:\DualPrint\MultiPrint.exe --watch`.

- **AC-2.1** Given that setup, when I run `DualPrint.exe` (from Downloads or anywhere else) and approve UAC, then the language picker is **not** shown and the app opens in my saved language.
- **AC-2.2** Given that setup, when the app has finished loading, then all my virtual printers appear with the same names, destinations, paper size, PDF folder, file prefix, PDF on/off state and default-printer badge, and the Print history page shows all my earlier entries.
- **AC-2.3** Given that setup, when the app has finished loading, then the `MultiPrint Watcher` task is **unregistered** (not only stopped), no `MultiPrint.exe --watch` process is running, and exactly one DualPrint service process is running.
- **AC-2.4** Given the upgrade is done, when I wait at least 3 minutes (long enough for the old one-minute trigger and restart settings to fire), then the MultiPrint service has not come back and exactly one service process is still running.
- **AC-2.5** Given the upgrade is done, when I print one page to a virtual printer, then each destination gets exactly **one** copy and one history entry is added.
- **AC-2.6** Given the upgrade is done, when I sign out and back in (or reboot), then only the DualPrint service starts and printing works.
- **AC-2.7** Given the upgrade is done, when I launch the old `MultiPrint.exe` v2.2.5 again (for example from a pinned icon or the Downloads folder), then printing still produces exactly one copy per destination (R4), and the next time `DualPrint.exe` is opened it removes the MultiPrint task again.
- **AC-2.8** Given the upgrade is done, when I look in `C:\DualPrint`, then the old `C:\DualPrint\MultiPrint.exe` can no longer act as the service. The architect chooses whether it is removed or left inert, and the release notes tell users to re-pin the app if they had pinned `MultiPrint.exe`.
- **AC-2.9** Given an existing printer whose PDF folder is `Documents\MultiPrint PDFs`, when I print to it after the upgrade, then the PDF is still saved in `Documents\MultiPrint PDFs`. Saved folders are never rewritten.
- **AC-2.10** Given an existing printer config that has a PDF destination but an **empty** `PdfFolder` (it currently falls back to the default), when I print after the upgrade, then the PDF still goes to `Documents\MultiPrint PDFs` and not the new default. The upgrade pins the old folder for such printers.
- **AC-2.11** Given the MultiPrint UI window is still open when I run `DualPrint.exe`, when the upgrade runs, then the outcome is the same as AC-2.3 to AC-2.5 and no data file is corrupted.
- **AC-2.12** Given that setup, when I choose **Settings → Remove all** in DualPrint, then all virtual printers are removed, and the DualPrint task, the `MultiPrint Watcher` task and the `DualPrint Watcher` task are all unregistered.

### US-3. Upgrade from an old DualPrint 1.x install
*As a user of the original DualPrint 1.x, I want the new DualPrint to replace my old service, so that I don't get duplicate prints.*

This behavior exists today (CHANGELOG 2.0.6), so it must not regress. It costs little because the code is already there.

- **AC-3.1** Given a 1.x install (task `DualPrint Watcher` running `powershell.exe ... C:\DualPrint\DualPrint.ps1 -Watch`), when I run `DualPrint.exe` 3.0.0 and the app loads, then the `DualPrint Watcher` task is unregistered, the 1.x PowerShell watcher is stopped, and exactly one new DualPrint service is running.
- **AC-3.2** Given AC-3.1 has happened, when I print once, then each destination gets exactly one copy.
- **AC-3.3** Given a machine with **only** DualPrint 3.0.0 installed, when the app opens, runs `Update-WatcherIfNeeded`, or I choose Settings → Restart, then the new DualPrint task is **never** unregistered as "legacy" and the service status stays "Service running" (R1, R2).
- **AC-3.4** Given a machine where a 1.x watcher is somehow still running, when the DualPrint app checks the service status, then it does not report the 1.x process as the DualPrint service (R1).

### US-4. UI text in all 5 app languages
*As a user in Arabic, English, Spanish, French or German, I want to see the name DualPrint in my language's UI, so that the app matches the website and the download.*

- **AC-4.1** Given each of the 5 app languages (ar, en, es, fr, de), when I open the app, then "DualPrint" is shown in the window title, the sidebar header, the language-picker title (first run) and the Settings footer.
- **AC-4.2** Given each of the 5 languages, when any error message box is shown (startup error, crash, trap handler), then its title is "DualPrint".
- **AC-4.3** Given each of the 5 languages, when I visit every page and dialog (Printers, empty state, add/edit dialog, History, Settings, Remove all confirm, toasts), then the brand "MultiPrint" appears nowhere. The generic term ("multi printer" and its translations) follows the Owner's answer to question 1.
- **AC-4.4** Given the Settings footer, when I read it, then it shows "DualPrint" followed by the running exe version (e.g. "DualPrint 3.0.0"), not a hard-coded number.
- **AC-4.5** Given Arabic (RTL), when "DualPrint" appears inside Arabic text, then it renders left-to-right and is not split or reordered.
- **AC-4.6** *(Only if the Owner chooses to rebrand the generic term in question 1.)* Given each language, when I read the keys `page_title`, `empty_title`, `history_sub`, `default_name` and every other string that uses the generic term, then the new term is used consistently. A native-quality translation is provided for ar, es, fr and de, and the Owner signs off on the Arabic wording.

### US-5. Website in all 6 site languages
*As a visitor in English, Arabic, Russian, German, Spanish or French, I want the site to present DualPrint with the right download, so that I trust the name and get the right file.*

- **AC-5.1** Given each of the 6 site languages (en, ar, ru, de, es, fr), home page and guide page, when I view the page, then the title, meta description, Open Graph `og:site_name`, JSON-LD `name` (SoftwareApplication, WebSite, Article author/publisher, breadcrumb), header brand, footer, FAQ, CTA and image alt text all say "DualPrint".
- **AC-5.2** Given each generated page, when I search its HTML for the brand "MultiPrint", then there is **at most one** match on that page. That one optional mention (kept for search continuity) is **either** a JSON-LD `alternateName: "MultiPrint"` **or** one visible "formerly MultiPrint" line, **never both**. The seo-specialist chooses which of the two options to use (and the exact wording and placement) and applies the same choice to every language.
- **AC-5.3** Given each language's home page, when I read the hero or description, then it states clearly that DualPrint works with **two or more** printers, so the name does not suggest a limit of two.
- **AC-5.4** Given the 5 app screenshots (`website/assets/screenshot-{en,ar,es,fr,de}.png`), when I view them, then they show "DualPrint" (title bar, sidebar) and no "MultiPrint" text, including the PDF folder label. The Russian page keeps its current screenshot behavior.
- **AC-5.5** Given `website/` is rebuilt with `python tools/build_site.py`, when I compare the output with the committed `website/` folder, then they are identical. Generated pages are not hand-edited.
- **AC-5.6** Given the site's version note, when I view it, then it shows the new version (e.g. v3.0.0).

### US-6. Download link
*As a visitor, I want the download button to give me DualPrint.zip, so that the file name matches the product.*

- **AC-6.1** Given every page in every site language, when I inspect the download button, then it points to `<repo>/releases/latest/download/DualPrint.zip`.
- **AC-6.2** Given the new release is published, when I open that link, then `DualPrint.zip` downloads, and it contains `DualPrint.exe` of the new version.
- **AC-6.3** Given the release, when I open its assets, then they are `DualPrint.zip` and `SHA256SUMS.txt`. The checksum line names `DualPrint.zip`, and the hash matches the downloaded file.
  - *Note (ADR 0003):* with no `MultiPrint.zip` asset, `<repo>/releases/latest/download/MultiPrint.zip` returns 404 once 3.0.0 is the latest release. Version-pinned links such as `.../releases/download/v2.2.5/MultiPrint.zip` keep working. This is **pending one Owner confirmation**. If the Owner asks to keep the old latest-link working, AC-6.3 changes to: the assets are `DualPrint.zip`, `MultiPrint.zip` (same bytes) and `SHA256SUMS.txt`, and the checksum file has one matching line for each zip.
- **AC-6.4** Given the release, when I read its title and notes, then the title is "DualPrint <version>" and the notes say in one line that MultiPrint is now DualPrint, that existing printers and history are kept, and that a pinned `MultiPrint.exe` should be re-pinned.
- **AC-6.5** Given `build.ps1 -Version <v>` runs, when it finishes, then it produces `build\DualPrint.exe` and `build\DualPrint.zip`, and nothing named MultiPrint.

### US-7. Docs
*As a user or contributor, I want the README and docs to use DualPrint, so that the instructions match what I download and see.*

- **AC-7.1** Given `README.md`, `SECURITY.md`, `LICENSE`, `docs/USER_GUIDE.md`, `docs/TROUBLESHOOTING.md`, `docs/ARCHITECTURE.md`, `docs/BUILDING.md` and `docs/PUBLISHING.md`, when I read them, then every product, exe, zip, task, file and repo name matches §5. Examples: `DualPrint.zip`, `DualPrint.exe`, `src/DualPrint.ps1`, the new task name, `git clone .../dualprint.git`, repository name `dualprint`, and release title `DualPrint <version>`.
- **AC-7.2** Given `README.md`, when I read the top, then it has the title "DualPrint" and one line saying "formerly MultiPrint".
- **AC-7.3** Given `docs/TROUBLESHOOTING.md`, when I read the "Duplicate printing" row, then it names both possible old versions ("MultiPrint 2.x" or "DualPrint 1.x") and says that running the latest DualPrint once stops them.
- **AC-7.4** Given `CHANGELOG.md`, when I read it, then there is a new version entry that explains the rename and the automatic upgrade, and the entries for 2.2.5 and earlier are unchanged.
- **AC-7.5** Given `LICENSE`, when I read it, then the copyright line reads "DualPrint contributors" and the rest of the MIT text is unchanged.
- **AC-7.6** Given the whole repo, when someone runs `git grep -n -i -P "multiprint(?!er)"` (this skips the generic word "MultiPrinter"), then every match is on the allowlist:
  (a) legacy-compatibility identifiers in source, each with a comment (R6);
  (b) CHANGELOG entries for 2.2.5 and earlier, plus the rename note in the new entry;
  (c) "formerly MultiPrint" mentions in README, site and release notes;
  (d) this spec and other `specs/` / `docs/architecture/` files that describe the migration;
  (e) legacy and upgrade mentions in user docs: `docs/TROUBLESHOOTING.md` (the "MultiPrint 2.x" wording required by AC-7.3, and the manual rollback steps to 2.2.5), `docs/release-notes/v3.0.0.md` (rename notice, re-pin `MultiPrint.exe` note), and the upgrade note in `docs/USER_GUIDE.md`;
  (f) `docs/seo/*` (the SEO migration plan and keyword notes, which must name the old brand);
  (g) the single per-page mention allowed by AC-5.2 (`alternateName` or "formerly MultiPrint", not both), in `website/` and its generator source.
  QA attaches the command output.

### US-8. Repo and site URL
*As the Owner, I want the repo and website address to say dualprint, so that the name is the same everywhere, including the URL.*

- **AC-8.1** Given the Owner has renamed the repo from `dualprinter` to `dualprint` in GitHub settings (Owner-only action), when the Website workflow next runs, then every generated link (`canonical`, `hreflang`, `og:url`, sitemap, robots, 404 redirect, download link) uses `https://eslamfariedshawky.github.io/dualprint/` and `https://github.com/eslamfariedshawky/dualprint`. No file is edited by hand, because `pages.yml` fills in `__SITE_URL__` and `__REPO_URL__`.
- **AC-8.2** Given the rename, when I open `https://github.com/eslamfariedshawky/dualprinter`, then GitHub redirects to the new repo. **Nobody may create a new repo named `dualprinter`**, because that would break this redirect.
- **AC-8.3** Given the rename, when I open the old site `https://eslamfariedshawky.github.io/dualprinter/`, then it is expected to return 404. GitHub does not redirect Pages. The Owner accepts this through question 3.
- **AC-8.4** Given the rename, when the CEO updates the local `origin` remote to the new URL, then `git fetch` works. This is a CEO step, after Owner approval.
- **AC-8.5** Given the Pages settings after the rename, when I check them, then Pages is still enabled with source "GitHub Actions". The Owner verifies this, because a rename should keep it.
- **AC-8.6** Given the board's `projects` entry, when the rename is done, then the CEO updates `repo` and `site` to the new URLs.

---

## 8. Phases and release order

The work is one shippable pass. The order matters only because of the URL:

1. **Build (team):** code, build, CI, site content and generator, screenshots and docs, all on branches, reviewed and tested. Nothing is pushed.
2. **Owner gate:** the Owner approves the release and renames the repo to `dualprint` **before** the new tag is pushed (recommended), so that the release, the README links and the generated site all use the final URLs the first time.
3. **Release (CEO, with each approval separate):** push `main`, push the tag `v<version>`, let `release.yml` publish `DualPrint.zip`, then run the Website workflow. Then verify AC-6.1, AC-6.2 and AC-8.1.

QA should test US-2 and US-3 on a real Windows machine (or VM) with the actual v2.2.5 release installed first. A unit test of the name constants is not enough.

## 9. Open questions for the Owner (3)

1. **The generic term "multi printer".** The UI calls each virtual printer a "multi printer" ("Multi printers" page title, "No multi printers yet", default name "Multi Printer"), with matching translations in 4 more app languages and 6 site languages. Should we keep that term or rebrand it?
   - **A. Keep "multi printer"** as the plain description of what you create inside DualPrint (e.g. "DualPrint — create a multi printer"). There are no translation changes, it is the lowest risk, and it keeps the "multi printer" search keyword.
   - **B. Change it to a neutral term**, e.g. "virtual printer" / "linked printer", in all languages. This is cleaner if "Multi" still feels like the old name, but it means about 10 string keys × 5 languages plus the site text, and new translations to review.
   - Note: "DualPrint" suggests 2 printers while the app supports many. Option A keeps "multi" visible, which helps with that, and AC-5.3 states "two or more" on the site either way.
   - **Recommendation: A**, keep it.
2. **Version number.** The identity changes (exe name, task, zip, download URL), so this is a visible break for anyone who scripted or linked `MultiPrint.zip`.
   - **A. 3.0.0** (major: new identity)
   - **B. 2.3.0** (minor: no feature change)
   - **Recommendation: A, 3.0.0.**
3. **When to rename the repo, and the URL change.** Renaming `dualprinter` → `dualprint` is a GitHub setting only you can change. GitHub redirects the repo and git URLs, but **not** the Pages site, so `.../dualprinter/` will stop working. It has been live for less than a day, so little is lost now, and more is lost the longer we wait.
   - **A. Rename right before the 3.0.0 release** (after spec approval, before the tag), so everything is generated once with the final URLs.
   - **B. Rename later**, as a separate step. 3.0.0 ships on the `dualprinter` URLs, and the site must be re-published after the rename.
   - **C. Keep the repo name `dualprinter`.** The URL never changes, but the name is not quite "one name".
   - **Recommendation: A.** Don't create a placeholder `dualprinter` repo afterwards, because it would break GitHub's redirect.

## 10. Notes for the CEO (not Owner questions)

- **N1. File renames.** This spec expects `git mv` renames (history kept) of `src/MultiPrint.ps1` → `src/DualPrint.ps1`, and of build outputs and zip names. If the "no deleting files" rule is read as covering renames, approving this spec should count as approving these renames. Please confirm with the Owner when the spec is approved.
- **N2. SEO stage.** The seo-specialist should review AC-5.1 to AC-5.3 (title, description and keywords per language, plus the "formerly MultiPrint" wording) and the URL change in US-8.
- **N3. Local naming.** `projects/multiprint` and the board project id `multiprint` are outside the product scope. Whether to rename them is a company housekeeping call.
- **N4. Design stage.** The UI layout does not change; only text does. The ui-ux-designer stage can probably be skipped unless the Owner picks 1B. The screenshots (AC-5.4) still have to be retaken.

---

## Changelog

- **Revision 1** (Nov 3, 2026; clarifications from the architect review, no scope change): AC-7.6 allowlist now also covers legacy and upgrade mentions in `docs/TROUBLESHOOTING.md`, `docs/release-notes/v3.0.0.md`, the `docs/USER_GUIDE.md` upgrade note, `docs/seo/*`, and the AC-5.2 per-page mention. AC-5.2 now says at most one "MultiPrint" per page: SEO picks a JSON-LD `alternateName` or a visible "formerly MultiPrint" line, not both. AC-6.3 now notes that `releases/latest/download/MultiPrint.zip` returns 404 after 3.0.0 (ADR 0003, pending one Owner confirmation).
