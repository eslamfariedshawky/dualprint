# Tests import function ASTs only: application startup, WPF and machine setup never execute.
$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'src/DualPrint.ps1'
$tokens = $null; $parseErrors = $null
$appAst = [Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors -join "`n") }
foreach ($fn in $appAst.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] }) {
    Invoke-Expression $fn.Extent.Text
}

if (-not ('DualPrintTestMutex' -as [type])) {
    # A CLR double throws the same exception type as the OS API; PowerShell script methods wrap it differently.
    Add-Type @'
public class DualPrintTestMutex {
    public string Name, Failure;
    public bool Available;
    public int Waits, Releases, Disposals;
    public bool WaitOne(int timeout) {
        Waits++;
        if (Failure == "abandoned") throw new System.Threading.AbandonedMutexException();
        if (Failure == "denied") throw new System.UnauthorizedAccessException();
        return Available;
    }
    public void ReleaseMutex() { Releases++; }
    public void Dispose() { Disposals++; }
}
'@
}
function New-TestMutex([string]$name, [bool]$available = $true, [string]$failure = '') {
    $m = New-Object DualPrintTestMutex
    $m.Name = $name; $m.Available = $available; $m.Failure = $failure
    return $m
}

Describe 'Legacy PDF routing and pinning' {
    BeforeEach {
        $LegacyDefaultPdf = 'C:\Users\Tester\Documents\MultiPrint PDFs'
        $DefaultPdf = 'C:\Users\Tester\Documents\DualPrint PDFs'
        $PdfTarget = 'Microsoft Print to PDF'
        $pdfFixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $pdfFixture | Out-Null
        $ConfigPath = Join-Path $pdfFixture 'printers.json'
        $script:ConfigError = $null
        Mock Write-Log {}
    }
    It 'routes a blank legacy PDF folder to its previous destination' {
        Get-PdfFolder ([pscustomobject]@{ PdfFolder = '' }) | Should Be 'C:\Users\Tester\Documents\MultiPrint PDFs'
    }
    It 'keeps a nonempty Unicode custom destination' {
        Get-PdfFolder ([pscustomobject]@{ PdfFolder = 'D:\ملفات\Épreuves' }) | Should Be 'D:\ملفات\Épreuves'
    }
    It 'pins only PDF printers and saves once across repeated upgrades' {
        $items = @(
            [pscustomobject]@{ Name = 'قديم'; Targets = @('Microsoft Print to PDF'); PdfFolder = ''; PdfEnabled = $false; PaperSize = 'a4' },
            [pscustomobject]@{ Name = 'custom'; Targets = @('Microsoft Print to PDF'); PdfFolder = 'D:\ملفات\Épreuves'; PdfPrefix = 'é' },
            [pscustomobject]@{ Name = 'paper'; Targets = @('HP'); PdfFolder = '' })
        ConvertTo-Json -InputObject $items -Depth 5 | Set-Content $ConfigPath -Encoding UTF8
        Pin-LegacyPdfFolders
        # A second pin must not rewrite a fully pinned configuration (exclusive writer makes an attempted rewrite fail).
        $readOnly = [IO.File]::Open($ConfigPath, 'Open', 'Read', 'Read')
        try { Pin-LegacyPdfFolders } finally { $readOnly.Dispose() }
        $saved = @(Get-Config)
        $saved[0].PdfFolder | Should Be 'C:\Users\Tester\Documents\MultiPrint PDFs'
        $saved[0].Name | Should Be 'قديم'
        $saved[0].PdfEnabled | Should Be $false
        $saved[0].PaperSize | Should Be 'a4'
        $saved[1].PdfFolder | Should Be 'D:\ملفات\Épreuves'
        $saved[1].PdfPrefix | Should Be 'é'
        $saved[2].PdfFolder | Should Be ''
    }
    It 'leaves malformed JSON unchanged' {
        Set-Content $ConfigPath '{broken' -Encoding UTF8
        $before = [IO.File]::ReadAllText($ConfigPath)
        try { Pin-LegacyPdfFolders } catch { }
        [IO.File]::ReadAllText($ConfigPath) | Should Be $before
    }
    It 'preserves original bytes if atomic pin replacement is denied' {
        $items = @([pscustomobject]@{ Name = 'old'; Targets = @('Microsoft Print to PDF'); PdfFolder = '' })
        ConvertTo-Json -InputObject $items -Depth 5 | Set-Content $ConfigPath -Encoding UTF8
        $before = [IO.File]::ReadAllText($ConfigPath)
        # Permit reading/writing, but deny rename/delete sharing: temp writes succeed and replacement must fail.
        $locked = [IO.File]::Open($ConfigPath, 'Open', 'Read', 'ReadWrite')
        try { { Pin-LegacyPdfFolders } | Should Throw } finally { $locked.Dispose() }
        [IO.File]::ReadAllText($ConfigPath) | Should Be $before
        @(Get-ChildItem $pdfFixture -Force).Count | Should Be 1
        Get-PdfFolder (@(Get-Config)[0]) | Should Be 'C:\Users\Tester\Documents\MultiPrint PDFs'
    }
    It 'uses the legacy destination when copying an actual PDF fixture' {
        $LegacyDefaultPdf = Join-Path $TestDrive 'legacy-pdfs'
        $DefaultPdf = Join-Path $TestDrive 'new-pdfs'
        Mock Start-Process { throw 'external printing is forbidden in this test' }
        $file = Join-Path $TestDrive 'fixture.pdf'; Set-Content $file 'fixture'
        $result = Send-ToTarget ([pscustomobject]@{ Name = 'old'; PdfFolder = '' }) $file $PdfTarget
        $result.Ok | Should Be $true
        (Split-Path $result.Msg -Parent) | Should Be $LegacyDefaultPdf
        Get-Content -LiteralPath $result.Msg | Should Be 'fixture'
    }
    It 'never saves a new PDF printer with an empty folder' {
        $Root = $TestDrive; $Driver = 'test'
        Mock Get-Printer {}
        Mock Get-PrinterDriver { $true }
        Mock Add-PrinterPort {}
        Mock Add-Printer {}
        Mock Restart-Service { throw 'real spooler restart is forbidden in this test' }
        Mock Get-Config { @() }
        $script:saved = $null
        Mock Save-Config { param($items); $script:saved = @($items) }
        New-MultiPrinter 'New printer' @('Microsoft Print to PDF') '' ''
        $script:saved[0].PdfFolder | Should Be 'C:\Users\Tester\Documents\DualPrint PDFs'
    }
    It 'does not write unreadable configuration' {
        Set-Content $ConfigPath 'original bytes' -Encoding UTF8
        Mock Get-Config { $script:ConfigError = 'denied'; @() }
        { Pin-LegacyPdfFolders } | Should Not Throw
        Get-Content $ConfigPath | Should Be 'original bytes'
    }
}

Describe 'Pin write interruption' {
    It 'preserves original bytes when a serialization write fails midway' {
        $ConfigPath = Join-Path $TestDrive 'interrupted.json'
        $LegacyDefaultPdf = Join-Path $TestDrive 'legacy-pdfs'; $PdfTarget = 'Microsoft Print to PDF'
        ConvertTo-Json -InputObject @([pscustomobject]@{ Name = 'old'; Targets = @($PdfTarget); PdfFolder = '' }) -Depth 5 |
            Set-Content $ConfigPath -Encoding UTF8
        $before = [IO.File]::ReadAllText($ConfigPath)
        Mock Write-Log {}
        Mock Set-Content {
            param($Path, $LiteralPath)
            $target = if ($LiteralPath) { $LiteralPath } else { $Path }
            [IO.File]::WriteAllText($target, 'partial write')
            throw 'simulated disk-full failure'
        }
        { Pin-LegacyPdfFolders } | Should Throw
        [IO.File]::ReadAllText($ConfigPath) | Should Be $before
        @(Get-ChildItem $TestDrive -Force).Count | Should Be 1
    }
}

Describe 'Legacy process identity and service removal' {
    BeforeEach {
        $TaskName = 'DualPrint Service'
        $LegacyTaskNames = @('MultiPrint Watcher', 'DualPrint Watcher')
        $RootExe = 'C:\DualPrint\DualPrint.exe'
        $Root = 'C:\DualPrint'
        Mock Write-Log {}
        Mock Start-Sleep {}
    }
    It 'selects only exact legacy watcher commands, never UIs or misleading arguments' {
        $script:processes = @(
            [pscustomobject]@{ ProcessId = 11; Name = 'MultiPrint.exe'; CommandLine = '"C:\DualPrint\MultiPrint.exe" --watch' },
            [pscustomobject]@{ ProcessId = 12; Name = 'powershell.exe'; CommandLine = 'powershell.exe -NoProfile -File "C:\DualPrint\DualPrint.ps1" -Watch' },
            [pscustomobject]@{ ProcessId = 13; Name = 'MultiPrint.exe'; CommandLine = 'MultiPrint.exe' },
            [pscustomobject]@{ ProcessId = 14; Name = 'MultiPrint.exe'; CommandLine = 'MultiPrint.exe --watchSomething' },
            [pscustomobject]@{ ProcessId = 15; Name = 'powershell.exe'; CommandLine = 'powershell.exe -File C:\DualPrint\DualPrint.ps1 -WatchSomething' },
            [pscustomobject]@{ ProcessId = 16; Name = 'powershell.exe'; CommandLine = 'powershell.exe -File C:\DualPrint\DualPrint.ps1.bak -Watch' },
            [pscustomobject]@{ ProcessId = 17; Name = 'powershell.exe'; CommandLine = 'powershell.exe -File C:\OtherDualPrint\DualPrint.ps1 -Watch' },
            [pscustomobject]@{ ProcessId = 18; Name = 'DualPrint.exe'; CommandLine = 'C:\DualPrint\DualPrint.exe --watch' },
            [pscustomobject]@{ ProcessId = 19; Name = 'powershell.exe'; CommandLine = 'powershell.exe -Command "Write-Output C:\DualPrint\DualPrint.ps1 -Watch"' },
            [pscustomobject]@{ ProcessId = 20; Name = 'MultiPrint.exe'; CommandLine = 'MultiPrint.exe --watch-extra' },
            [pscustomobject]@{ ProcessId = 21; Name = 'powershell.exe'; CommandLine = 'powershell.exe -File C:\other.ps1 C:\DualPrint\DualPrint.ps1 -Watch' },
            [pscustomobject]@{ ProcessId = 22; Name = 'MultiPrint.exe'; CommandLine = $null },
            [pscustomobject]@{ ProcessId = 23; Name = 'powershell.exe'; CommandLine = $null },
            [pscustomobject]@{ ProcessId = $PID; Name = 'MultiPrint.exe'; CommandLine = 'MultiPrint.exe --watch' })
        Mock Get-CimInstance { $script:processes }
        (@(Get-LegacyWatcherProcesses).ProcessId -join ',') | Should Be '11,12'
    }
    It 'disables, stops and unregisters each old task before killing its watcher' {
        $script:events = @()
        Mock Get-ScheduledTask { param($TaskName); if ($TaskName -in @('MultiPrint Watcher','DualPrint Watcher')) { [pscustomobject]@{ TaskName = $TaskName } } }
        Mock Disable-ScheduledTask { param($TaskName); $script:events += "disable:$TaskName" }
        Mock Stop-ScheduledTask { param($TaskName); $script:events += "stop:$TaskName" }
        Mock Unregister-ScheduledTask { param($TaskName); $script:events += "unregister:$TaskName" }
        Mock Get-LegacyWatcherProcesses { [pscustomobject]@{ ProcessId = 123 } }
        Mock Stop-Process { param($Id); $script:events += "kill:$Id" }
        Remove-LegacyServices | Should Be $true
        ($script:events -join '|') | Should Be 'disable:MultiPrint Watcher|stop:MultiPrint Watcher|unregister:MultiPrint Watcher|disable:DualPrint Watcher|stop:DualPrint Watcher|unregister:DualPrint Watcher|kill:123'
    }
    It 'reports no legacy service on a clean machine' {
        Mock Get-ScheduledTask {}
        Mock Get-LegacyWatcherProcesses {}
        Remove-LegacyServices | Should Be $false
    }
    It 'continues legacy cleanup after an inaccessible old task' {
        $script:removed = @()
        Mock Get-ScheduledTask { $true }
        Mock Disable-ScheduledTask { throw 'denied' }
        Mock Stop-ScheduledTask { throw 'denied' }
        Mock Unregister-ScheduledTask { param($TaskName); $script:removed += $TaskName }
        Mock Get-LegacyWatcherProcesses {}
        Remove-LegacyServices | Should Be $true
        ($script:removed -join ',') | Should Be 'MultiPrint Watcher,DualPrint Watcher'
    }
    It 'self-restart kills only the installed exact executable watcher' {
        Mock Stop-ScheduledTask {}
        Mock Get-CimInstance { @(
            [pscustomobject]@{ ProcessId = 31; Name = 'DualPrint.exe'; ExecutablePath = 'C:\DualPrint\DualPrint.exe'; CommandLine = '"C:\DualPrint\DualPrint.exe" --watch' },
            [pscustomobject]@{ ProcessId = 32; Name = 'DualPrint.exe'; ExecutablePath = 'D:\Downloads\DualPrint.exe'; CommandLine = 'DualPrint.exe --watch' },
            [pscustomobject]@{ ProcessId = 33; Name = 'DualPrint.exe'; ExecutablePath = $null; CommandLine = 'C:\DualPrint\DualPrint.exe --watch' },
            [pscustomobject]@{ ProcessId = 34; Name = 'DualPrint.exe'; ExecutablePath = 'C:\DualPrint\DualPrint.exe'; CommandLine = 'DualPrint.exe --watch-extra' },
            [pscustomobject]@{ ProcessId = 35; Name = 'DualPrint.exe'; ExecutablePath = 'C:\DualPrint\DualPrint.exe'; CommandLine = 'DualPrint.exe' },
            [pscustomobject]@{ ProcessId = 36; Name = 'DualPrint.exe'; ExecutablePath = 'C:\DualPrint\DualPrint.exe'; CommandLine = $null },
            [pscustomobject]@{ ProcessId = $PID; Name = 'DualPrint.exe'; ExecutablePath = 'C:\DualPrint\DualPrint.exe'; CommandLine = 'DualPrint.exe --watch' }) }
        $script:killed = @()
        Mock Stop-Process { param($Id); $script:killed += $Id }
        Stop-OwnService
        ($script:killed -join ',') | Should Be '31'
        Assert-MockCalled Stop-ScheduledTask -Times 1 -Exactly -Scope It -ParameterFilter { $TaskName -eq 'DualPrint Service' }
    }
    It 'uninstall removes legacy services then its own service and task' {
        $script:events = @()
        Mock Get-Config { @() }
        Mock Remove-LegacyServices { $script:events += 'legacy'; $true }
        Mock Stop-OwnService { $script:events += 'own' }
        Mock Unregister-ScheduledTask { param($TaskName); $script:events += $TaskName }
        Uninstall-All
        ($script:events -join ',') | Should Be 'legacy,own,DualPrint Service'
    }
}

Describe 'Upgrade sequencing and rollback preservation' {
    BeforeEach {
        $fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $fixture | Out-Null
        $RootExe = Join-Path $fixture 'DualPrint.exe'; Set-Content $RootExe 'new'
        $AppExe = $RootExe; $TaskName = 'DualPrint Service'
        $LegacyExe = Join-Path $fixture 'MultiPrint.exe'; Set-Content $LegacyExe 'rollback'
        Mock Write-Log {}
        Mock Test-RootOpen { $false }
        Mock Pin-LegacyPdfFolders {}
        Mock Remove-LegacyServices { $false }
        Mock Get-Config { [pscustomobject]@{ Name = 'printer' } }
        Mock Get-ScheduledTask { [pscustomobject]@{ Actions = @([pscustomobject]@{ Execute = $RootExe }); Triggers = @([pscustomobject]@{ Repetition = [pscustomobject]@{ Interval = 'PT1M' } }, [pscustomobject]@{}) } }
        Mock Test-ServiceRunning { $true }
        Mock Refresh-Service {}
        Mock Start-ScheduledTask {}
        Mock Register-Watcher {}
    }
    It 'cleans legacy services even with zero printers' {
        Mock Get-Config { @() }
        $script:events = @()
        Mock Pin-LegacyPdfFolders { $script:events += 'pin' }
        Mock Remove-LegacyServices { $script:events += 'cleanup'; $true }
        Update-WatcherIfNeeded
        ($script:events -join ',') | Should Be 'pin,cleanup'
        Assert-MockCalled Register-Watcher -Times 0 -Exactly -Scope It
    }
    It 're-registers after finding a legacy service before confirming and retiring' {
        $script:events = @()
        Mock Pin-LegacyPdfFolders { $script:events += 'pin' }
        Mock Remove-LegacyServices { $script:events += 'cleanup'; $true }
        Mock Register-Watcher { $script:events += 'register' }
        Mock Wait-ServiceRunning { $script:events += 'ready'; $true }
        Mock Retire-LegacyExe { $script:events += 'retire' }
        Update-WatcherIfNeeded
        ($script:events -join ',') | Should Be 'pin,cleanup,register,ready,retire'
    }
    It 'keeps the old exe when service confirmation times out' {
        Mock Wait-ServiceRunning { $false }
        Update-WatcherIfNeeded
        Test-Path $LegacyExe | Should Be $true
        Test-Path "$LegacyExe.old" | Should Be $false
    }
    It 'keeps the old exe after registration failure' {
        Mock Get-ScheduledTask {}
        Mock Register-Watcher { throw 'task registration denied' }
        Update-WatcherIfNeeded
        Test-Path $LegacyExe | Should Be $true
        Assert-MockCalled Refresh-Service -Times 1 -Exactly -Scope It
    }
    It 'retries failed registration and retires only after successful readiness' {
        $script:attempts = 0; $script:retired = 0
        Mock Get-ScheduledTask {}
        Mock Register-Watcher { $script:attempts++; if ($script:attempts -eq 1) { throw 'first registration fails' } }
        Mock Wait-ServiceRunning { $script:attempts -gt 1 }
        Mock Retire-LegacyExe { $script:retired++ }
        Update-WatcherIfNeeded
        $script:retired | Should Be 0
        Update-WatcherIfNeeded
        $script:retired | Should Be 1
    }
}

Describe 'Legacy executable retirement' {
    BeforeEach {
        $fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $fixture | Out-Null
        $LegacyExe = Join-Path $fixture 'MultiPrint.exe'; Set-Content $LegacyExe 'rollback'
        Mock Write-Log {}
    }
    It 'renames the old executable without deleting its bytes' {
        Retire-LegacyExe
        Test-Path $LegacyExe | Should Be $false
        Get-Content "$LegacyExe.old" | Should Be 'rollback'
    }
    It 'preserves an existing rollback copy during a repeat upgrade' {
        Set-Content "$LegacyExe.old" 'first rollback'
        Retire-LegacyExe
        Get-Content "$LegacyExe.old" | Should Be 'first rollback'
        $copies = @(Get-ChildItem $fixture | Where-Object { $_.Name -like 'MultiPrint.exe.old.*' })
        $copies.Count | Should Be 1
        Get-Content $copies[0].FullName | Should Be 'rollback'
        Test-Path $LegacyExe | Should Be $false
    }
    It 'retains the executable when retirement fails' {
        Mock Move-Item { throw 'rename denied' }
        { Retire-LegacyExe } | Should Not Throw
        Test-Path $LegacyExe | Should Be $true
    }
}

Describe 'Watcher exclusion and mutex lifetime' {
    BeforeEach {
        $ServiceMutexName = 'Local\DualPrintTests-' + [guid]::NewGuid().ToString('N')
        $LegacyMutexNames = @('test-old-two', 'test-old-one')
        $script:LegacyLocks = @{}
        $script:mutexes = @{}
        $script:queueReads = 0
        $Root = $TestDrive; $HistoryPath = Join-Path $TestDrive 'history.jsonl'
        Mock Write-Log {}
        Mock Get-Config { $script:queueReads++; @() }
        if (Get-Command Get-LegacyWatcherProcesses -ErrorAction SilentlyContinue) { Mock Get-LegacyWatcherProcesses {} }
        Mock Start-Sleep { throw 'end test watcher' }
    }
    It 'does not report a primary-only watcher as ready' {
        $m = New-Object Threading.Mutex($false, $ServiceMutexName)
        try { Test-ServiceRunning | Should Be $false } finally { $m.Dispose() }
    }
    It 'reports ready only while primary and readiness handles exist' {
        $m = New-Object Threading.Mutex($false, $ServiceMutexName)
        $ready = New-Object Threading.Mutex($false, ($ServiceMutexName + '.Ready'))
        try { Test-ServiceRunning | Should Be $true } finally { $ready.Dispose(); $m.Dispose() }
        Test-ServiceRunning | Should Be $false
    }
    It 'waits for readiness and returns false at a bounded deadline' {
        $script:clock = [datetime]'2026-01-01'
        Mock Get-Date { $script:clock = $script:clock.AddSeconds(1); $script:clock }
        Mock Start-Sleep {}
        Mock Test-ServiceRunning { $false }
        Wait-ServiceRunning 2 | Should Be $false
    }
    It 'returns promptly when the watcher becomes ready' {
        Mock Test-ServiceRunning { $true }
        Wait-ServiceRunning 2 | Should Be $true
        Assert-MockCalled Start-Sleep -Times 0 -Exactly -Scope It
    }
    It 'does not recursively acquire a legacy lock it already owns' {
        foreach ($name in $LegacyMutexNames) { $script:mutexes[$name] = New-TestMutex $name }
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        Ensure-LegacyLocks | Should Be $true
        Ensure-LegacyLocks | Should Be $true
        $script:mutexes['test-old-two'].Waits | Should Be 1
        $script:mutexes['test-old-one'].Waits | Should Be 1
    }
    It 'disposes a contended legacy handle and retries it on the next pass' {
        $script:mutexes['test-old-two'] = New-TestMutex 'test-old-two' $false
        $script:mutexes['test-old-one'] = New-TestMutex 'test-old-one'
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        Ensure-LegacyLocks | Should Be $false
        $script:mutexes['test-old-two'].Disposals | Should Be 1
        $script:mutexes['test-old-two'].Available = $true
        Ensure-LegacyLocks | Should Be $true
        $script:mutexes['test-old-one'].Waits | Should Be 1
    }
    It 'accepts an abandoned lock as owned' {
        foreach ($name in $LegacyMutexNames) { $script:mutexes[$name] = New-TestMutex $name $true 'abandoned' }
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        Ensure-LegacyLocks | Should Be $true
    }
    It 'never reads queues while a legacy lock is held elsewhere' {
        $script:mutexes[$ServiceMutexName] = New-TestMutex $ServiceMutexName
        $script:mutexes['test-old-two'] = New-TestMutex 'test-old-two' $false
        $script:mutexes['test-old-one'] = New-TestMutex 'test-old-one'
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        try { Start-Watcher } catch { $_.Exception.Message | Should Match 'end test watcher' }
        $script:queueReads | Should Be 0
        $script:mutexes[$ServiceMutexName].Releases | Should Be 1
        $script:mutexes[$ServiceMutexName].Disposals | Should Be 1
        $script:mutexes['test-old-one'].Releases | Should Be 1
        $script:mutexes['test-old-one'].Disposals | Should Be 1
    }
    It 'never prints if readiness acquisition fails and closes every handle' {
        foreach ($name in @($ServiceMutexName) + $LegacyMutexNames) { $script:mutexes[$name] = New-TestMutex $name }
        $script:mutexes[$ServiceMutexName + '.Ready'] = New-TestMutex 'ready' $false
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        try { Start-Watcher } catch { }
        $script:queueReads | Should Be 0
        foreach ($m in $script:mutexes.Values) { $m.Disposals | Should Be 1 }
    }
    It 'publishes readiness by creating an initially owned mutex' {
        foreach ($name in @($ServiceMutexName, ($ServiceMutexName + '.Ready')) + $LegacyMutexNames) { $script:mutexes[$name] = New-TestMutex $name }
        $script:readyInitiallyOwned = $null
        Mock New-Object {
            param($TypeName, $ArgumentList)
            $m = $script:mutexes[$ArgumentList[1]]
            if ($ArgumentList[1] -eq ($ServiceMutexName + '.Ready')) { $script:readyInitiallyOwned = $ArgumentList[0] }
            if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }
            $m
        } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        try { Start-Watcher } catch { }
        $script:readyInitiallyOwned | Should Be $true
    }
    It 'does not read jobs when readiness construction fails' {
        foreach ($name in @($ServiceMutexName) + $LegacyMutexNames) { $script:mutexes[$name] = New-TestMutex $name }
        Mock New-Object {
            param($TypeName, $ArgumentList)
            if ($ArgumentList[1] -eq ($ServiceMutexName + '.Ready')) { throw 'ready construction denied' }
            $script:mutexes[$ArgumentList[1]]
        } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        try { Start-Watcher } catch { $_.Exception.Message | Should Match 'ready construction denied' }
        $script:queueReads | Should Be 0
        foreach ($m in $script:mutexes.Values) { $m.Releases | Should Be 1; $m.Disposals | Should Be 1 }
    }
    It 'releases and disposes all owned locks on each launcher restart' {
        for ($attempt = 0; $attempt -lt 2; $attempt++) {
            foreach ($name in @($ServiceMutexName, ($ServiceMutexName + '.Ready')) + $LegacyMutexNames) { $script:mutexes[$name] = New-TestMutex $name }
            Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
            try { Start-Watcher } catch { $_.Exception.Message | Should Match 'end test watcher' }
            foreach ($m in $script:mutexes.Values) {
                if ($m.Name -eq ($ServiceMutexName + '.Ready')) { $m.Waits | Should Be 0 } else { $m.Waits | Should Be 1 }
                $m.Releases | Should Be 1; $m.Disposals | Should Be 1
            }
        }
        $script:queueReads | Should Be 2
    }
    It 'does not continue after failing to acquire the primary mutex' {
        $script:mutexes[$ServiceMutexName] = New-TestMutex $ServiceMutexName $false
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        Start-Watcher
        $script:queueReads | Should Be 0
        $script:mutexes[$ServiceMutexName].Disposals | Should Be 1
    }
    It 'fails closed on unexpected primary mutex errors' {
        $script:mutexes[$ServiceMutexName] = New-TestMutex $ServiceMutexName $true 'denied'
        Mock New-Object { param($TypeName, $ArgumentList); $m = $script:mutexes[$ArgumentList[1]]; if ($ArgumentList.Count -eq 3) { $ArgumentList[2].Value = $m.Available }; $m } -ParameterFilter { $TypeName -eq 'Threading.Mutex' }
        try { Start-Watcher } catch { }
        $script:queueReads | Should Be 0
        $script:mutexes[$ServiceMutexName].Disposals | Should Be 1
    }
}

Describe 'Watcher bootstrap before the top-level watch entry point' {
    It 'can find the legacy-process helper using only definitions available at watcher startup' {
        $entry = $appAst.EndBlock.Statements | Where-Object {
            $_ -is [Management.Automation.Language.IfStatementAst] -and $_.Clauses[0].Item1.Extent.Text -eq '$Watch'
        } | Select-Object -First 1
        $definitions = ($appAst.EndBlock.Statements | Where-Object {
            $_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Extent.StartOffset -lt $entry.Extent.StartOffset
        } | ForEach-Object { $_.Extent.Text }) -join "`n"
        $shell = [powershell]::Create()
        try {
            [void]$shell.AddScript($definitions)
            [void]$shell.AddScript({
                param($fixtureRoot)
                $Root = $fixtureRoot; $ServiceMutexName = 'bootstrap-primary'; $LegacyMutexNames = @('bootstrap-old')
                $script:legacyQueries = 0; $script:queueReads = 0
                function Write-Log($m) {}
                function Get-CimInstance { $script:legacyQueries++; @() }
                function Get-Config { $script:queueReads++; @() }
                function Start-Sleep { throw 'end bootstrap test' }
                function New-Object($TypeName, $ArgumentList) {
                    $m = [DualPrintTestMutex]::new(); $m.Name = $ArgumentList[1]
                    $m.Available = ($m.Name -eq 'bootstrap-primary'); return $m
                }
                $message = ''
                try { Start-Watcher } catch { $message = $_.Exception.Message }
                [pscustomobject]@{ Message = $message; LegacyQueries = $script:legacyQueries; QueueReads = $script:queueReads }
            }.ToString()).AddArgument($TestDrive)
            $result = @($shell.Invoke())[-1]
            $result.Message | Should Be 'end bootstrap test'
            $result.LegacyQueries | Should Be 1
            $result.QueueReads | Should Be 0
        } finally { $shell.Dispose() }
    }
}

Describe 'Runtime version footer' {
    It 'reads the built executable version independently of the selected language' {
        $AppExe = Join-Path (Split-Path $PSScriptRoot -Parent) 'build/DualPrint.exe'
        foreach ($Lang in @('ar','en','es','fr','de')) { Get-AppVersionText | Should Be 'DualPrint 3.0.0' }
    }
    It 'uses the bare product name when running a script' {
        $AppExe = 'D:\source\DualPrint.ps1'
        Get-AppVersionText | Should Be 'DualPrint'
    }
}
