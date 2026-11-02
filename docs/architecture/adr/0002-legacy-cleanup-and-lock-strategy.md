# ADR 0002: Legacy clean-up, lock strategy, old exe and PDF folder

- Status: Accepted (architect, T010)
- Feature: F005 (spec rules R2–R5, AC-2.x, AC-3.x)

## Context
A 3.0 install must replace either a MultiPrint 2.2.5 service (task `MultiPrint Watcher`, exe `C:\DualPrint\MultiPrint.exe --watch`, one-minute trigger, 999 restarts) or a 1.x service (task `DualPrint Watcher`, `powershell … DualPrint.ps1 -Watch`). Afterwards, exactly one watcher must print, even when:
- an old exe is launched again later
- the 2.2.5 UI is open during the upgrade
- the upgrade fails halfway

The UI runs elevated. The watcher runs as the user with `RunLevel Limited`. Shipped 2.2.5 binaries cannot be changed.

Two smaller questions sit in the same area:
- what to do with `C:\DualPrint\MultiPrint.exe` (AC-2.8)
- how to keep PDFs of legacy printers with an empty `PdfFolder` in `Documents\MultiPrint PDFs` (AC-2.10) while new printers default to `Documents\DualPrint PDFs`

## Options
**Removal**
- A. Stop the legacy task only. Rejected: the trigger restarts it within a minute (R3).
- B. Unregister only. Rejected: the running instance keeps running, and a trigger can fire between steps.
- C. **Disable → Stop → Unregister each legacy task, then kill legacy processes matched by command line (R2).**

**Exactly-once guarantee**
- D. Rely on the UI clean-up only. Rejected: an old exe launched later re-registers its task. A watcher that starts in the gap would print twice.
- E. **The new watcher holds every legacy mutex (R4) and does not process jobs until it holds all of them. While a legacy watcher holds one, the new watcher kills it (throttled to once per 60 s, R2 match only) and yields.**

**Old exe**
- F. Leave it in place. Inert because of E, but a pinned icon keeps launching the 2.2.5 UI, which re-registers its task every time.
- G. Delete it. Fails while the 2.2.5 UI is running from it (the file is locked), and it removes the user's manual rollback path.
- H. **Rename it to `MultiPrint.exe.old`, only after the new service is confirmed running.** Windows allows renaming a running exe. Nothing is lost, rollback is a rename away, and nothing can launch it by accident.

**PDF folder**
- I. Pin only (rewrite `printers.json`). If the write fails, or the watcher prints before the UI ran, the PDF goes to the new default.
- J. Runtime fallback only (empty → legacy folder). Correct, but the data stays implicit.
- K. **Both.** `Get-PdfFolder` returns `PdfFolder` or the legacy folder, and is used by the watcher, the card and the editor. `Pin-LegacyPdfFolders` makes it explicit (idempotent, no marker needed). 3.0 never writes an empty folder for a PDF printer, so "empty" always means "legacy".

## Decision
C + E + H + K, in this order inside `Update-WatcherIfNeeded`:
1. pin
2. remove legacy services (even with 0 printers)
3. register `DualPrint Service` if needed (always after a legacy find)
4. wait up to 10 s for `Local\DualPrintService`
5. only then retire the old exe

`Uninstall-All` removes the legacy tasks as well as its own (AC-2.12). `Register-Watcher` may stop and restart only its own task and `C:\DualPrint\DualPrint.exe --watch` (R2).

## Consequences
- Exactly-once printing holds in every ordering, including a legacy watcher that wins a race at logon. If a legacy watcher can't be killed (e.g. an elevated 1.x process), the legacy watcher keeps printing alone until the next UI launch removes it. Jobs are never doubled or dropped.
- Killing a legacy watcher mid-job can leave that one job partly delivered. This risk already exists in 2.2.5's `Stop-Watchers` and is accepted.
- A 2.2.5 UI launched later can re-create `MultiPrint Watcher` and `MultiPrint.exe`. Its watcher exits on the lock, and the next DualPrint launch cleans up again. This is an accepted, documented loop (AC-2.7).
- A failure after step 2 and before step 4 leaves no service running. It is never a double service. The UI shows "Service stopped", one click or the next launch repairs it, and the old exe is still present for a manual rollback.
- `C:\DualPrint\MultiPrint.exe.old` remains on disk. Users may delete it. The 1.x `DualPrint.ps1` is left as is (inert, out of scope).
- `printers.json` keeps its schema. 2.2.5 can read a pinned file, so a rollback is data-safe.
