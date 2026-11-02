# T012: legacy upgrade validation

## Approved scope and baseline

- Plan: F005-2 in `docs/architecture/F005-rename-to-dualprint.md`, implementing the Owner-approved F005 spec and ADRs 0001–0004.
- Base: reviewed T011 identity branch `feat/be-T011-dualprint-identity`, commit `64a5661`.
- Branch: `feat/be-T012-legacy-upgrade`.
- Isolated worktree: `D:/projects/dualprint/projects/.worktrees/dualprint-backend-T012`.
- Production changes are limited to `src/DualPrint.ps1`. The tests and this validation record accompany the implementation.
- The company `team/` directory is read-only by explicit Owner instruction. No board, log, lesson, or checklist files were edited. The main project checkout remains clean on `plan/F005-docs`; the SEO worktree was not changed.

## Implemented behavior

- Both legacy task names are disabled, stopped, and unregistered before matched legacy watcher processes are stopped. Cleanup also runs with zero configured printers.
- Process matching requires a complete watcher argument. The old PowerShell watcher must execute the exact installed script through `-File`; other scripts, command strings, suffixes, null command lines, ordinary UIs, and the current process are excluded. Self-restart stops only the installed exact `DualPrint.exe` executable path with a watcher argument.
- The watcher owns its primary mutex and both legacy mutexes for its lifetime. It never reads jobs before all legacy locks are held, retries contention, throttles legacy process cleanup to once per 60 seconds, and releases/disposes handles on exit. Previously acquired legacy locks are not recursively reacquired.
- Legacy blank PDF folders resolve to the old default in printing, cards, and editing. Pinning changes only blank PDF-target records, retains explicit/custom/Unicode values and other fields, and is idempotent. New PDF printers always save an explicit new default.
- Upgrade checks register/restart as needed, wait for readiness, then retire the old exe. Failed registration, confirmation, or rename retains the old exe; the next launch retries. Uninstall includes all three task names.
- The footer reads the executable's file version independently of the selected language and uses left-to-right text flow.

## Scoped safety refinements from the architecture pseudocode

1. A primary mutex exists while the watcher is still waiting for a legacy lock. It cannot authorize rollback-exe retirement. The CEO approved an additional `Local\DualPrintService.Ready` mutex, created with initial ownership only after both legacy locks are owned. `Test-ServiceRunning` requires both primary and Ready handles. Construction/failure paths read no jobs, and Ready is local to each watcher invocation and reliably disposed.
2. Existing `MultiPrint.exe.old` files are preserved. A repeat upgrade retires the new legacy copy to `MultiPrint.exe.old.<guid>` without replacing the earlier rollback copy.
3. Pin migration serializes to a unique temporary file beside `printers.json` and atomically replaces the existing file only after the temporary write succeeds. Its own temporary file is cleaned up on failure. A blocked replacement or interrupted write leaves the original bytes intact. General `Save-Config` behavior is unchanged.
4. The legacy process helper is defined before the top-level watch entry point. A fresh-runspace regression imports only functions available at that entry point and exercises contention; importing every function alone would hide this ordering defect.

## Test execution and evidence

The baseline had no test suite. Its local `3.0.0` build passed before implementation. Tests were written first, and red runs demonstrated the blank-folder invariant, primary-only readiness, queue reads during contention, missing handle disposal, and fail-open primary-lock error behavior. Later focused red tests caught helper definition order, non-atomic readiness publication, and original-byte corruption after a simulated partial write. Fixtures were corrected for Windows PowerShell UTF-8 handling and Pester 3 mock scope before accepting green results.

Final full-suite command, from this worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -EnableExit"
```

Result: **40 passed, 0 failed, 0 skipped**, exit 0, using the already-installed Pester 3.4.0. No dependency was installed. The targeted command also passes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script ./tests/LegacyUpgrade.Tests.ps1 -EnableExit"
```

The suite imports function ASTs without executing application startup. OS task, process-stop, printer, spooler, and ACL operations in the tested flows are mocked. PDF and configuration tests use temporary fixtures; actual named-mutex status tests use unique test names. One initial PDF test mistakenly retained an invented `C:\Users\Tester` fallback path; Windows denied creation, the test was corrected before implementation, and a final check confirms that directory does not exist.

Coverage includes legacy process exclusions, cleanup ordering, inaccessible tasks, exact installed-exe restart filtering, zero-printer cleanup, repeat-upgrade sequencing, timeout and registration failure/retry, retirement and rename failure, existing rollback preservation, mutex contention/retry/abandonment/lifetime, primary and readiness failures, watcher bootstrap order, PDF routing/pin idempotence, malformed/unreadable configuration, actual blocked file replacement, simulated partial disk writes, new-printer invariants, and version text across all five languages.

Final build:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./build.ps1 -Version 3.0.0
```

Result: exit 0; `Building DualPrint 3.0.0.0`; `Zip check passed: DualPrint.exe`. Outputs are ignored local artifacts `build/DualPrint.exe` and `build/DualPrint.zip`. File description and product name are `DualPrint`; file version is `3.0.0.0`. The application was never launched.

Verification also parsed `src/DualPrint.ps1`, generated `build/DualPrint.ps1`, `build.ps1`, and the test script with the Windows PowerShell parser: zero errors. `git diff --check` passed. There is no configured lint/type-check command, and PSScriptAnalyzer is not installed; no standalone lint claim is made. The C# launcher compiled through the existing build.

Reviewed source SHA256:

```text
8113FA18FDDA8C2E6409486E061C595D86F2C30498047056C01C2A0D36BAF9B6  src/DualPrint.ps1
59D54799426C233A61DE2BE7E75EB9740F1C78B41E5717A791BE98ABCB9B3821  tests/LegacyUpgrade.Tests.ps1
A2B286F33EF52E32C566F5352C4CDD3A4CE2EDD66744E5649E2119D6641F9D39  build/DualPrint.exe
669FFAF0645CC67902E07280AEBC49C4491B03F37B866CB0B1B33927EA37E5A5  build/DualPrint.zip
```

The CEO reported independent source review APPROVED, scoped security review CLEARED, and independent QA 40/40 passing against the source/test hashes above. No source changes followed those reviews.

## Remaining checks and practical limits

Real Windows VM QA from architecture §8 remains required: fresh install, MultiPrint 2.2.5 and DualPrint 1.x upgrades, real scheduled-task registration/removal, logon/reboot persistence, an old UI left open, an old exe relaunched, elevated legacy-lock contention, three-minute trigger persistence, actual exactly-once printing/history, uninstall, and rollback. WPF/Arabic footer rendering and taskbar/UAC behavior need visual/runtime QA. No real printers, tasks, ACLs, installed configuration, or services were changed during implementation; `.env` was never read.

Atomic pin replacement prevents this migration from partially overwriting the original configuration. It does **not** serialize concurrent UI writers. Existing configuration saves still use direct `Set-Content`; another UI can overwrite a pin or a concurrent configuration edit, and a process crash can leave an unused migration temp file. Runtime legacy fallback remains effective if pinning fails or a legacy UI saves a blank folder again. Broader shared-writer coordination is outside this task.

The 60-second cleanup throttle is implemented and source-reviewed; the isolated suite exercises contention and job exclusion but does not perform a real 60-second Windows process-kill race. Limited/elevated process permissions, task trigger timing, and physical delivery guarantees remain VM concerns. No push, merge, deployment, publishing, or deletion of existing files/branches was performed.

## Developer checklist

- [x] Read company handbook, backend JD, lessons, approved spec, architecture and ADRs.
- [x] Stayed within backend scope on the isolated task branch.
- [x] Implemented the scoped acceptance criteria and accompanied behavior with tests.
- [x] Full test suite passed; build, parser and whitespace checks passed with limitations above.
- [x] No new dependencies, secret access, credentials, debug logs, or unrelated refactor.
- [x] Reviewed changes and supplied a standard report to the CEO.
- [x] Kept `team/` untouched as explicitly instructed; board updates are not part of this delivery.
- [ ] Real VM QA and later release/merge gates remain with the production line.
