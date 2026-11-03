# Building DualPrint from source

Use Windows 10/11 with Windows PowerShell and .NET Framework 4.x. `build.ps1` uses the Windows `csc.exe`; Visual Studio and a dependency install are not required. Start in the repository root.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 -Version 3.0.0
```

The build reads `src/DualPrint.ps1`, embeds `src/strings.json`, applies the version to `src/Launcher.cs`, compiles the launcher and creates:

- `build/DualPrint.exe` (file version `3.0.0.0`).
- `build/DualPrint.zip`, containing exactly `DualPrint.exe`.
- `build/DualPrint.ps1` and `build/Launcher.cs`, generated intermediates for inspection.

The local build produces only canonical outputs. It does not create or update the `MultiPrint.zip` compatibility alias. No application environment variables or `.env` file are required.

## Tests and packaging checks

Use the already-installed Pester version supported by the repository (the recorded baseline is Pester 3.4.0):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -EnableExit"
powershell -NoProfile -ExecutionPolicy Bypass -File .github/scripts/verify-release.ps1
```

The tests import function ASTs and mock machine operations; they do not launch the UI or establish real printer delivery. The verification script runs the workflow build and packaging logic locally, checks archive contents/version, equal alias bytes, both checksums and release-note selection. Its temporary fixtures and outputs stay under ignored `build/`; it publishes nothing. No standalone lint or type-check command is configured.

Before release, complete the real Windows upgrade, task/logon, UI, exactly-once printing, uninstall and rollback checks described in [the validation record](qa/T012-upgrade-validation.md). Automated checks do not replace these checks.

## Website screenshots

The five `website/assets/screenshot-<lang>.png` images are rendered from the real app UI (`build/DualPrint.ps1`) with sample printers and history:

```powershell
.\build.ps1 -Version 3.0.0
powershell -NoProfile -ExecutionPolicy Bypass -STA -File tools\render_screenshots.ps1
```

The script runs the app against a temporary sandbox folder and stubs out everything that touches the system: it needs no admin rights, creates no printers or scheduled task, and does not touch `C:\DualPrint` or an installed copy. Images are 1620×1245 (the window at 150%); if the size changes, update the `width`/`height` values in `tools/build_site.py` and run `python tools/build_site.py`.

## CI behavior

[Build & Release](../.github/workflows/release.yml) builds on pull requests, manual dispatch, qualifying pushes to `main`, and pushed `v*` tags. Main pushes changing only `website/**`, `docs/**` or root `*.md` files are ignored. Non-tag builds use version `0.0.0`; use a numeric release tag such as `v3.0.0` for release versioning.

Every run uploads the **DualPrint** artifact containing both zips and `SHA256SUMS.txt`. Only tag runs execute the publishing job. Creating a Release through the GitHub UI alone is not the workflow trigger. See [Publishing](PUBLISHING.md).
