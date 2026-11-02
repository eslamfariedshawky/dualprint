# Changelog

## Unreleased
- Documentation: README, CHANGELOG and all user docs in `docs/` are now in English.

## 2.2.5
- The print service restarts itself automatically within 3 seconds if it stops for any reason, and Windows checks on it every minute.
- SumatraPDF is stopped if it hangs for more than two minutes, instead of hanging the service.
- Service start and stop are logged, and the `heartbeat.txt` file is updated every minute.

## 2.2.4
- Locked files in `C:\DualPrint` are repaired one file at a time using `takeown` and then restoring permissions, with details logged to `%TEMP%\MultiPrint-acl.txt`.
- If the printers file cannot be read, a message is shown and saving over it is blocked so the settings are not lost.
- Any error in a button or event in the UI is shown as a message and logged, without closing the app.

## 2.2.3
- Files in `C:\DualPrint` are checked for write access (not just read access) and repaired automatically, including removing the "Hidden" and "Read-only" attributes.
- The app no longer closes if the language cannot be saved.

## 2.2.2
- Fixed the "Access to the path ... is denied" error that appeared in version 2.2.0: the folder permissions were being applied to the files incorrectly. The app detects the problem when it opens and fixes it automatically.

## 2.2.1
- A multi-printer can now be linked to just one printer (for example, one printer plus automatic PDF saving).
- When the printer is linked to PDF only, the PDF pause switch is hidden and saving is never skipped.

## 2.2.0 (security improvements)
- Restricted permissions on the `C:\DualPrint` folder: full control for SYSTEM and administrators, modify for the current user, and read-only for all other users.
- Deleting any folder outside `C:\DualPrint\queues` is blocked, even if the settings file is edited by hand.
- Printer names are validated before use, and incoming text (such as document names) is never interpreted as commands inside the UI.
- SumatraPDF 3.6.x is required: 3.5.x versions affected by CVE-2026-25961 are rejected, files with a tampered signature are rejected, its update check is disabled, and no copy placed next to the app or in user folders is used.
- Only the app's own service processes are stopped during an update.
- Added a Content Security Policy (CSP) to the website, reduced GitHub Actions permissions, and attached a `SHA256SUMS.txt` file to every release.
- Clearer Arabic wording for the number of printer destinations.

## 2.1.1
- Faster app startup: the window appears immediately and the data loads afterwards.
- One printer query instead of three, and an immediate service status check.
- Printer details (paper size and color) load after the cards appear, so offline printers no longer delay opening the app.

## 2.1.0
- Added the **Set as default** button and a "Default" badge on the card.

## 2.0.6
- Services from old versions are prevented from running in parallel with the current service.
- The printer list is read correctly even when saved in the `{value, Count}` format, fixing the "Key cannot be null" error.
- The service starts with Windows and is restored automatically every five minutes if it stops.
- Fixed the service stopping after an update (Abandoned mutex).
- A clear error card is shown instead of the printer card disappearing.
- More reliable navigation between pages.

## 2.0.0
- New UI with a side menu: Printers, Print history and Settings.
- A card for each multi-printer showing printer status, settings, PDF folder and paper size, with options to pause PDF and print a test page.
- A print history with the document name and the result for each destination.
- Add, edit and delete from a dialog inside the app, including renaming the printer.

## 1.x
- Adopted the name MultiPrint (multi printer) instead of DualPrint.
- Support for five languages, with language selection on first run.
- A single executable that runs as a standalone app with no PowerShell window.
- A fixed folder for PDF files and a customizable file-name prefix.
- "Remove all" option.
