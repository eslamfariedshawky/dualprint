# F005 release candidate handoff

Baseline: `release/F005-v3.0.0`, commit `2ffad7b`. This record describes the assembled candidate before this handoff is committed; it is not a publication or runtime-QA certificate.

## State and release gate

T011 through T015 are prepared; integrated code review is APPROVED and scoped security review is CLEARED. T016 screenshots remain stale, and T017 real Windows VM validation is blocked. Required runtime QA has not passed. The repository remains `eslamfariedshawky/dualprinter`; the Owner's repository rename to `dualprint` is pending.

No merge to `main`, release tag or app release has occurred. The Owner has authorized publishing the finished code. Candidate-branch publication is authorized; check the remote branch before resuming. The product release remains held for the required QA and screenshots. Keep company `team/` files frozen. The requested 10% usage threshold cannot be evaluated because no tool exposes a measurable usage percentage; do not invent a percentage or assert compliance.

## Final automated evidence

The CEO reports the final Pester suite **40 passed, 0 failed**, exit 0. The release verifier passed the build, archive contents/version, byte-identical compatibility alias, two matching checksum lines, release title and release-note selection checks. All **17 generated text outputs** matched the candidate in an in-memory comparison. This does not validate screenshots, real tasks, WPF rendering or physical printing.

Commands, from the repository root on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script ./tests/LegacyUpgrade.Tests.ps1 -EnableExit"
powershell -NoProfile -ExecutionPolicy Bypass -File .github/scripts/verify-release.ps1
```

Current SHA-256 evidence:

| File | SHA-256 |
|---|---|
| `src/DualPrint.ps1` | `8113FA18FDDA8C2E6409486E061C595D86F2C30498047056C01C2A0D36BAF9B6` |
| `tests/LegacyUpgrade.Tests.ps1` | `FFDDD4798347AE282193FFD93A00FE75E72F458752971E9CAE0C0607C69E5023` |

The earlier [T012 evidence](T012-upgrade-validation.md) records a test-file byte hash beginning `59D54799`. That differs from the current checkout representation. Git confirms no content diff; the byte hashes are not equal. The older evidence remains unchanged.

## Required VM and screenshot checks

Follow the complete [architecture validation matrix](../architecture/F005-rename-to-dualprint.md#8-test-plan-hooks-for-qa-real-windows-1011-vm-with-snapshots) and [T012 practical limits](T012-upgrade-validation.md#remaining-checks-and-practical-limits):

- **S0 clean:** install; verify UAC/exe version, taskbar grouping, new PDF default, service readiness and self-restart safety.
- **S1 real MultiPrint 2.2.5:** prepare at least two printers, PDF/custom and blank legacy PDF destinations, history and Arabic language. Verify preservation, legacy-task removal, readiness, one watcher and preserved old executable. Exercise old UI open, old exe relaunched, legacy-lock contention, at least three minutes of trigger persistence, sign-out/logon and reboot. Verify exactly one delivery per destination and one history entry after each scenario.
- **S2 original DualPrint 1.x:** test the real install if available, otherwise the documented simulated watcher and explicitly label the simulation. Verify legacy cleanup, honest stopped status and exactly-once printing.
- Verify uninstall and failure/retry/manual rollback, including re-registering a disabled task through **Settings > Print service > Restart**. Retake the five app-language website screenshots with DualPrint branding; verify all app pages/dialogs, Arabic LTR version footer and the website screenshot labels. Record actual outcomes and attach evidence before clearing T016/T017.

Use the task/process/version checks in the matrix, but do not treat mutex existence alone as readiness: status requires both `Local\DualPrintService` and `Local\DualPrintService.Ready`, with Ready published only after both legacy locks are owned. See [troubleshooting and manual rollback](../TROUBLESHOOTING.md) and [the publishing procedure](../PUBLISHING.md) for recovery and later release steps. After the gate clears and publication occurs, separately verify both download links, all three assets, checksum equality, release metadata and repository redirects.
