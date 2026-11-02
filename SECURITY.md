# Security Policy

## Reporting a vulnerability
Please report security issues privately through **GitHub → Security → Report a vulnerability** (private vulnerability reporting) instead of opening a public issue. We aim to respond within 7 days.

## How DualPrint protects your system
- **Folder permissions:** `C:\DualPrint` is restricted to SYSTEM and Administrators (full control), the installing user (modify) and other users (read only), so other accounts cannot replace the background service or its settings.
- **Safe clean-up:** the app only deletes folders inside `C:\DualPrint\queues`, even if the settings file is edited by hand.
- **Least privilege:** the background service runs with the signed-in user's normal (non-administrator) rights. Administrator rights are only requested by the settings window to add or remove printers.
- **Input validation:** printer names are validated, and all text shown in the interface (document names, printer names) is escaped.
- **SumatraPDF:** downloaded over HTTPS from the official site (version 3.6.x; 3.5.x is rejected because of CVE-2026-25961), rejected if its digital signature is tampered with, and its update check is turned off. Copies placed next to the app or in user folders are never used.
- **Builds:** release builds are produced by GitHub Actions from the public source, and each release includes `SHA256SUMS.txt` so downloads can be verified:
  ```powershell
  (Get-FileHash .\DualPrint.zip -Algorithm SHA256).Hash
  ```

## Known limitations
- The executable is not code-signed yet, so Windows SmartScreen shows a warning on first run.
- The app needs administrator rights once to create printers and the scheduled task.
