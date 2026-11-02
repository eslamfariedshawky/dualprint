# F005: Rename to DualPrint — Architecture

| | |
|---|---|
| Feature | F005 |
| Task | T010 (architecture) |
| Spec | `specs/F005-rename-to-dualprint.md` (approved by the Owner) |
| Owner decisions applied | Keep the generic term "multi printer" (Q1 = A) · Version 3.0.0 (Q2 = A) · Owner renames the repo `dualprinter` → `dualprint` before the v3.0.0 tag (Q3 = A) · `git mv` file renames approved (N1) |
| ADRs | [0001](adr/0001-dualprint-identifiers.md) identifiers · [0002](adr/0002-legacy-cleanup-and-lock-strategy.md) legacy clean-up · [0003](adr/0003-release-asset-name-and-download-link.md) asset name and download link · [0004](adr/0004-version-3-0-0.md) version |

There is no HTTP API and no database. The "contract" in this feature is the set of names that Windows sees: the exe, the scheduled task, the mutexes, the AppUserModelID, the folders and the release asset. The data model (`printers.json`, `settings.json`, `history.jsonl`) does not change shape. §7 lists the one value-level change: the PDF folder gets pinned for some legacy printers.

---

## 1. Components touched

| Component | File (after rename) | Change |
|---|---|---|
| App script | `src/MultiPrint.ps1` → `src/DualPrint.ps1` (`git mv`) | Identifiers, legacy clean-up, legacy locks, PDF-folder pin, old-exe retirement, version footer, UI titles |
| Launcher | `src/Launcher.cs` | Assembly attributes, AppUserModelID, resource name, message box captions, null-resource guard |
| Build | `build.ps1` | Input/output/resource names, zip guard |
| CI / release | `.github/workflows/release.yml` | Asset and artifact names, checksum line, release title and notes |
| Pages | `.github/workflows/pages.yml` | No logic change. URLs come from `github.repository`, so they follow the repo rename on their own. Comment wording only. |
| Site generator | `tools/build_site.py`, `tools/site_content.py`, `website/**` (generated) | Brand constant, download link, version, copy, screenshots |
| Docs | `README.md`, `SECURITY.md`, `LICENSE`, `CHANGELOG.md`, `docs/*.md` (not `docs/architecture/`) | Owned by tech-writer |
| Strings | `src/strings.json` | **No change.** It contains no brand text, and the generic term stays (Q1 = A). |

---

## 2. Final identifiers (ADR 0001)

| Item | v2.2.5 (legacy) | 1.x (legacy) | **3.0.0 (new)** |
|---|---|---|---|
| Product name (UI, titles, message boxes) | MultiPrint | DualPrint | **DualPrint** |
| Source script | `src/MultiPrint.ps1` | `DualPrint.ps1` | **`src/DualPrint.ps1`** |
| Embedded resource name | `MultiPrint.ps1` | — | **`DualPrint.ps1`** |
| Build outputs | `build\MultiPrint.{ps1,exe,zip}` | — | **`build\DualPrint.ps1`, `build\DualPrint.exe`, `build\DualPrint.zip`** |
| CI artifact name | `MultiPrint` | — | **`DualPrint`** |
| Release assets | `MultiPrint.zip`, `SHA256SUMS.txt` | — | **`DualPrint.zip`, `MultiPrint.zip` (identical compatibility alias), `SHA256SUMS.txt`** |
| Installed exe (`$RootExe`) | `C:\DualPrint\MultiPrint.exe` | `powershell.exe … C:\DualPrint\DualPrint.ps1` | **`C:\DualPrint\DualPrint.exe`** |
| Scheduled task (`$TaskName`) | `MultiPrint Watcher` | `DualPrint Watcher` | **`DualPrint Service`** |
| Service mutex (primary) | `Local\MultiPrintWatcher` | `Local\DualPrintWatcher` | **`Local\DualPrintService`** |
| Locks also held by the new service (R4) | `Local\DualPrintWatcher` | — | **`Local\MultiPrintWatcher`, `Local\DualPrintWatcher`** |
| AppUserModelID | `MultiPrint.App` | — | **`DualPrint.App`** |
| Default PDF folder for **new** printers (`$DefaultPdf`) | `Documents\MultiPrint PDFs` | — | **`Documents\DualPrint PDFs`** |
| Fallback PDF folder for **legacy** printers with an empty `PdfFolder` (`$LegacyDefaultPdf`) | (was the default) | — | **`Documents\MultiPrint PDFs`** (legacy constant, commented) |
| ACL repair log | `%TEMP%\MultiPrint-acl.txt` | — | **`%TEMP%\DualPrint-acl.txt`** |
| Sumatra temp folder prefix | `mp_` | — | **`dp_`** (cosmetic) |
| Exe properties: Title / Description / Company / Product / Copyright | MultiPrint | — | **DualPrint / "DualPrint - print to several printers at once" / DualPrint / DualPrint / "DualPrint contributors"** |
| Exe version | 2.2.5.0 | — | **3.0.0.0** (set by `build.ps1 -Version`) |
| Data folder | `C:\DualPrint` | `C:\DualPrint` | **unchanged** |
| Retired legacy exe | — | — | `C:\DualPrint\MultiPrint.exe` → renamed to **`C:\DualPrint\MultiPrint.exe.old`** (ADR 0002) |

**R1 check.** `DualPrint Service` ≠ `DualPrint Watcher` ≠ `MultiPrint Watcher`, and `Local\DualPrintService` ≠ `Local\DualPrintWatcher` ≠ `Local\MultiPrintWatcher`. Neither the 2.2.5 nor the 1.x clean-up code matches the new names. The 2.2.5 `Stop-Watchers` only unregisters the task named `DualPrint Watcher` and only kills `MultiPrint.exe --watch` and `powershell.exe … DualPrint\DualPrint.ps1 -Watch`.

**Kept on purpose (not brand-visible; they do not match the AC-7.6 grep `multiprint(?!er)`):**
- Function names `New-MultiPrinter`, `Remove-MultiPrinter` and `Set-DefaultMultiPrinter` use the generic term (Q1 = A).
- `$global:MPErrorShown` is an internal variable shared between the ps1 and `Launcher.cs`. Renaming it would mean changing both in lockstep for no user value.
- The site's `localStorage` key `mp-lang` is the visitor's saved language choice. The origin (`eslamfariedshawky.github.io`) does not change with the repo rename, so keeping the key keeps the choice. Add a comment saying why.

Every remaining `MultiPrint` string in `src/` must carry a `# Legacy (v2.x MultiPrint) — kept for upgrade compatibility` comment (R6).

---

## 3. Upgrade flows

All three flows go through the same code path: **UI start (elevated) → `Start-InitialLoad` → `Update-WatcherIfNeeded`**. The watcher itself (`--watch`, not elevated) adds a second line of defense, `Ensure-LegacyLocks`, which keeps the "never two services" rule even when the UI path did not run or a legacy exe is started again later.

### 3.1 Fresh install

1. The user downloads `DualPrint.zip`, extracts it and runs `DualPrint.exe` from Downloads. `Launcher.cs` sets the AppUserModelID `DualPrint.App`, asks for elevation (UAC shows "DualPrint", taken from the exe's file description) and runs the embedded `DualPrint.ps1`.
2. The script creates `C:\DualPrint` and `queues\`. The language picker appears because there is no `settings.json`.
3. `Update-WatcherIfNeeded`: config is empty → `Remove-LegacyServices` finds nothing → the service status shows stopped, which is the current behavior for 0 printers.
4. The user adds the first printer (`BtnSave`) → `New-MultiPrinter` (PDF folder prefilled with `Documents\DualPrint PDFs`) → `Register-Watcher`:
   - copies `Downloads\DualPrint.exe` → `C:\DualPrint\DualPrint.exe`
   - registers the task `DualPrint Service` with action `C:\DualPrint\DualPrint.exe --watch` (same triggers and settings as today) and starts it.
5. The watcher takes `Local\DualPrintService`, then `Local\MultiPrintWatcher` and `Local\DualPrintWatcher` → starts printing. The sidebar shows "Service running" (AC-1.3).
6. Result: no `MultiPrint.exe` and no `MultiPrint*` task (AC-1.4).

### 3.2 Upgrade from MultiPrint v2.2.5

Start state: task `MultiPrint Watcher` → `C:\DualPrint\MultiPrint.exe --watch` is running and holds `Local\MultiPrintWatcher` and `Local\DualPrintWatcher`. `printers.json`, `settings.json` (with `Lang`) and `history.jsonl` exist. A 2.2.5 UI window may also be open (AC-2.11).

1. The user runs `DualPrint.exe` (from anywhere) and approves UAC.
2. `settings.json` already has `Lang` → no language picker (AC-2.1). Nothing in `C:\DualPrint` is moved or rewritten (R5).
3. `Start-InitialLoad` → `Refresh-Printers` shows the printers. PDF folders are resolved by `Get-PdfFolder`, so an empty `PdfFolder` displays as `Documents\MultiPrint PDFs` (AC-2.2, AC-2.10).
4. `Update-WatcherIfNeeded` runs, in this order:
   1. ACL check (unchanged).
   2. **`Pin-LegacyPdfFolders`**: every printer whose targets include `Microsoft Print to PDF` and whose `PdfFolder` is empty gets `PdfFolder = Documents\MultiPrint PDFs`. Non-empty values are never touched (AC-2.9). The file is saved once and only if something changed. It is skipped if `printers.json` could not be read (`$script:ConfigError`), as `Save-Config` already enforces.
   3. **`Remove-LegacyServices`**, for each legacy task in (`MultiPrint Watcher`, `DualPrint Watcher`): **Disable** → **Stop** → **Unregister**. Then it kills legacy processes found by command line (R2): `MultiPrint.exe` with `--watch`, and `powershell.exe` with `DualPrint\DualPrint.ps1` and `-Watch`. It returns `$true` if anything was found (AC-2.3, R3).
   4. `$needs` is computed as today, plus "a legacy service was found". Since `DualPrint Service` does not exist yet, `$needs` is true → **`Register-Watcher`**: stops its own task (if any) → copies the exe to `C:\DualPrint\DualPrint.exe` → registers `DualPrint Service` → starts it.
   5. **`Wait-ServiceRunning`** polls `Test-ServiceRunning` (mutex `Local\DualPrintService`) for up to 10 s.
   6. **Only if the service is confirmed running:** `Retire-LegacyExe` renames `C:\DualPrint\MultiPrint.exe` → `C:\DualPrint\MultiPrint.exe.old` (overwriting an older `.old` file). Windows allows renaming an exe that is running, so this works even with the 2.2.5 UI open (AC-2.11). If the rename fails, it is logged and retried on the next launch.
   7. `Refresh-Service` → "Service running".
5. The new watcher takes all three locks, because the legacy watcher was killed in step 4.3. If a legacy watcher still holds a lock (because the kill failed, or it restarted in the gap), the new watcher **does not process jobs** until it holds every legacy lock (see §4, `Ensure-LegacyLocks`). Printing therefore never happens twice. In that window the legacy watcher prints the same `printers.json` exactly once.
6. AC-2.4: the `MultiPrint Watcher` task no longer exists, so its one-minute trigger and 999 restarts cannot fire.
7. AC-2.6: at logon only `DualPrint Service` has a trigger.

**Old exe launched later (AC-2.7).** For example, from `Downloads\MultiPrint.exe` or a pinned icon:
- The 2.2.5 UI's `Update-WatcherIfNeeded` sees no `MultiPrint Watcher` task → its `Register-Watcher` runs. Its `Stop-Watchers` touches only `MultiPrint Watcher`, `DualPrint Watcher`, `MultiPrint.exe --watch` and the 1.x PowerShell watcher, **never** `DualPrint Service` or `DualPrint.exe`. It copies itself back to `C:\DualPrint\MultiPrint.exe` and registers and starts `MultiPrint Watcher`.
- The 2.2.5 watcher starts, finds `Local\MultiPrintWatcher` held by DualPrint, sets `WatcherAlreadyRunning` and exits 0. It does not print. The one-minute trigger repeats this harmlessly.
- The 2.2.5 UI shows "Service running", because it reads `Local\MultiPrintWatcher`, which DualPrint holds.
- The next time `DualPrint.exe` opens, step 4.3 unregisters `MultiPrint Watcher` again and step 4.6 retires the exe again.

**Old exe left in `C:\DualPrint` (AC-2.8).** After a successful upgrade it is renamed to `MultiPrint.exe.old`. It cannot run by double-click and no task points to it. If the rename is not possible, the exe stays and is inert for the reasons above (locks plus `Ensure-LegacyLocks`). A pinned `C:\DualPrint\MultiPrint.exe` shortcut will show as broken. The release notes and CHANGELOG tell users to re-pin `DualPrint.exe`.

### 3.3 Upgrade from DualPrint 1.x

Start state: task `DualPrint Watcher` → `powershell.exe … C:\DualPrint\DualPrint.ps1 -Watch`, holding `Local\DualPrintWatcher`.

Same as §3.2. Step 4.3 disables, stops and unregisters `DualPrint Watcher` and kills the PowerShell watcher (AC-3.1). There is no `MultiPrint.exe`, so step 4.6 does nothing. `C:\DualPrint\DualPrint.ps1` is left untouched: it is inert without its task, and removing it is outside the spec.

- AC-3.3: `DualPrint Service` is never in the legacy list, and `DualPrint.exe` never matches the legacy process filter. `Register-Watcher` still stops and restarts its **own** task during re-registration, which R2 allows.
- AC-3.4: `Test-ServiceRunning` checks only `Local\DualPrintService`. A 1.x or 2.2.5 watcher holds only the old names, so it is never reported as the DualPrint service.

### 3.4 Data kept (R5, AC-2.2, AC-2.10)

| File | Action |
|---|---|
| `printers.json` | Read as is. Only change: an empty `PdfFolder` on PDF-target printers is filled with the legacy folder. Same schema, so 2.2.5 can still read it. |
| `settings.json`, `history.jsonl`, `log.txt`, `SumatraPDF.exe`, `SumatraPDF-settings.txt`, `queues\*`, Windows printers and ports | Untouched |
| `Documents\MultiPrint PDFs` and any custom folder | Never moved or renamed |

### 3.5 Failure and rollback

| Failure point | State left | Recovery |
|---|---|---|
| Before 4.3 (e.g. ACL repair throws) | 2.2.5 service still running, nothing changed | Logged. The next launch retries. |
| 4.2 pin fails to save | No data change (the write is all-or-nothing at the `Set-Content` level, and skipped when config is unreadable) | `Get-PdfFolder` still routes empty folders to the legacy folder, so printing is correct. The next launch retries. |
| After 4.3, before 4.4 completes (e.g. `Register-ScheduledTask` throws) | **No service running**; old exe still in place (retirement only happens after confirmation) | The UI shows "Service stopped" in red, and clicking it runs `Start-ServiceNow` → `Register-Watcher`. The next launch also retries, because `$needs` is true with no task. No double printing is possible, because at most one watcher exists. |
| 4.5 times out (task registered but watcher not up) | Task present; the one-minute trigger and restart settings will keep trying | Old exe **not** retired. Logged. The next launch re-evaluates. |
| 4.6 rename fails (file locked in a way that blocks rename) | Old exe stays, inert | Retried on the next launch. |

**Manual rollback to 2.2.5** (for TROUBLESHOOTING.md, tech-writer):
1. In Task Scheduler, delete `DualPrint Service`.
2. End `DualPrint.exe` in Task Manager.
3. Run `MultiPrint.exe` 2.2.5. It re-registers `MultiPrint Watcher`.

The data is compatible both ways. Without step 1, the DualPrint service stays in charge and the 2.2.5 watcher exits on the lock, which is still safe.

---

## 4. Function-level design (`src/DualPrint.ps1`)

### 4.1 Constants (top of file)

```powershell
$Root             = 'C:\DualPrint'
$RootExe          = Join-Path $Root 'DualPrint.exe'
$DefaultPdf       = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'DualPrint PDFs'
$TaskName         = 'DualPrint Service'
$ServiceMutexName = 'Local\DualPrintService'

# Legacy (v2.x MultiPrint and 1.x DualPrint) — kept for upgrade compatibility, see ADR 0002
$LegacyDefaultPdf  = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'MultiPrint PDFs'
$LegacyTaskNames   = @('MultiPrint Watcher', 'DualPrint Watcher')
$LegacyMutexNames  = @('Local\MultiPrintWatcher', 'Local\DualPrintWatcher')
$LegacyExe         = Join-Path $Root 'MultiPrint.exe'
```
`$OldTaskName` is removed. Every user of it switches to `$LegacyTaskNames`.

### 4.2 New functions

```powershell
# Effective PDF folder of a printer. Empty = created by <= 2.2.5, whose fallback was "MultiPrint PDFs" (AC-2.10).
function Get-PdfFolder($cfg) { if ($cfg.PdfFolder) { $cfg.PdfFolder } else { $LegacyDefaultPdf } }

# AC-2.10: make the legacy fallback explicit in printers.json. Idempotent; 3.0 never writes an empty PdfFolder for a PDF printer.
function Pin-LegacyPdfFolders {
    $all = @(Get-Config); if ($script:ConfigError) { return }
    $changed = $false
    foreach ($c in $all) {
        if ((@(Get-Targets $c) -contains $PdfTarget) -and -not $c.PdfFolder) {
            $c | Add-Member PdfFolder $LegacyDefaultPdf -Force; $changed = $true
        }
    }
    if ($changed) { Save-Config $all; Write-Log "Pinned legacy PDF folder for upgraded printers" }
}

# R2: legacy = what it runs, never by name alone. DualPrint.exe is never matched.
function Get-LegacyWatcherProcesses {
    Get-CimInstance Win32_Process -Filter "Name='MultiPrint.exe' OR Name='powershell.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.ProcessId -ne $PID -and (
        ($_.Name -eq 'MultiPrint.exe' -and $_.CommandLine -match '\s--watch\b') -or
        ($_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'DualPrint\\DualPrint\.ps1' -and $_.CommandLine -match '-Watch')) }
}

# R3: disable first so the one-minute trigger / 999 restarts cannot fire between stop and unregister.
# Needs admin (UI only). Returns $true if anything legacy was found.
function Remove-LegacyServices {
    $found = $false
    foreach ($t in $LegacyTaskNames) {
        if (Get-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue) {
            $found = $true
            try { Disable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue | Out-Null } catch {}
            try { Stop-ScheduledTask    -TaskName $t -ErrorAction SilentlyContinue } catch {}
            try { Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction Stop; Write-Log "Removed legacy task: $t" }
            catch { Write-Log "Could not remove legacy task ${t}: $_" }
        }
    }
    foreach ($p in @(Get-LegacyWatcherProcesses)) {
        $found = $true
        try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch { Write-Log "Could not stop legacy pid $($p.ProcessId): $_" }
    }
    if ($found) { Start-Sleep -Milliseconds 700 }
    return $found
}

# AC-2.8: rename (not delete). A running exe can be renamed, and the user keeps a manual rollback path.
function Retire-LegacyExe {
    if (-not (Test-Path -LiteralPath $LegacyExe)) { return }
    try { Move-Item -LiteralPath $LegacyExe -Destination "$LegacyExe.old" -Force -ErrorAction Stop; Write-Log "Retired $LegacyExe" }
    catch { Write-Log "Could not retire ${LegacyExe}: $_" }
}

function Wait-ServiceRunning([int]$seconds = 10) {
    $until = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $until) { if (Test-ServiceRunning) { return $true }; Start-Sleep -Milliseconds 500 }
    return $false
}

# "DualPrint 3.0.0" from the running exe (AC-4.4). Falls back to the bare name when run as a .ps1.
function Get-AppVersionText {
    if ($AppExe -like '*.exe') {
        try { $v = [Diagnostics.FileVersionInfo]::GetVersionInfo($AppExe)
              return "DualPrint {0}.{1}.{2}" -f $v.FileMajorPart, $v.FileMinorPart, $v.FileBuildPart } catch {}
    }
    return 'DualPrint'
}
```

### 4.3 Watcher: `Start-Watcher` + `Ensure-LegacyLocks` (R4)

```powershell
function Start-Watcher {
    $mutex = New-Object Threading.Mutex($false, $ServiceMutexName)
    <# acquire exactly as today (WaitOne(0), AbandonedMutexException => got) #>
    if (-not $got) { $global:WatcherAlreadyRunning = $true; return }

    $script:LegacyLocks = @{}          # name -> Mutex object we own
    $lastLegacyKill = [datetime]::MinValue
    Write-Log "Watcher started (pid $PID)"
    try {
      while ($true) {
        <# heartbeat as today #>
        if (-not (Ensure-LegacyLocks)) {
            # A legacy watcher still owns a lock: it is printing; we must not (exactly-once).
            if (((Get-Date) - $lastLegacyKill).TotalSeconds -ge 60) {
                foreach ($p in @(Get-LegacyWatcherProcesses)) { try { Stop-Process -Id $p.ProcessId -Force } catch {} }
                $lastLegacyKill = Get-Date; Write-Log "Legacy watcher holds a lock; waiting"
            }
            Start-Sleep -Milliseconds 700; continue
        }
        <# job loop and 6-hourly clean-up exactly as today, but Send-ToTarget uses Get-PdfFolder #>
      }
    } finally {
        foreach ($m in $script:LegacyLocks.Values) { try { $m.ReleaseMutex() } catch {} }
        try { $mutex.ReleaseMutex() } catch {}
        Write-Log "Watcher stopped (pid $PID)"
    }
}

# Returns $true only when every legacy lock is owned by this thread. Never re-waits on a lock already owned
# (that would raise the recursion count and leak on release).
function Ensure-LegacyLocks {
    foreach ($n in $LegacyMutexNames) {
        if ($script:LegacyLocks.ContainsKey($n)) { continue }
        $m = New-Object Threading.Mutex($false, $n); $ok = $false
        try { $ok = $m.WaitOne(0) } catch [Threading.AbandonedMutexException] { $ok = $true } catch { $ok = $false }
        if ($ok) { $script:LegacyLocks[$n] = $m } else { $m.Dispose() }
    }
    return ($script:LegacyLocks.Count -eq $LegacyMutexNames.Count)
}
```
Notes for backend-dev:
- The watcher runs non-elevated (`RunLevel Limited`). It can kill a same-user, same-integrity legacy watcher (2.2.5 is registered `Limited`). It **cannot** unregister tasks; that stays the UI's job. If a legacy watcher runs elevated (possible for 1.x) and cannot be killed, the new watcher keeps yielding. Jobs are still printed once, by the legacy watcher, until the next UI launch cleans it up.
- The Launcher's restart loop re-invokes `Start-Watcher` on the same thread. The `finally` releases every lock, so the next call starts clean.
- Kill only on the 60 s throttle. Never kill anything that `Get-LegacyWatcherProcesses` does not match.

### 4.4 Changed functions

| Function | Change |
|---|---|
| `trap` (top) | Message box title `'DualPrint'`. |
| `Send-ToTarget` | `$dir = Get-PdfFolder $cfg` instead of `… else { $DefaultPdf }`. |
| `Start-Watcher` | Primary mutex `$ServiceMutexName`, plus `Ensure-LegacyLocks` gating (§4.3). |
| `$AclLog` and the inline log path in the locked-file block (line ~257) | Both use `%TEMP%\DualPrint-acl.txt`. Reuse `$AclLog` and define it before the first use. |
| `Find-Sumatra` | Temp prefix `dp_`. |
| `Show-LanguagePicker` XAML | `Title="DualPrint"`. |
| `Stop-Watchers` | **Split.** It becomes `Stop-OwnService`, which stops `$TaskName` and kills `DualPrint.exe --watch` processes whose path is `$RootExe` (excluding `$PID`). That is the R2-allowed self-restart, so `Copy-Item` over `$RootExe` does not fail on a stray instance. Legacy handling moves to `Remove-LegacyServices`. |
| `Register-Watcher` | `Remove-LegacyServices` → `Stop-OwnService` → `Protect-RootFolder` → copy exe → register `$TaskName` (same triggers, settings and principal) → start. |
| `New-MultiPrinter` | Defensive invariant: if `$targets` contains `$PdfTarget` and `$pdfFolder` is empty, use `$DefaultPdf`. That way 3.0 never stores an empty folder for a PDF printer, which keeps `Get-PdfFolder`'s "empty means legacy" rule true. |
| `Uninstall-All` (AC-2.12) | Remove printers → `Remove-LegacyServices` → `Stop-OwnService` → unregister `$TaskName`. All three tasks end up gone. |
| `Test-ServiceRunning` | `TryOpenExisting($ServiceMutexName)` only (AC-3.4). |
| `New-TargetCard` | `$folder = Get-PdfFolder $cfg`. |
| `Open-Editor` | `$TxtPdf.Text = if ($cfg) { Get-PdfFolder $cfg } else { $DefaultPdf }`. Editing a legacy printer shows and keeps `MultiPrint PDFs`; a new printer gets `DualPrint PDFs` (AC-1.5, AC-2.9). |
| Main window XAML | `Title="DualPrint"`, sidebar header `Text="DualPrint"`. The footer becomes `<TextBlock x:Name="TxtVersion" FlowDirection="LeftToRight" …/>` (AC-4.5), and its text is set to `Get-AppVersionText` after load (AC-4.4). |
| `Update-WatcherIfNeeded` | See below. |

```powershell
function Update-WatcherIfNeeded {
    try { if (Test-RootOpen) { Protect-RootFolder } } catch { Write-Log "ACL check: $_" }
    try { Pin-LegacyPdfFolders } catch { Write-Log "PDF folder pin: $_" }
    $legacy = $false
    try { $legacy = Remove-LegacyServices } catch { Write-Log "Legacy clean-up: $_" }   # runs even with 0 printers
    if (@(Get-Config).Count -eq 0) { try { Refresh-Service } catch {}; return }
    try {
        $task  = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        $needs = $legacy -or (-not $task) -or <# same exe-path / trigger / hash checks as today #>
        if ($needs) { Register-Watcher }
        elseif (-not (Test-ServiceRunning)) { Start-ScheduledTask -TaskName $TaskName }
        if (Wait-ServiceRunning) { Retire-LegacyExe } else { Write-Log "Service not confirmed; legacy exe kept" }
    } catch { Write-Log "Watcher upgrade: $_" }
    Refresh-Service
}
```
`Wait-ServiceRunning` blocks the UI thread for up to 10 s. That is the same pattern as today's `Start-Sleep` in `Register-Watcher`, and it runs at `ApplicationIdle` after the window is visible. If review wants it shorter, 5 s is acceptable, because a missed retirement is simply retried on the next launch.

### 4.5 `src/Launcher.cs`

- Assembly attributes as listed in §2. The version stays a literal that `build.ps1` rewrites; change the literal in source to `3.0.0.0`.
- `SetCurrentProcessExplicitAppUserModelID("DualPrint.App")`.
- `GetManifestResourceStream("DualPrint.ps1")`. If it returns `null`, throw `InvalidOperationException("Embedded script DualPrint.ps1 is missing")`, so a build/resource name mismatch fails loudly instead of with a NullReferenceException.
- Both `MessageBoxW` captions become `"DualPrint"`.

---

## 5. Build and release (ADR 0003)

### 5.1 `build.ps1`
- One constant, `$AppName = 'DualPrint'`, drives `src\$AppName.ps1`, `build\$AppName.ps1`, `/resource:…,$AppName.ps1`, `/out:build\$AppName.exe` and `build\$AppName.zip`.
- Header comment and `Write-Host` text say DualPrint.
- **Guard (AC-1.1, AC-6.5):** after `Compress-Archive`, open the zip (`[IO.Compression.ZipFile]::OpenRead`) and `throw` if any entry name matches `MultiPrint`, or if the zip does not contain exactly `DualPrint.exe`.
- Local builds produce only canonical `DualPrint` outputs. CI creates the release-only `MultiPrint.zip` alias after this build; both archives contain exactly `DualPrint.exe`.
- It does not delete old `build\MultiPrint.*` files; `build/` is git-ignored. CI starts from a clean checkout.

### 5.2 `.github/workflows/release.yml`
- After the canonical build, copy `build/DualPrint.zip` to `build/MultiPrint.zip` with identical bytes for 3.0.0 and every future release (Owner-approved T013 compatibility decision).
- Checksum lines: `<hash>  DualPrint.zip` and `<hash>  MultiPrint.zip`, with the same SHA-256 hash for both archives.
- `upload-artifact` / `download-artifact` name: `DualPrint`. Paths: `build/DualPrint.zip`, `build/MultiPrint.zip`, `build/SHA256SUMS.txt`.
- `action-gh-release`:
  - `files: DualPrint.zip, MultiPrint.zip, SHA256SUMS.txt` (T013-amended AC-6.3, exactly these three).
  - `name:` "DualPrint 3.0.0", i.e. `DualPrint ` + the tag without its leading `v`. Compute it in a small step output, because GitHub expressions cannot strip a prefix.
  - Release notes (AC-6.4): the release job checks out only `docs/release-notes/` (sparse) and passes `body_path: docs/release-notes/${{ github.ref_name }}.md` when that file exists, keeping `generate_release_notes: true`. The tech-writer writes `docs/release-notes/v3.0.0.md`, containing the one-line rename notice, "printers and history are kept" and "re-pin `DualPrint.exe`".
- Comments: MultiPrint → DualPrint.
- Keep the third-party actions pinned to the same SHAs (no new actions).

### 5.3 Download link compatibility (decision, ADR 0003)
- **Current decision (T013; Owner approved):** publish `MultiPrint.zip` as an identical-byte alias of canonical `DualPrint.zip` on 3.0.0 and every future release, with checksum lines for both names. This supersedes the original canonical-only decision and its pending confirmation below. The amended AC-6.3 permits exactly the two zips and `SHA256SUMS.txt`.
- `releases/latest/download/MultiPrint.zip` remains usable while this contract is maintained. Version-pinned legacy links remain unchanged.

**Historical reasoning (T010; superseded):**
- The site link becomes `<repo>/releases/latest/download/DualPrint.zip` (AC-6.1). `__REPO_URL__` follows the renamed repo automatically.
- **The release does not attach a `MultiPrint.zip` alias.** Reasons:
  1. AC-6.3 of the approved spec fixes the assets to exactly `DualPrint.zip` and `SHA256SUMS.txt`, and Goal 1 is one name.
  2. `latest/download/<name>` resolves only against the *current* latest release. An alias would have to be attached to every future release forever to keep working, not just to 3.0.0.
  3. The only place that ever linked to `…/latest/download/MultiPrint.zip` is the `dualprinter` Pages site, which goes offline anyway with the repo rename (AC-8.3), plus at most one day of external links.
  4. Version-pinned links keep working: `…/releases/download/v2.2.5/MultiPrint.zip` stays valid, including through the old repo URL thanks to GitHub's rename redirect.
- **Consequence:** `…/releases/latest/download/MultiPrint.zip` returns 404 after 3.0.0 is published. This is listed under Needs Owner, because the CEO brief asked that old links "keep working" and the approved spec forbids the alias. If the Owner wants the alias, it is a two-line change in `release.yml` (copy the zip, add it to `files:` and to `SHA256SUMS.txt`), and AC-6.3 must be amended.

### 5.4 Release order (spec §8, unchanged)
Branches reviewed and tested → Owner approval → **Owner renames the repo** → CEO updates `origin` (AC-8.4) → push `main` → push tag `v3.0.0` → `release.yml` publishes → the Website workflow runs on `release: published` and regenerates with the new `__SITE_URL__` and `__REPO_URL__` → verify AC-6.1, AC-6.2 and AC-8.1. **The tag must be pushed after the rename**, otherwise the release and site are generated with `dualprinter` URLs.

---

## 6. Website generator (high level)

The seo-specialist owns titles, descriptions, keywords, the "formerly MultiPrint" wording and the URL migration plan. This section only describes the mechanics.

- `tools/site_content.py`: `VERSION = "3.0.0"`. Add `BRAND = "DualPrint"`. Rewrite the copy in all six languages from MultiPrint to DualPrint. Add one per-language "formerly MultiPrint" phrase (key name chosen by SEO). Hero/description copy states "two or more printers" (AC-5.3). The generic "multi printer" wording stays (Q1 = A).
- `tools/build_site.py`: `DL = REPO + "/releases/latest/download/DualPrint.zip"`. Every hard-coded `"MultiPrint"` (`og:site_name`, the SoftwareApplication, WebSite and Article author/publisher/about JSON-LD, the breadcrumb, brand `aria-label` and text, crumbs, 404 title and link) uses `BRAND`. Add a comment next to `'mp-lang'` explaining that it is kept.
- **AC-5.2 limit:** each generated page may contain **at most one** `MultiPrint` match in total. If SEO wants a JSON-LD `alternateName: "MultiPrint"`, that counts as the page's one mention, so they cannot have both a visible mention and `alternateName`. That choice belongs to SEO.
- Regenerate `website/` with `python tools/build_site.py` and commit the output. Do not hand-edit it (AC-5.5).
- **Screenshots (AC-5.4):** `website/assets/screenshot-{en,ar,es,fr,de}.png`, 1620×1155 (the size `build_site.py` declares). They must be retaken from the built 3.0.0 exe, with demo data that uses the new default PDF folder (`DualPrint PDFs`). See task F005-6.
- `pages.yml`: no logic change.
- Old site URL: GitHub Pages is not redirected after a rename (AC-8.3), and a placeholder `dualprinter` repo is forbidden (AC-8.2). SEO writes the Search Console steps for the Owner.

---

## 7. Data model

No schema change. One value-level change in `printers.json`, applied once and idempotently by `Pin-LegacyPdfFolders`:

| Condition | Before | After |
|---|---|---|
| `Targets` contains `Microsoft Print to PDF` and `PdfFolder` is empty or missing | `"PdfFolder": null` / `""` / absent | `"PdfFolder": "<MyDocuments>\\MultiPrint PDFs"` |
| Anything else | unchanged | unchanged |

Invariant from 3.0 on: a printer with a PDF target always has a non-empty `PdfFolder` (enforced in `BtnSave`, which already requires it, and now also in `New-MultiPrinter`).

---

## 8. Test plan hooks for QA (real Windows 10/11, VM with snapshots)

Use a VM with three snapshots: **S0 clean**, **S1 v2.2.5 installed from the real GitHub release** (2+ printers, one with a PDF destination, one PDF printer with `PdfFolder` blanked by hand in `printers.json`, history entries, language = Arabic), and **S2 1.x simulated**. For S2: if no 1.x build is available, register a task `DualPrint Watcher` that runs `powershell.exe -File C:\DualPrint\DualPrint.ps1 -Watch`, where that script holds `Local\DualPrintWatcher` and loops. Say in the report whether S2 was real or simulated.

Useful checks (PowerShell):
```powershell
Get-ScheduledTask | Where-Object TaskName -match 'Print' | Select TaskName, State, @{n='Exe';e={$_.Actions[0].Execute}}, @{n='Args';e={$_.Actions[0].Arguments}}
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match '--watch|-Watch' } | Select ProcessId, Name, CommandLine
foreach ($n in 'Local\DualPrintService','Local\MultiPrintWatcher','Local\DualPrintWatcher') { $m=$null; "$n : " + [Threading.Mutex]::TryOpenExisting($n,[ref]$m) }
(Get-Item C:\DualPrint\DualPrint.exe).VersionInfo | Select FileDescription, ProductName, LegalCopyright, FileVersion
Add-Type -A System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::OpenRead("$PWD\DualPrint.zip").Entries.FullName
(Get-FileHash DualPrint.zip -A SHA256).Hash.ToLower(); Get-Content SHA256SUMS.txt
git grep -n -i -P "multiprint(?!er)"
```

| Area | What to verify | ACs |
|---|---|---|
| Build | `build.ps1 -Version 3.0.0` outputs only `DualPrint.*`. The zip holds only `DualPrint.exe`. The exe Details tab shows DualPrint and 3.0.0.0. | 1.1, 1.6, 6.5 |
| Fresh (S0) | UAC name. Task `DualPrint Service` → `C:\DualPrint\DualPrint.exe --watch`. No `MultiPrint*` file or task. New printer prefilled with `DualPrint PDFs`. Taskbar grouping (`DualPrint.App`). | 1.2–1.7 |
| Upgrade (S1) | No language picker. Printers identical (all fields, default badge). History intact. `MultiPrint Watcher` **gone** (not just Ready/Disabled). One `DualPrint.exe --watch`. All three mutexes exist. `MultiPrint.exe` → `MultiPrint.exe.old`. | 2.1–2.3, 2.8 |
| Persistence | Wait ≥ 3 min: still one watcher and no legacy task. Sign out/in and reboot: only the DualPrint service starts. | 2.4, 2.6 |
| Exactly once | Print one page: one copy per destination, one history line. Repeat after each scenario below. | 2.5, 2.7, 3.2 |
| PDF folders | A printer with a custom folder keeps it. A printer with blank `PdfFolder` writes to `MultiPrint PDFs`, and `printers.json` now holds that path explicitly. A new printer goes to `DualPrint PDFs`. | 1.5, 2.9, 2.10 |
| Old exe again | Run `Downloads\MultiPrint.exe` 2.2.5: it re-registers its task, but its watcher exits (no extra process remains, or it exits within seconds), printing stays exactly once, and the 2.2.5 UI does not break the DualPrint task. Reopen DualPrint: the legacy task is removed and the exe is re-retired. | 2.7 |
| Race | Kill `DualPrint.exe --watch`, start `MultiPrint.exe --watch` manually, then start the DualPrint task: log shows "Legacy watcher holds a lock; waiting", the legacy process is killed within about 60 s, and printing stays exactly once throughout. | R4 |
| UI open | With the 2.2.5 UI window open, run DualPrint: same outcome as the upgrade row. `printers.json` and `history.jsonl` still parse. | 2.11 |
| Remove all | All three task names are absent afterwards. | 2.12 |
| 1.x (S2) | `DualPrint Watcher` gone, PowerShell watcher gone, one DualPrint service, exactly-once printing. | 3.1, 3.2 |
| Self-safety | On S0 after install: reopen the app, Settings → Restart, reopen again. `DualPrint Service` always present and "Service running". | 3.3 |
| Status honesty | Only the 1.x stub running (DualPrint task disabled): sidebar shows "Service stopped". | 3.4 |
| Rollback | Make `Register-ScheduledTask` fail (e.g. a pre-created read-only task with the same name, or test by code injection on a dev build): service shows stopped, `MultiPrint.exe` **not** retired, and a relaunch recovers. Manual rollback steps from TROUBLESHOOTING work. | §3.5 |
| UI text ×5 langs | Window title, sidebar, picker title, footer "DualPrint 3.0.0", error box title. No "MultiPrint" on any page or dialog. Arabic footer renders LTR. | 4.1–4.5 |
| Site | Rebuild equals the committed `website/`. Download link, version, brand and JSON-LD on all 12 pages. At most one MultiPrint match per page. Screenshots retaken. | 5.1–5.6, 6.1 |
| Release (post-publish, CEO with Owner approval) | Assets exactly `DualPrint.zip` + `MultiPrint.zip` + `SHA256SUMS.txt`; zip bytes identical and both checksum lines match; old latest-download alias works; title "DualPrint 3.0.0", notes line. Old repo URL redirects. | 6.2–6.4, 8.1–8.2 |
| Repo grep | Attach the `git grep` output; every match must be on the allowlist (see the spec issue in the report about the allowlist). | 7.6 |

---

## 9. Task breakdown

IDs are suggestions; the CEO assigns the real ones. Each task is one branch.

| # | Owner | Branch | Scope (files) | Depends on | Size |
|---|---|---|---|---|---|
| F005-1 | backend-dev | `feat/be-<id>-dualprint-identity` | `git mv src/MultiPrint.ps1 src/DualPrint.ps1`. Constants in §4.1 (no new logic yet). XAML titles, trap title, ACL log, `dp_` prefix, `Test-ServiceRunning` and primary mutex rename, R6 comments. `src/Launcher.cs` (§4.5). `build.ps1` (§5.1 incl. zip guard). | this doc | S |
| F005-2 | backend-dev | `feat/be-<id>-legacy-upgrade` (from F005-1) | `src/DualPrint.ps1` only: `Get-PdfFolder`, `Pin-LegacyPdfFolders`, `Get-LegacyWatcherProcesses`, `Remove-LegacyServices`, `Stop-OwnService`, `Retire-LegacyExe`, `Wait-ServiceRunning`, `Ensure-LegacyLocks` in the watcher, `Update-WatcherIfNeeded`, `Uninstall-All`, `New-MultiPrinter` invariant, version footer. | F005-1 | M |
| F005-3 | devops-engineer | `feat/ops-<id>-release-dualprint` | `.github/workflows/release.yml` (§5.2). Comment-only touch to `pages.yml`. | F005-1 (output names) | S |
| F005-4 | seo-specialist | `feat/seo-<id>-dualprint-site` | `tools/site_content.py`, `tools/build_site.py`, regenerated `website/**` except the screenshots, plus the URL migration plan and Owner Search Console steps. | this doc (can run in parallel with F005-1/2) | M |
| F005-5 | tech-writer | `feat/docs-<id>-dualprint-docs` | `README.md`, `SECURITY.md`, `LICENSE`, `CHANGELOG.md` (3.0.0 entry), `docs/USER_GUIDE.md`, `docs/TROUBLESHOOTING.md` (duplicate-printing row and rollback steps from §3.5), `docs/ARCHITECTURE.md` (new names, `Ensure-LegacyLocks`, and fix the existing "every five minutes" → one minute), `docs/BUILDING.md`, `docs/PUBLISHING.md`, new `docs/release-notes/v3.0.0.md`. | F005-2 merged-ready (final names); F005-3 for the release-notes path | M |
| F005-6 | qa-engineer → seo-specialist | capture: QA (no branch, files handed to the CEO); commit: on the F005-4 branch | **Screenshots.** QA builds 3.0.0 from F005-2, sets up the same demo printers as the current shots (PDF folder `Documents\DualPrint PDFs`), and captures the main window in en, ar, es, fr and de at 1620×1155 (same framing as today). The CEO hands the PNGs to the seo-specialist, who replaces `website/assets/screenshot-*.png` on the F005-4 branch and rebuilds. If UAC blocks automated capture on the test machine, this becomes a 5-minute Owner step (run the exe, screenshot five windows). | F005-2, F005-4 | S |
| F005-7 | qa-engineer | tests + `team/bugs.md` | Full §8 plan on a real Windows VM (S0, S1, S2), with `git grep` output attached. | F005-1…6 | M |

Order: F005-1 → (F005-2 ∥ F005-3 ∥ F005-4) → F005-5 → F005-6 → code-reviewer per branch → F005-7 → security-engineer → Owner gate (approve release + rename repo) → CEO release steps (§5.4).

ui-ux-designer: **skipped.** No layout change (Q1 = A). The only UI edits are text, a footer `x:Name` and `FlowDirection="LeftToRight"`, all specified here. The CEO should note the skip on the board.
