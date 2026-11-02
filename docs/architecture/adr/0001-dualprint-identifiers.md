# ADR 0001: Internal identifiers for DualPrint 3.0.0

- Status: Accepted (architect, T010). Spec F005 approved by the Owner.
- Feature: F005

## Context
The product is being renamed from MultiPrint (v2.x) to DualPrint. The original 1.x product was also called DualPrint, and the current code removes or blocks anything carrying the 1.x names:
- `src/MultiPrint.ps1:29` `$OldTaskName = 'DualPrint Watcher'`
- `:446-457` `Stop-Watchers` unregisters that task and kills `powershell … DualPrint\DualPrint.ps1 -Watch`
- `:141` holds `Local\DualPrintWatcher`
- `:1712-1713` re-registers whenever `DualPrint Watcher` exists

Spec rule R1 forbids the new names from colliding with `DualPrint Watcher`, `Local\DualPrintWatcher`, `MultiPrint Watcher` or `Local\MultiPrintWatcher`. Released 2.2.5 binaries (which a user may still launch) carry their own clean-up code. That code cannot be changed, so the new names must also be safe against it.

## Options
1. **Plain search-and-replace** (`MultiPrint Watcher` → `DualPrint Watcher`, `Local\MultiPrintWatcher` → `Local\DualPrintWatcher`). Rejected. The new service would be deleted by its own legacy clean-up and by any 2.2.5 binary. A running 1.x watcher would look like "our service", so the new watcher would exit.
2. **Versioned names** (`DualPrint3 Watcher`, `Local\DualPrint3Watcher`). Safe, but the version leaks into a user-visible task name and would look stale in 4.x.
3. **New neutral suffix**: task `DualPrint Service`, mutex `Local\DualPrintService`. This is the spec's suggestion and matches the UI's existing "Service running" wording.

## Decision
Option 3. The full set:

| Item | Value |
|---|---|
| Exe / installed path | `DualPrint.exe` / `C:\DualPrint\DualPrint.exe` |
| Embedded resource | `DualPrint.ps1` |
| Scheduled task | `DualPrint Service` |
| Primary mutex | `Local\DualPrintService` |
| Legacy locks also held | `Local\MultiPrintWatcher`, `Local\DualPrintWatcher` |
| AppUserModelID | `DualPrint.App` |
| Default PDF folder (new printers) | `Documents\DualPrint PDFs` |
| Legacy PDF fallback | `Documents\MultiPrint PDFs` |
| ACL log | `%TEMP%\DualPrint-acl.txt` |
| Release asset / CI artifact | `DualPrint.zip` / `DualPrint` |
| Exe properties | Title, Company, Product: `DualPrint`. Description: `DualPrint - print to several printers at once`. Copyright: `DualPrint contributors`. |

Kept: function names with the generic term (`New-MultiPrinter` etc., Owner Q1 = A), the internal `$global:MPErrorShown`, and the site's `mp-lang` localStorage key (it keeps visitors' language choice; the origin does not change). None of these are user-visible brand text, and none match the AC-7.6 grep.

Every remaining `MultiPrint` literal in `src/` is a legacy identifier and carries a comment (R6).

## Consequences
- No 2.2.5 or 1.x code path can unregister, kill or impersonate the 3.0 service. A 2.2.5 binary's `Stop-Watchers` matches only `MultiPrint Watcher`, `DualPrint Watcher`, `MultiPrint.exe --watch` and the 1.x PowerShell watcher.
- Taskbar pins made under `MultiPrint.App` do not group with the new app. The release notes tell users to re-pin.
- `Test-ServiceRunning` keys on `Local\DualPrintService` only, so a legacy watcher is never reported as the DualPrint service (AC-3.4).
- Future renames must follow the same rule: never reuse a name that any shipped version treats as legacy.
