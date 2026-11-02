# DualPrint - a virtual printer that prints to several printers at the same time
param([switch]$Watch)

trap {
    $msg = "$($_.Exception.Message)`n`n$($_.InvocationInfo.PositionMessage)"
    try {
        New-Item -ItemType Directory -Force -Path 'C:\DualPrint' | Out-Null
        Add-Content -Path 'C:\DualPrint\error.txt' -Value ("{0:yyyy-MM-dd HH:mm:ss}`n{1}`n" -f (Get-Date), $msg) -Encoding UTF8
    } catch {}
    if (-not $Watch) {
        try { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show($msg, 'DualPrint') } catch {}
    }
    $global:MPErrorShown = $true
    break
}

$ErrorActionPreference = 'Stop'
$Root         = 'C:\DualPrint'
$RootExe      = Join-Path $Root 'DualPrint.exe'
if (-not $AppExe) { $AppExe = $RootExe }
$AppDir = Split-Path $AppExe -Parent
$ConfigPath   = Join-Path $Root 'printers.json'
$SettingsPath = Join-Path $Root 'settings.json'
$Sumatra      = Join-Path $Root 'SumatraPDF.exe'
$LogPath      = Join-Path $Root 'log.txt'
$HistoryPath  = Join-Path $Root 'history.jsonl'
$DefaultPdf   = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'DualPrint PDFs'
$TaskName     = 'DualPrint Service'
$ServiceMutexName = 'Local\DualPrintService'
$Driver       = 'Microsoft Print To PDF'
$PdfTarget    = 'Microsoft Print to PDF'
$SumatraUrls  = @('https://www.sumatrapdfreader.org/dl/rel/3.6.1/SumatraPDF-3.6.1-64.zip',
                  'https://www.sumatrapdfreader.org/dl/rel/3.6/SumatraPDF-3.6-64.zip')

# Legacy (v2.x MultiPrint and 1.x DualPrint) — kept for upgrade compatibility, see ADR 0002.
# The new names above must never equal any of these (spec rule R1, ADR 0001).
$LegacyDefaultPdf = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'MultiPrint PDFs'
$LegacyTaskNames  = @('MultiPrint Watcher', 'DualPrint Watcher')
$LegacyMutexNames = @('Local\MultiPrintWatcher', 'Local\DualPrintWatcher')
$LegacyExe        = Join-Path $Root 'MultiPrint.exe'
$OldTaskName      = 'DualPrint Watcher'   # Legacy 1.x task; still read by Stop-Watchers and Update-WatcherIfNeeded

# ================================================================ General helpers
function Write-Log([string]$m) {
    try { Add-Content -Path $LogPath -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $m) -Encoding UTF8 } catch {}
}

# Any error in a UI button or event is logged and shown as a message, without closing the app
function Report-UiError($err) {
    try { Write-Log "UI error: $($err.Exception.Message) @ $($err.InvocationInfo.ScriptLineNumber)" } catch {}
    try { if (Get-Command Show-Toast -ErrorAction SilentlyContinue) { Show-Toast (T 'error' $err.Exception.Message) $false } } catch {}
}

function Get-Config {
    $script:ConfigError = $null
    if (Test-Path $ConfigPath) {
        try { $raw = Get-Content $ConfigPath -Raw -Encoding UTF8 -ErrorAction Stop }
        catch {
            $script:ConfigError = $_.Exception.Message
            if ($script:LastConfigError -ne $script:ConfigError) { Write-Log "Config read failed: $($script:ConfigError)" }
            $script:LastConfigError = $script:ConfigError
            return @()
        }
        if ($raw -and $raw.Trim()) {
            $items = @(@($raw | ConvertFrom-Json) | ForEach-Object { $_ } | Where-Object { $_ -and $_.Name })
            foreach ($c in $items) { $c.Targets = [string[]](Get-Targets $c) }
            return $items
        }
    }
    return @()
}

# Returns printer names as clean strings (skips empty ones and unwraps the {value, Count} shape that PowerShell 5 sometimes saves)
function Get-Targets($cfg) {
    $t = $cfg.Targets
    if ($null -eq $t) { return @() }
    if ($t -isnot [string] -and $t.PSObject.Properties['value']) { $t = $t.value }
    return @(@($t) | Where-Object { $_ -and "$_".Trim() } | ForEach-Object { [string]$_ })
}

function Save-Config($items) {
    # If the printers file could not be read, do not overwrite it (so existing printers are not lost)
    if ($script:ConfigError) { throw (T 'err_config') }
    ConvertTo-Json -InputObject @($items) -Depth 5 | Set-Content -Path $ConfigPath -Encoding UTF8
}

# ================================================================ Watcher (runs in the background)
function Test-FileReady([string]$p) {
    try {
        $s = [IO.File]::Open($p, 'Open', 'ReadWrite', 'None')
        $len = $s.Length; $s.Close()
        return ($len -gt 0)
    } catch { return $false }
}

function Add-History([string]$printer, [string]$doc, $results) {
    try {
        $o = [pscustomobject]@{ Time = (Get-Date).ToString('o'); Printer = $printer; Doc = $doc; Results = @($results) }
        Add-Content -Path $HistoryPath -Value ($o | ConvertTo-Json -Compress -Depth 5) -Encoding UTF8
    } catch {}
}

function Send-ToTarget($cfg, [string]$file, [string]$target) {
    if ($target -eq $PdfTarget) {
        $dir = if ($cfg.PdfFolder) { $cfg.PdfFolder } else { $DefaultPdf }
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $base = if ($cfg.PdfPrefix) { $cfg.PdfPrefix } else { $cfg.Name }
        $safe = ($base -replace '[\\/:*?"<>|]', '_')
        $dest = Join-Path $dir ("{0}_{1:yyyy-MM-dd_HH-mm-ss}.pdf" -f $safe, (Get-Date))
        $i = 1
        while (Test-Path $dest) { $dest = Join-Path $dir ("{0}_{1:yyyy-MM-dd_HH-mm-ss}_{2}.pdf" -f $safe, (Get-Date), $i); $i++ }
        Copy-Item $file $dest -Force
        Write-Log "PDF saved: $dest"
        return [pscustomobject]@{ Target = $target; Ok = $true; Msg = $dest }
    }
    if ($target -match '"') { throw "Invalid printer name" }
    $a = @('-print-to', "`"$target`"")
    if ($cfg.PaperSize -and $cfg.PaperSize -ne 'auto') { $a += @('-print-settings', "paper=$($cfg.PaperSize)") }
    $a += @('-silent', '-exit-when-done', "`"$file`"")
    $p = Start-Process -FilePath $Sumatra -ArgumentList $a -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit(120000)) {
        try { $p.Kill() } catch {}
        Write-Log "Printing to [$target] timed out after 2 minutes"
        return [pscustomobject]@{ Target = $target; Ok = $false; Msg = 'timeout' }
    }
    Write-Log "Printed to [$target] exit=$($p.ExitCode)"
    return [pscustomobject]@{ Target = $target; Ok = ($p.ExitCode -eq 0); Msg = "exit $($p.ExitCode)" }
}

function Get-JobDocName([string]$printer) {
    try {
        $j = Get-PrintJob -PrinterName $printer -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($j -and $j.DocumentName) {
            return ($j.DocumentName -replace '^Microsoft (Word|Excel|PowerPoint|Office \w+) - ', '')
        }
    } catch {}
    return $null
}

function Start-Watcher {
    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    $mutex = New-Object Threading.Mutex($false, $ServiceMutexName)
    $got = $false
    try { $got = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $got = $true }   # Previous instance was killed - the lock is now ours
    catch { $got = $true }
    if (-not $got) { $global:WatcherAlreadyRunning = $true; return }
    # Also take the legacy (DualPrint) lock so that if an old version is opened, its service does not run alongside this one
    $oldMutex = New-Object Threading.Mutex($false, 'Local\DualPrintWatcher')
    try { [void]$oldMutex.WaitOne(0) } catch {}
    Write-Log "Watcher started (pid $PID)"
    $lastClean = Get-Date
    $lastBeat = [datetime]::MinValue
    $docNames = @{}
    try {
    while ($true) {
        if (((Get-Date) - $lastBeat).TotalMinutes -ge 1) {
            try { [IO.File]::WriteAllText((Join-Path $Root 'heartbeat.txt'), (Get-Date).ToString('o')) } catch {}
            $lastBeat = Get-Date
        }
        try {
            foreach ($cfg in Get-Config) {
                $in = Join-Path $cfg.Folder 'incoming.pdf'
                if (-not (Test-Path $in)) { continue }
                if (-not $docNames[$cfg.Name]) { $n = Get-JobDocName $cfg.Name; if ($n) { $docNames[$cfg.Name] = $n } }
                if (-not (Test-FileReady $in)) { continue }
                $size1 = (Get-Item $in).Length
                Start-Sleep -Milliseconds 400
                if (-not (Test-FileReady $in) -or (Get-Item $in).Length -ne $size1) { continue }

                $jobsDir = Join-Path $cfg.Folder 'jobs'
                New-Item -ItemType Directory -Force -Path $jobsDir | Out-Null
                $job = Join-Path $jobsDir ("job_{0:yyyyMMdd_HHmmss_fff}.pdf" -f (Get-Date))
                try { Move-Item $in $job -Force } catch { continue }
                $doc = $docNames[$cfg.Name]; $docNames.Remove($cfg.Name)
                Write-Log "New job on [$($cfg.Name)] doc=[$doc]"
                $results = @()
                $allT = @(Get-Targets $cfg)
                foreach ($t in $allT) {
                    if ($t -eq $PdfTarget -and $cfg.PdfEnabled -eq $false -and $allT.Count -gt 1) { continue }
                    try { $results += Send-ToTarget $cfg $job $t }
                    catch { Write-Log "ERROR [$t]: $_"; $results += [pscustomobject]@{ Target = $t; Ok = $false; Msg = "$_" } }
                }
                Add-History $cfg.Name $doc $results
            }
            if (((Get-Date) - $lastClean).TotalHours -ge 6) {
                foreach ($cfg in Get-Config) {
                    $jd = Join-Path $cfg.Folder 'jobs'
                    if (Test-Path $jd) {
                        Get-ChildItem $jd -Filter *.pdf | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
                            Remove-Item -Force -ErrorAction SilentlyContinue
                    }
                }
                if (Test-Path $HistoryPath) {
                    $lines = @(Get-Content $HistoryPath -Encoding UTF8)
                    if ($lines.Count -gt 3000) { $lines[-1500..-1] | Set-Content $HistoryPath -Encoding UTF8 }
                }
                $lastClean = Get-Date
            }
        } catch { Write-Log "Watcher error: $_" }
        Start-Sleep -Milliseconds 700
    }
    } finally {
        Write-Log "Watcher stopped (pid $PID)"
        try { $mutex.ReleaseMutex() } catch {}
    }
}

if ($Watch) {
    try { Start-Watcher } catch { Write-Log "Watcher fatal: $_" }
    return
}

# ================================================================ Setup
New-Item -ItemType Directory -Force -Path $Root, (Join-Path $Root 'queues') | Out-Null

# Permissions for C:\DualPrint:
#   The folder itself: SYSTEM and Administrators full control, current user modify, other users read-only
#   Files and subfolders inside it: inherit these same permissions (reset) — without applying folder permissions to a file
$AclLog = Join-Path $env:TEMP 'DualPrint-acl.txt'
function Invoke-Logged([string]$exe, [string[]]$argList) {
    $out = & $exe @argList 2>&1
    try { Add-Content -Path $AclLog -Value ("> {0} {1}  (exit {2})`r`n{3}" -f $exe, ($argList -join ' '), $LASTEXITCODE, ($out -join "`r`n")) } catch {}
}

# Each level separately: give file ownership back to Administrators (takeown), then make them inherit the folder permissions (reset)
function Repair-Tree([string]$dir) {
    Invoke-Logged 'takeown.exe' @('/F', "$dir\*", '/A')
    Invoke-Logged 'icacls.exe' @("$dir\*", '/reset', '/C', '/Q')
    foreach ($d in @(Get-ChildItem -LiteralPath $dir -Directory -Force -ErrorAction SilentlyContinue)) { Repair-Tree $d.FullName }
}

function Protect-RootFolder {
    try {
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        Invoke-Logged 'takeown.exe' @('/F', $Root, '/A')
        Invoke-Logged 'icacls.exe' @($Root, '/inheritance:r', '/grant:r', '*S-1-5-18:(OI)(CI)F', '*S-1-5-32-544:(OI)(CI)F', "*$($sid):(OI)(CI)M", '*S-1-5-32-545:(OI)(CI)RX', '/C', '/Q')
        Repair-Tree $Root
        $null = & attrib.exe -R -H -S "$Root\*" /S /D 2>&1
        Write-Log "Folder permissions applied"
    } catch { Write-Log "Folder permissions: $_" }
}

# Checks that the app can read and write a file (not just read it)
function Test-Writable([string]$path) {
    try { $fs = [IO.File]::Open($path, 'Open', 'ReadWrite', 'ReadWrite'); $fs.Close(); return $true } catch { return $false }
}

# Files inside C:\DualPrint that are not writable (caused by version 2.2.0)
function Get-LockedFiles {
    $bad = @()
    try {
        foreach ($f in @(Get-ChildItem -LiteralPath $Root -Force -Recurse -File -ErrorAction SilentlyContinue)) {
            if ($f.Extension -in '.json', '.jsonl', '.txt' -and -not (Test-Writable $f.FullName)) { $bad += $f.FullName }
        }
        $probe = Join-Path $Root ('.probe_' + [Guid]::NewGuid().ToString('N'))
        try { [IO.File]::WriteAllText($probe, 'ok'); Remove-Item -LiteralPath $probe -Force } catch { $bad += $Root }
    } catch { $bad += $Root }
    return $bad
}

$locked = @(Get-LockedFiles)
if ($locked.Count) {
    foreach ($b in $locked | Select-Object -First 3) {
        try { Add-Content -Path $AclLog -Value ("{0:u} {1}`n{2}" -f (Get-Date), $b, ((& icacls.exe $b 2>&1) -join "`n")) } catch {}
    }
    Protect-RootFolder
    $null = & attrib.exe -R -H -S "$Root\*" /S /D 2>&1   # A hidden or read-only file rejects writes
    # If a file is still locked after the repair: files that can be recreated are deleted; the rest are moved aside and a fresh copy is used
    foreach ($f in @(Get-LockedFiles)) {
        if ($f -eq $Root) { continue }
        try {
            if ((Split-Path $f -Leaf) -in 'settings.json', 'log.txt', 'error.txt', 'SumatraPDF-settings.txt') { Remove-Item -LiteralPath $f -Force -ErrorAction Stop }
            else {
                $copy = Get-Content -LiteralPath $f -Raw -ErrorAction Stop
                Move-Item -LiteralPath $f -Destination ($f + '.locked-' + (Get-Date -Format 'yyyyMMddHHmmss')) -Force -ErrorAction Stop
                [IO.File]::WriteAllText($f, $copy, (New-Object Text.UTF8Encoding($false)))
            }
        } catch {}
    }
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ================================================================ Languages
$AllStrings = @'
__STRINGS_JSON__
'@ | ConvertFrom-Json

function Get-Lang {
    if (Test-Path $SettingsPath) {
        try { $s = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json; if ($s.Lang) { return $s.Lang } } catch {}
    }
    return $null
}
function Set-Lang([string]$code) {
    # If saving fails for any reason, the app continues in the chosen language instead of closing
    try { ConvertTo-Json -InputObject ([pscustomobject]@{ Lang = $code }) | Set-Content -Path $SettingsPath -Encoding UTF8 -ErrorAction Stop }
    catch { Write-Log "Could not save language: $_" }
}

function Show-LanguagePicker {
    [xml]$px = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DualPrint" Width="380" SizeToContent="Height" WindowStartupLocation="CenterScreen"
        Background="#F1F5F9" FontFamily="Segoe UI" FontSize="15" ResizeMode="NoResize">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Background" Value="White"/>
      <Setter Property="Foreground" Value="#0F172A"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,10"/>
      <Setter Property="Padding" Value="16,13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="12"
                    BorderBrush="#E2E8F0" BorderThickness="1" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="#EEF2FF"/>
                <Setter TargetName="b" Property="BorderBrush" Value="#6366F1"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <StackPanel Margin="24">
    <Border CornerRadius="14" Padding="18,14" Margin="0,0,0,18">
      <Border.Background>
        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
          <GradientStop Color="#6366F1" Offset="0"/>
          <GradientStop Color="#8B5CF6" Offset="1"/>
        </LinearGradientBrush>
      </Border.Background>
      <StackPanel>
        <TextBlock Text="🌐  Choose your language" FontSize="18" FontWeight="Bold" Foreground="White"/>
        <TextBlock Text="اختر اللغة · Elige tu idioma · Choisissez · Sprache wählen" Foreground="#E0E7FF"
                   FontSize="12" Margin="0,4,0,0" TextWrapping="Wrap"/>
      </StackPanel>
    </Border>
    <StackPanel x:Name="LangButtons"/>
  </StackPanel>
</Window>
'@
    $pw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $px))
    $panel = $pw.FindName('LangButtons')
    $script:PickedLang = $null
    foreach ($pair in @(@('ar','العربية'), @('en','English'), @('es','Español'), @('fr','Français'), @('de','Deutsch'))) {
        $b = New-Object Windows.Controls.Button
        $b.Content = $pair[1]; $b.Tag = $pair[0]
        $b.Add_Click({ try { $script:PickedLang = [string]$this.Tag; [Windows.Window]::GetWindow($this).Close()  } catch { Report-UiError $_ } })
        [void]$panel.Children.Add($b)
    }
    [void]$pw.ShowDialog()
    return $script:PickedLang
}

$Lang = Get-Lang
if (-not $Lang) {
    $Lang = Show-LanguagePicker
    if (-not $Lang) { return }
    Set-Lang $Lang
}
$Strings = $AllStrings.$Lang
if (-not $Strings) { $Lang = 'en'; $Strings = $AllStrings.en }

function T([string]$k) {
    $s = $Strings.$k
    if (-not $s) { $s = $AllStrings.en.$k }
    if (-not $s) { $s = $k }
    if ($args.Count) { return ($s -f $args) }
    return $s
}

# ================================================================ Printer functions
# ================================================================ Printer functions
# The signature must be valid or absent; any tampered file (HashMismatch, etc.) is rejected
function Test-SumatraFile([string]$path) {
    if (-not (Test-Path $path)) { return $false }
    try {
        $sig = Get-AuthenticodeSignature -FilePath $path
        if ($sig.Status -ne 'Valid' -and $sig.Status -ne 'NotSigned') { Write-Log "SumatraPDF rejected ($($sig.Status)): $path"; return $false }
        $ver = (Get-Item $path).VersionInfo.FileVersion
        if ($ver -match '^3\.5\.') { Write-Log "SumatraPDF $ver is outdated (CVE-2026-25961), replacing"; return $false }
    } catch { return $false }
    return $true
}

# Stops SumatraPDF from checking for updates (update vulnerability in older versions)
function Set-SumatraSettings {
    $cfg = Join-Path $Root 'SumatraPDF-settings.txt'
    try {
        if (Test-Path $cfg) {
            $t = Get-Content $cfg -Raw
            if ($t -match 'CheckForUpdates\s*=\s*false') { return }
            $t = $t -replace 'CheckForUpdates\s*=\s*\w+', 'CheckForUpdates = false'
            if ($t -notmatch 'CheckForUpdates') { $t = "CheckForUpdates = false`r`n" + $t }
            Set-Content -Path $cfg -Value $t -Encoding UTF8
        } else {
            Set-Content -Path $cfg -Value "CheckForUpdates = false" -Encoding UTF8
        }
    } catch { Write-Log "SumatraPDF settings: $_" }
}

function Find-Sumatra {
    if (Test-SumatraFile $Sumatra) { Set-SumatraSettings; return $true }
    # Only admin-protected locations (not next to the app and not in user folders)
    $candidates = @("$env:ProgramFiles\SumatraPDF\SumatraPDF.exe", "${env:ProgramFiles(x86)}\SumatraPDF\SumatraPDF.exe")
    foreach ($c in $candidates) {
        if ($c -and (Test-SumatraFile $c)) { Copy-Item $c $Sumatra -Force; Set-SumatraSettings; return $true }
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    foreach ($url in $SumatraUrls) {
        $tmp = Join-Path ([IO.Path]::GetTempPath()) ("dp_" + [Guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $tmp | Out-Null
            $zip = Join-Path $tmp 'sumatra.zip'
            Invoke-WebRequest $url -OutFile $zip -UseBasicParsing
            Expand-Archive $zip -DestinationPath (Join-Path $tmp 'x') -Force
            $exe = Get-ChildItem (Join-Path $tmp 'x') -Filter 'SumatraPDF*.exe' -Recurse | Select-Object -First 1
            if ($exe -and (Test-SumatraFile $exe.FullName)) {
                Copy-Item $exe.FullName $Sumatra -Force
                Set-SumatraSettings
                Write-Log "SumatraPDF installed from $url"
                return $true
            }
        } catch { Write-Log "SumatraPDF download failed ($url): $_" }
        finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
    return $false
}

function Test-InQueues([string]$path) {
    if (-not $path) { return $false }
    try {
        $q = [IO.Path]::GetFullPath((Join-Path $Root 'queues')).TrimEnd('\') + '\'
        $full = [IO.Path]::GetFullPath($path)
        return $full.StartsWith($q, [StringComparison]::OrdinalIgnoreCase) -and $full.Length -gt $q.Length
    } catch { return $false }
}

# Printer names: characters that could break commands or paths are not allowed
function Test-PrinterName([string]$n) {
    return ($n -and $n.Length -le 200 -and $n -notmatch '[\\,"<>|*?:/]' -and $n.Trim() -eq $n)
}

function Stop-Watchers {
    foreach ($t in @($TaskName, $OldTaskName)) {
        try { Stop-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue } catch {}
    }
    try { Unregister-ScheduledTask -TaskName $OldTaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    # Legacy (v2.x MultiPrint) — kept for upgrade compatibility: stops an old MultiPrint.exe --watch
    Get-CimInstance Win32_Process -Filter "Name='MultiPrint.exe' OR Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessId -ne $PID -and (
            ($_.Name -eq 'MultiPrint.exe' -and $_.CommandLine -match '\s--watch\b') -or
            ($_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'DualPrint\\DualPrint\.ps1' -and $_.CommandLine -match '-Watch')) } |
        ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }
    Start-Sleep -Milliseconds 700
}

function Register-Watcher {
    Stop-Watchers
    Protect-RootFolder
    if ($AppExe -ne $RootExe) { Copy-Item $AppExe $RootExe -Force }
    $user = "$env:USERDOMAIN\$env:USERNAME"
    $action    = New-ScheduledTaskAction -Execute $RootExe -Argument '--watch'
    # Runs at Windows startup + checks every minute that it is running (restarts on its own if it crashes)
    $trigger1  = New-ScheduledTaskTrigger -AtLogOn -User $user
    $trigger   = @($trigger1)
    try {
        $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
        try { $trigger2.Repetition.Duration = '' } catch {}
        $trigger = @($trigger1, $trigger2)
    } catch { Write-Log "Repeat trigger not supported: $_" }
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
                 -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew `
                 -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings `
        -Principal $principal -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName
}

function New-MultiPrinter([string]$name, [string[]]$targets, [string]$pdfFolder, [string]$pdfPrefix, [string]$paper = 'auto') {
    if (-not (Test-PrinterName $name)) { throw (T 'err_badname') }
    if (@($targets | Where-Object { $_ -match '"' }).Count) { throw (T 'err_badname') }
    if (Get-Printer -Name $name -ErrorAction SilentlyContinue) { throw (T 'err_exists') }
    if (-not (Get-PrinterDriver -Name $Driver -ErrorAction SilentlyContinue)) { throw (T 'err_driver' $Driver) }
    $folder = Join-Path $Root ("queues\q_" + (Get-Date).Ticks)
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $port = Join-Path $folder 'incoming.pdf'
    try { Add-PrinterPort -Name $port }
    catch { Restart-Service Spooler -Force; Start-Sleep 2; Add-PrinterPort -Name $port }
    Add-Printer -Name $name -DriverName $Driver -PortName $port

    $item = [pscustomobject]@{ Name = $name; Folder = $folder; Port = $port; Targets = [string[]]$targets; PdfFolder = $pdfFolder; PdfPrefix = $pdfPrefix; PaperSize = $paper; PdfEnabled = $true }
    Save-Config (@(Get-Config) + $item)
}

function Remove-MultiPrinter([string]$name) {
    $all  = @(Get-Config)
    $item = $all | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (Get-Printer -Name $name -ErrorAction SilentlyContinue) { Remove-Printer -Name $name }
    if ($item) {
        Start-Sleep -Milliseconds 500
        if (Test-InQueues $item.Port) { try { Remove-PrinterPort -Name $item.Port } catch {} }
        if (Test-InQueues $item.Folder) { try { Remove-Item -LiteralPath $item.Folder -Recurse -Force } catch {} }
        else { Write-Log "Refused to delete folder outside queues: $($item.Folder)" }
    }
    Save-Config @($all | Where-Object { $_.Name -ne $name })
}

function Uninstall-All {
    foreach ($c in @(Get-Config)) { Remove-MultiPrinter $c.Name }
    Stop-Watchers
    try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
}

function Update-Cfg([string]$name, [hashtable]$values) {
    $all = @(Get-Config)
    foreach ($c in $all) {
        if ($c.Name -eq $name) {
            foreach ($k in $values.Keys) { $c | Add-Member -NotePropertyName $k -NotePropertyValue $values[$k] -Force }
        }
    }
    Save-Config $all
}

function Get-History([int]$count) {
    if (-not (Test-Path $HistoryPath)) { return @() }
    $items = @(Get-Content $HistoryPath -Tail $count -Encoding UTF8 | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } | Where-Object { $_ })
    [array]::Reverse($items)
    return $items
}

# A single query for all printers: connection status + default printer
function Get-PrinterSnapshot {
    $h = @{}; $def = $null
    foreach ($p in @(Get-CimInstance Win32_Printer -Property Name, WorkOffline, PrinterStatus, DetectedErrorState, Default -ErrorAction SilentlyContinue)) {
        if (-not $p.Name) { continue }
        $h[$p.Name] = -not ($p.WorkOffline -or $p.PrinterStatus -eq 7 -or $p.DetectedErrorState -eq 9)
        if ($p.Default) { $def = [string]$p.Name }
    }
    return @{ States = $h; Default = $def }
}

function Get-PrinterStates { return (Get-PrinterSnapshot).States }

# Instant check: the service holds a lock with a fixed name, so if the lock exists the service is running (instead of searching all processes)
function Test-ServiceRunning {
    $m = $null
    try {
        if ([Threading.Mutex]::TryOpenExisting($ServiceMutexName, [ref]$m)) { $m.Dispose(); return $true }
    } catch [UnauthorizedAccessException] { return $true } catch {}
    return $false
}

function Get-DefaultPrinterName {
    try {
        $d = Get-CimInstance Win32_Printer -Filter 'Default=TRUE' -ErrorAction Stop | Select-Object -First 1
        if ($d) { return [string]$d.Name }
    } catch {}
    return $null
}

function Set-DefaultMultiPrinter([string]$name) {
    # Turn off "Let Windows manage my default printer" so Windows does not change it on its own
    try {
        $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows'
        Set-ItemProperty -Path $k -Name 'LegacyDefaultPrinterMode' -Value 1 -Type DWord -ErrorAction Stop
    } catch { Write-Log "LegacyDefaultPrinterMode: $_" }
    $p = Get-CimInstance Win32_Printer -ErrorAction Stop | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $p) { throw (T 'err_notfound') }
    $r = Invoke-CimMethod -InputObject $p -MethodName SetDefaultPrinter
    if ($r.ReturnValue -ne 0) {
        # Fallback method
        $net = New-Object -ComObject WScript.Network
        $net.SetDefaultPrinter($name)
    }
    Write-Log "Default printer set: $name"
}


# ================================================================ UI (WPF)
$IF = 'Segoe Fluent Icons, Segoe MDL2 Assets'
$PaperSizes = @('auto', 'A4', 'A3', 'A5', 'letter', 'legal')
$CultureMap = @{ ar = 'ar-EG'; en = 'en-US'; es = 'es-ES'; fr = 'fr-FR'; de = 'de-DE' }
$Culture = [Globalization.CultureInfo]::GetCultureInfo($CultureMap[$Lang])
$LangNames = @{ ar = 'العربية'; en = 'English'; es = 'Español'; fr = 'Français'; de = 'Deutsch' }
$Purple = '#5B45E6'

function X([string]$s) {
    $r = [Security.SecurityElement]::Escape([string]$s)
    if ($r.StartsWith('{')) { $r = '{}' + $r }   # Prevents the text from being parsed as a Markup Extension
    return $r
}
# Finds an element by name inside any part built from XAML (more reliable than FindName)
function FN($root, [string]$name) {
    $n = [Windows.LogicalTreeHelper]::FindLogicalNode($root, $name)
    if (-not $n) { $n = $root.FindName($name) }
    if (-not $n) { throw "Element '$name' not found" }
    return $n
}

function New-El([string]$x) {
    $x = $x.Trim() -replace '^<([\w\.]+)', '<$1 xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'
    return [Windows.Markup.XamlReader]::Parse($x)
}

$xamlText = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DualPrint" Width="1080" Height="720" MinWidth="940" MinHeight="600"
        WindowStartupLocation="CenterScreen" FlowDirection="{{dir}}" Background="#F6F7FB"
        FontFamily="Segoe UI" FontSize="13" Foreground="#0F172A">
  <Window.Resources>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#5B45E6"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Padding" Value="20,11"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="1.2" CornerRadius="10" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.45"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Outline" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="White"/>
      <Setter Property="Foreground" Value="#4F3BD6"/>
      <Setter Property="BorderBrush" Value="#C9C2F7"/>
    </Style>
    <Style x:Key="Soft" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#F4F5F8"/>
      <Setter Property="Foreground" Value="#334155"/>
      <Setter Property="BorderBrush" Value="#E5E7EB"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="Normal"/>
      <Setter Property="Padding" Value="12,6"/>
    </Style>
    <Style x:Key="DangerSoft" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#FEF2F2"/>
      <Setter Property="Foreground" Value="#DC2626"/>
      <Setter Property="BorderBrush" Value="#FECACA"/>
    </Style>
    <Style x:Key="Link" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#4F3BD6"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Padding" Value="6,4"/>
    </Style>
    <Style x:Key="IconBtn" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#64748B"/>
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontWeight" Value="Normal"/>
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="Padding" Value="6"/>
    </Style>
    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="White"/>
      <Setter Property="BorderBrush" Value="#ECEDF3"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="16"/>
      <Setter Property="Padding" Value="22"/>
    </Style>
    <Style x:Key="Nav" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#334155"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,0,0,6"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="b" Background="Transparent" CornerRadius="10" Padding="14,11">
              <StackPanel Orientation="Horizontal">
                <TextBlock x:Name="ic" Text="{TemplateBinding Tag}" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets"
                           FontSize="17" VerticalAlignment="Center" Margin="0,0,12,0"/>
                <ContentPresenter VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#F5F4FE"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="Background" Value="#EEEBFE"/>
                <Setter Property="Foreground" Value="#4F3BD6"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Switch" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="track" Width="44" Height="24" CornerRadius="12" Background="#CBD5E1">
              <Ellipse x:Name="knob" Width="18" Height="18" Fill="White" HorizontalAlignment="Left" Margin="3,0"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="track" Property="Background" Value="#5B45E6"/>
                <Setter TargetName="knob" Property="HorizontalAlignment" Value="Right"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Sel" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Width" Value="238"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="b" Background="#FAFAFC" BorderBrush="#E5E7EB" BorderThickness="1.5" CornerRadius="12"
                    Padding="12,10" Margin="0,0,8,8">
              <Grid>
                <ContentPresenter VerticalAlignment="Center"/>
                <Border x:Name="tick" Visibility="Collapsed" Width="18" Height="18" CornerRadius="9" Background="#5B45E6"
                        HorizontalAlignment="Right" VerticalAlignment="Center">
                  <TextBlock Text="&#xE73E;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" FontSize="10"
                             Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="BorderBrush" Value="#B9B0F5"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="BorderBrush" Value="#5B45E6"/>
                <Setter TargetName="b" Property="Background" Value="#F3F0FF"/>
                <Setter TargetName="tick" Property="Visibility" Value="Visible"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Padding" Value="10,8"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="bd" Background="White" BorderBrush="#D9DCE3" BorderThickness="1" CornerRadius="9">
              <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsKeyboardFocused" Value="True">
                <Setter TargetName="bd" Property="BorderBrush" Value="#5B45E6"/>
                <Setter TargetName="bd" Property="BorderThickness" Value="2"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Lbl" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#475569"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,7"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="220"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <!-- ===== Sidebar ===== -->
    <Border Grid.Column="0" Background="White" BorderBrush="#ECEDF3" BorderThickness="0,0,1,0">
      <DockPanel Margin="14,26,14,18">
        <Border x:Name="SvcBox" DockPanel.Dock="Bottom" CornerRadius="10" Padding="12,10" Cursor="Hand">
          <StackPanel Orientation="Horizontal">
            <Ellipse x:Name="SvcDot" Width="9" Height="9" VerticalAlignment="Center" Margin="0,0,9,0"/>
            <TextBlock x:Name="SvcText" FontWeight="SemiBold"/>
          </StackPanel>
        </Border>
        <StackPanel DockPanel.Dock="Top">
          <StackPanel HorizontalAlignment="Center" Margin="0,0,0,30">
            <TextBlock Text="&#xE749;" FontFamily="{{icons}}" FontSize="36" Foreground="#5B45E6" HorizontalAlignment="Center"/>
            <TextBlock Text="DualPrint" FontSize="22" FontWeight="Bold" Margin="0,6,0,0" HorizontalAlignment="Center"/>
          </StackPanel>
          <RadioButton x:Name="NavPrinters" Style="{StaticResource Nav}" IsChecked="True"
                       Tag="&#xE749;" Content="{{nav_printers}}"/>
          <RadioButton x:Name="NavHistory" Style="{StaticResource Nav}"
                       Tag="&#xE81C;" Content="{{nav_history}}"/>
          <RadioButton x:Name="NavSettings" Style="{StaticResource Nav}"
                       Tag="&#xE713;" Content="{{nav_settings}}"/>
        </StackPanel>
        <Grid/>
      </DockPanel>
    </Border>

    <!-- ===== Printers page ===== -->
    <ScrollViewer x:Name="PagePrinters" Grid.Column="1" VerticalScrollBarVisibility="Hidden">
      <StackPanel Margin="28,24,28,20">
        <Grid Margin="0,0,0,20">
          <StackPanel Orientation="Horizontal">
            <Border Width="48" Height="48" CornerRadius="12" Background="#EEEBFE">
              <TextBlock Text="&#xE749;" FontFamily="{{icons}}" FontSize="22" Foreground="#5B45E6"
                         HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
              <TextBlock Text="{{page_title}}" FontSize="24" FontWeight="Bold"/>
              <TextBlock Text="{{page_sub}}" Foreground="#64748B" Margin="0,3,0,0"/>
            </StackPanel>
          </StackPanel>
          <Button x:Name="BtnAdd" Style="{StaticResource Btn}" HorizontalAlignment="Right" VerticalAlignment="Center">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="&#xE710;" FontFamily="{{icons}}" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <TextBlock Text="{{add_printer}}"/>
            </StackPanel>
          </Button>
        </Grid>

        <StackPanel x:Name="PrintersList"/>

        <Border Style="{StaticResource Card}" Padding="20,18">
          <StackPanel>
            <Grid Margin="0,0,0,12">
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="&#xE823;" FontFamily="{{icons}}" FontSize="16" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="{{recent}}" FontSize="16" FontWeight="Bold"/>
              </StackPanel>
              <Button x:Name="BtnViewLog" Style="{StaticResource Link}" HorizontalAlignment="Right">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="{{view_log}}"/>
                  <TextBlock x:Name="Chev" FontFamily="{{icons}}" FontSize="10" VerticalAlignment="Center" Margin="8,0,0,0"/>
                </StackPanel>
              </Button>
            </Grid>
            <ContentControl x:Name="RecentHeader"/>
            <StackPanel x:Name="RecentRows"/>
          </StackPanel>
        </Border>

        <StackPanel Orientation="Horizontal" Margin="4,14,0,0">
          <TextBlock x:Name="FooterIcon" Text="&#xE946;" FontFamily="{{icons}}" Foreground="#94A3B8"
                     VerticalAlignment="Center" Margin="0,0,8,0"/>
          <TextBlock x:Name="FooterText" Foreground="#64748B"/>
        </StackPanel>
      </StackPanel>
    </ScrollViewer>

    <!-- ===== Log page ===== -->
    <ScrollViewer x:Name="PageHistory" Grid.Column="1" VerticalScrollBarVisibility="Hidden" Visibility="Collapsed">
      <StackPanel Margin="28,24,28,20">
        <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
          <Border Width="48" Height="48" CornerRadius="12" Background="#EEEBFE">
            <TextBlock Text="&#xE81C;" FontFamily="{{icons}}" FontSize="22" Foreground="#5B45E6"
                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="{{history_title}}" FontSize="24" FontWeight="Bold"/>
            <TextBlock Text="{{history_sub}}" Foreground="#64748B" Margin="0,3,0,0"/>
          </StackPanel>
        </StackPanel>
        <Border Style="{StaticResource Card}" Padding="20,18">
          <StackPanel>
            <ContentControl x:Name="HistoryHeader"/>
            <StackPanel x:Name="HistoryRows"/>
          </StackPanel>
        </Border>
      </StackPanel>
    </ScrollViewer>

    <!-- ===== Settings page ===== -->
    <ScrollViewer x:Name="PageSettings" Grid.Column="1" VerticalScrollBarVisibility="Hidden" Visibility="Collapsed">
      <StackPanel Margin="28,24,28,20">
        <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
          <Border Width="48" Height="48" CornerRadius="12" Background="#EEEBFE">
            <TextBlock Text="&#xE713;" FontFamily="{{icons}}" FontSize="22" Foreground="#5B45E6"
                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="{{settings_title}}" FontSize="24" FontWeight="Bold"/>
            <TextBlock Text="{{settings_sub}}" Foreground="#64748B" Margin="0,3,0,0"/>
          </StackPanel>
        </StackPanel>
        <Border Style="{StaticResource Card}" Padding="22,8">
          <StackPanel>
            <Grid Margin="0,14">
              <StackPanel>
                <TextBlock Text="{{set_lang}}" FontSize="15" FontWeight="Bold"/>
                <TextBlock x:Name="LangNow" Foreground="#64748B" Margin="0,3,0,0"/>
              </StackPanel>
              <Button x:Name="BtnLang" Style="{StaticResource Outline}" Content="{{change}}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </Grid>
            <Border Height="1" Background="#F0F1F5"/>
            <Grid Margin="0,14">
              <StackPanel>
                <TextBlock Text="{{set_service}}" FontSize="15" FontWeight="Bold"/>
                <TextBlock Text="{{set_service_sub}}" Foreground="#64748B" Margin="0,3,0,0" TextWrapping="Wrap" MaxWidth="480" HorizontalAlignment="Left"/>
              </StackPanel>
              <Button x:Name="BtnRestartSvc" Style="{StaticResource Outline}" Content="{{restart}}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </Grid>
            <Border Height="1" Background="#F0F1F5"/>
            <Grid Margin="0,14">
              <StackPanel>
                <TextBlock Text="{{set_log}}" FontSize="15" FontWeight="Bold"/>
                <TextBlock Text="{{set_log_sub}}" Foreground="#64748B" Margin="0,3,0,0"/>
              </StackPanel>
              <Button x:Name="BtnLog" Style="{StaticResource Outline}" Content="{{open}}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </Grid>
            <Border Height="1" Background="#F0F1F5"/>
            <Grid Margin="0,14">
              <StackPanel>
                <TextBlock Text="{{set_remove}}" FontSize="15" FontWeight="Bold" Foreground="#B91C1C"/>
                <TextBlock Text="{{set_remove_sub}}" Foreground="#64748B" Margin="0,3,0,0" TextWrapping="Wrap" MaxWidth="480" HorizontalAlignment="Left"/>
              </StackPanel>
              <Button x:Name="BtnRemoveAll" Style="{StaticResource DangerSoft}" Content="{{remove_all}}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </Grid>
          </StackPanel>
        </Border>
        <TextBlock Text="DualPrint" Foreground="#94A3B8" Margin="4,14,0,0"/>
      </StackPanel>
    </ScrollViewer>

    <!-- ===== Add / edit dialog ===== -->
    <Grid x:Name="Overlay" Grid.ColumnSpan="2" Visibility="Collapsed" Background="#73111827">
      <Border Background="White" CornerRadius="18" Width="580" MaxHeight="660" Padding="26,24"
              HorizontalAlignment="Center" VerticalAlignment="Center">
        <DockPanel>
          <TextBlock x:Name="EdTitle" DockPanel.Dock="Top" FontSize="20" FontWeight="Bold" Margin="0,0,0,18"/>
          <Grid DockPanel.Dock="Bottom" Margin="0,18,0,0">
            <StackPanel Orientation="Horizontal">
              <Button x:Name="BtnSave" Style="{StaticResource Btn}" Content="{{save}}" MinWidth="130"/>
              <Button x:Name="BtnCancel" Style="{StaticResource Outline}" Content="{{cancel}}" Margin="10,0,0,0" MinWidth="100"/>
            </StackPanel>
            <Button x:Name="BtnDelete" Style="{StaticResource DangerSoft}" HorizontalAlignment="Right">
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="&#xE74D;" FontFamily="{{icons}}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="{{delete}}"/>
              </StackPanel>
            </Button>
          </Grid>
          <ScrollViewer VerticalScrollBarVisibility="Hidden">
            <StackPanel>
              <TextBlock Text="{{name_label}}" Style="{StaticResource Lbl}"/>
              <TextBox x:Name="TxtName" Margin="0,0,0,16"/>
              <TextBlock Text="{{targets_label}}" Style="{StaticResource Lbl}"/>
              <WrapPanel x:Name="EdTargets" Margin="0,0,0,8"/>
              <TextBlock Text="{{paper_size}}" Style="{StaticResource Lbl}"/>
              <ComboBox x:Name="CmbPaper" Width="200" Height="34" HorizontalAlignment="Left" Margin="0,0,0,16"
                        VerticalContentAlignment="Center" FontSize="13"/>
              <Border x:Name="PdfPanel" Background="#F7F5FF" CornerRadius="12" Padding="16" Visibility="Collapsed">
                <StackPanel>
                  <TextBlock Text="{{pdf_folder_label}}" Style="{StaticResource Lbl}"/>
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="*"/>
                      <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="TxtPdf" IsReadOnly="True" FlowDirection="LeftToRight"/>
                    <Button x:Name="BtnBrowse" Grid.Column="1" Style="{StaticResource Outline}" Content="{{browse}}"
                            Margin="8,0,0,0" Padding="14,7"/>
                  </Grid>
                  <TextBlock Text="{{prefix_label}}" Style="{StaticResource Lbl}" Margin="0,14,0,7"/>
                  <TextBox x:Name="TxtPrefix"/>
                  <TextBlock x:Name="TxtExample" Foreground="#7C3AED" FontSize="12" Margin="2,7,0,0" TextWrapping="Wrap"/>
                </StackPanel>
              </Border>
            </StackPanel>
          </ScrollViewer>
        </DockPanel>
      </Border>
    </Grid>

    <!-- ===== Toast message ===== -->
    <Border x:Name="Toast" Grid.ColumnSpan="2" Visibility="Collapsed" VerticalAlignment="Bottom" HorizontalAlignment="Center"
            Margin="0,0,0,26" CornerRadius="12" Padding="18,11" Background="#1E293B">
      <TextBlock x:Name="ToastText" Foreground="White" FontWeight="SemiBold" TextWrapping="Wrap" MaxWidth="600"/>
    </Border>
  </Grid>
</Window>
'@

$dir = if ($Lang -eq 'ar') { 'RightToLeft' } else { 'LeftToRight' }
$xamlText = $xamlText.Replace('{{dir}}', $dir).Replace('{{icons}}', $IF)
foreach ($m in [regex]::Matches($xamlText, '\{\{(\w+)\}\}')) {
    $xamlText = $xamlText.Replace($m.Value, (X (T $m.Groups[1].Value)))
}
[xml]$xaml = $xamlText
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
foreach ($n in 'SvcBox','SvcDot','SvcText','NavPrinters','NavHistory','NavSettings','PagePrinters','PageHistory','PageSettings',
               'BtnAdd','PrintersList','BtnViewLog','Chev','RecentHeader','RecentRows','FooterIcon','FooterText',
               'HistoryHeader','HistoryRows','LangNow','BtnLang','BtnRestartSvc','BtnLog','BtnRemoveAll',
               'Overlay','EdTitle','BtnSave','BtnCancel','BtnDelete','TxtName','EdTargets','CmbPaper','PdfPanel',
               'TxtPdf','BtnBrowse','TxtPrefix','TxtExample','Toast','ToastText') {
    Set-Variable -Name $n -Value $win.FindName($n)
}
$win.MaxHeight = [Windows.SystemParameters]::WorkArea.Height
$Chev.Text = if ($Lang -eq 'ar') { [string][char]0xE76B } else { [string][char]0xE76C }
$LangNow.Text = $LangNames[$Lang]

# ---------------------------------------------------------------- Messages
$ToastTimer = New-Object Windows.Threading.DispatcherTimer
$ToastTimer.Interval = [TimeSpan]::FromSeconds(3.5)
$ToastTimer.Add_Tick({ try { $Toast.Visibility = 'Collapsed'; $ToastTimer.Stop()  } catch { Report-UiError $_ } })
function Show-Toast([string]$msg, [bool]$ok = $true) {
    $Toast.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString($(if ($ok) { '#1E293B' } else { '#B91C1C' }))
    $ToastText.Text = $msg
    $Toast.Visibility = 'Visible'
    $ToastTimer.Stop(); $ToastTimer.Start()
}

# ---------------------------------------------------------------- Small elements
function Get-FileBadge([string]$doc) {
    $ext = ''
    try { $ext = [IO.Path]::GetExtension($doc).ToLower() } catch {}
    switch -Regex ($ext) {
        '^\.pdf$'              { return @('#E5484D', 'PDF') }
        '^\.(xlsx?|csv|xlsm)$' { return @('#1D9A5B', 'X') }
        '^\.(docx?|rtf)$'      { return @('#2F6FEB', 'W') }
        '^\.(pptx?)$'          { return @('#E07B39', 'P') }
        '^\.(png|jpe?g|gif|bmp|tiff?)$' { return @('#0EA5A4', 'IMG') }
        default                { return @('#94A3B8', '') }
    }
}

function Get-BadgeXaml([string]$color, [string]$label, [int]$w = 22, [int]$h = 26) {
    if ($label) {
        return "<Border Width='$w' Height='$h' CornerRadius='4' Background='$color' VerticalAlignment='Center'><TextBlock Text='$label' Foreground='White' FontSize='8' FontWeight='Bold' HorizontalAlignment='Center' VerticalAlignment='Center' FlowDirection='LeftToRight'/></Border>"
    }
    return "<TextBlock Text='&#xE8A5;' FontFamily='$IF' FontSize='18' Foreground='$color' VerticalAlignment='Center'/>"
}

function Get-TargetIconXaml([string]$target) {
    if ($target -eq $PdfTarget) { return (Get-BadgeXaml '#E5484D' 'PDF' 18 21) }
    return "<TextBlock Text='&#xE749;' FontFamily='$IF' FontSize='17' Foreground='#334155' VerticalAlignment='Center'/>"
}

function Get-StatusChipXaml($results) {
    $r = @($results)
    $ok = @($r | Where-Object { $_.Ok }).Count
    if ($r.Count -gt 0 -and $ok -eq $r.Count) { $bg = '#E8F8EE'; $fg = '#15803D'; $txt = T 'st_done'; $g = '&#xE73E;' }
    elseif ($ok -gt 0) { $bg = '#FFF7E6'; $fg = '#B45309'; $txt = T 'st_partial'; $g = '&#xE7BA;' }
    else { $bg = '#FEF2F2'; $fg = '#B91C1C'; $txt = T 'st_failed'; $g = '&#xE711;' }
    $tip = X (($r | ForEach-Object { "$($_.Target): $(if ($_.Ok) { 'OK' } else { $_.Msg })" }) -join "`n")
    return @"
<Border CornerRadius='12' Padding='10,4' Background='$bg' HorizontalAlignment='Left' ToolTip='$tip'>
  <StackPanel Orientation='Horizontal'>
    <Border Width='16' Height='16' CornerRadius='8' Background='$fg' Margin='0,0,6,0'>
      <TextBlock Text='$g' FontFamily='$IF' FontSize='9' Foreground='White' HorizontalAlignment='Center' VerticalAlignment='Center'/>
    </Border>
    <TextBlock Text='$(X $txt)' Foreground='$fg' FontWeight='SemiBold' FontSize='12'/>
  </StackPanel>
</Border>
"@
}

function Get-ColsXaml([bool]$full) {
    if ($full) { return "<Grid.ColumnDefinitions><ColumnDefinition Width='2.2*'/><ColumnDefinition Width='1.5*'/><ColumnDefinition Width='1.1*'/><ColumnDefinition Width='1.3*'/><ColumnDefinition Width='1*'/></Grid.ColumnDefinitions>" }
    return "<Grid.ColumnDefinitions><ColumnDefinition Width='2.4*'/><ColumnDefinition Width='1.3*'/><ColumnDefinition Width='1*'/><ColumnDefinition Width='1*'/></Grid.ColumnDefinitions>"
}

function New-TableHeader([bool]$full) {
    $c = 0
    $cells = @("<TextBlock Grid.Column='$c' Text='$(X (T 'col_doc'))'/>")
    if ($full) { $c++; $cells += "<TextBlock Grid.Column='$c' Text='$(X (T 'col_printer'))'/>" }
    $c++; $cells += "<TextBlock Grid.Column='$c' Text='$(X (T 'col_targets'))'/>"
    $c++; $cells += "<TextBlock Grid.Column='$c' Text='$(X (T 'col_time'))'/>"
    $c++; $cells += "<TextBlock Grid.Column='$c' Text='$(X (T 'col_status'))'/>"
    return New-El @"
<Border Background='#F6F7FB' CornerRadius='8' Padding='14,9' TextElement.Foreground='#64748B' TextElement.FontSize='12'>
  <Grid>$(Get-ColsXaml $full)$($cells -join '')</Grid>
</Border>
"@
}

function New-HistoryRow($h, [bool]$full) {
    $doc = if ($h.Doc) { [string]$h.Doc } else { T 'doc_unknown' }
    $b = Get-FileBadge $doc
    $time = ''
    try {
        $dt = [DateTimeOffset]::Parse([string]$h.Time).LocalDateTime
        $time = if ($full) { $dt.ToString('g', $Culture) } else { $dt.ToString('t', $Culture) }
    } catch {}
    $targets = @($h.Results | ForEach-Object { Get-TargetIconXaml $_.Target })
    $plus = "<TextBlock Text='+' Foreground='#94A3B8' Margin='7,0' VerticalAlignment='Center'/>"
    $c = 0
    $cells = @("<StackPanel Grid.Column='$c' Orientation='Horizontal'>$(Get-BadgeXaml $b[0] $b[1])<TextBlock Text='$(X $doc)' Margin='10,0,0,0' VerticalAlignment='Center' TextTrimming='CharacterEllipsis' MaxWidth='260' ToolTip='$(X $doc)'/></StackPanel>")
    if ($full) { $c++; $cells += "<TextBlock Grid.Column='$c' Text='$(X $h.Printer)' VerticalAlignment='Center' Foreground='#475569' TextTrimming='CharacterEllipsis'/>" }
    $c++; $cells += "<StackPanel Grid.Column='$c' Orientation='Horizontal'>$($targets -join $plus)</StackPanel>"
    $c++; $cells += "<TextBlock Grid.Column='$c' Text='$(X $time)' VerticalAlignment='Center' Foreground='#475569'/>"
    $c++; $cells += "<ContentControl Grid.Column='$c' VerticalAlignment='Center'>$(Get-StatusChipXaml $h.Results)</ContentControl>"
    return New-El @"
<Border BorderBrush='#F0F1F5' BorderThickness='0,0,0,1' Padding='14,9'>
  <Grid>$(Get-ColsXaml $full)$($cells -join '')</Grid>
</Border>
"@
}

function New-EmptyText([string]$t) {
    return New-El "<TextBlock Text='$(X $t)' Foreground='#94A3B8' Margin='14,16' HorizontalAlignment='Center'/>"
}

# ---------------------------------------------------------------- Printer cards
function New-TargetCard([string]$target, $cfg, $states) {
    if ($target -eq $PdfTarget) {
        $on = $cfg.PdfEnabled -ne $false
        $folder = if ($cfg.PdfFolder) { $cfg.PdfFolder } else { $DefaultPdf }
        $short = (($folder -split '\\') | Select-Object -Last 2) -join ' / '
        $dot = if ($on) { '#7C3AED' } else { '#94A3B8' }
        $st = if ($on) { T 'pdf_auto' } else { T 'pdf_off' }
        $el = New-El @"
<Border Background='White' BorderBrush='#ECEDF3' BorderThickness='1' CornerRadius='14' Padding='16' Margin='6'>
  <Grid>
    <Grid.ColumnDefinitions><ColumnDefinition Width='Auto'/><ColumnDefinition Width='*'/></Grid.ColumnDefinitions>
    <Border Width='52' Height='52' CornerRadius='12' Background='#EEF0FF' VerticalAlignment='Top'>
      $(Get-BadgeXaml '#5B45E6' 'PDF' 24 30)
    </Border>
    <StackPanel Grid.Column='1' Margin='14,0,0,0'>
      <TextBlock Text='$(X (T 'pdf_title'))' FontWeight='Bold' FontSize='15'/>
      <StackPanel Orientation='Horizontal' Margin='0,6,0,0'>
        <Ellipse Width='7' Height='7' Fill='$dot' VerticalAlignment='Center' Margin='0,0,7,0'/>
        <TextBlock Text='$(X $st)' Foreground='#475569'/>
      </StackPanel>
      <StackPanel Orientation='Horizontal' Margin='0,5,0,0' ToolTip='$(X $folder)'>
        <TextBlock Text='&#xE8B7;' FontFamily='$IF' Foreground='#64748B' VerticalAlignment='Center' Margin='0,0,6,0'/>
        <TextBlock Text='$(X $short)' Foreground='#64748B' FlowDirection='LeftToRight' TextTrimming='CharacterEllipsis' MaxWidth='200'/>
      </StackPanel>
      <Button x:Name='Act' Style='{DynamicResource Soft}' HorizontalAlignment='Left' Margin='0,11,0,0'>
        <StackPanel Orientation='Horizontal'>
          <TextBlock Text='&#xE8B7;' FontFamily='$IF' VerticalAlignment='Center' Margin='0,0,7,0'/>
          <TextBlock Text='$(X (T 'change_folder'))'/>
        </StackPanel>
      </Button>
    </StackPanel>
  </Grid>
</Border>
"@
        $btn = (FN $el 'Act'); $btn.Tag = $cfg.Name
        $btn.Add_Click({ try {
            $n = [string]$this.Tag
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            $dlg.Description = T 'folder_desc'
            $dlg.ShowNewFolderButton = $true
            if ($dlg.ShowDialog() -eq 'OK') {
                Update-Cfg $n @{ PdfFolder = $dlg.SelectedPath }
                Refresh-Printers; Show-Toast (T 'saved')
            }
         } catch { Report-UiError $_ } })
        return $el
    }

    $online = $true
    if ($target -and $states.ContainsKey($target)) { $online = $states[$target] }
    $dot = if ($online) { '#16A34A' } else { '#DC2626' }
    $st  = if ($online) { T 'connected' } else { T 'offline' }
    $detTxt = if ($script:PcCache.ContainsKey($target)) { Format-PrinterDetails $target $cfg } else { Format-PrinterDetails $target $cfg $true }
    $glyph = if ($target -match '(?i)80mm|58mm|pos|receipt|thermal|xprinter') { '&#xE8C7;' } else { '&#xE749;' }
    $el = New-El @"
<Border Background='White' BorderBrush='#ECEDF3' BorderThickness='1' CornerRadius='14' Padding='16' Margin='6'>
  <Grid>
    <Grid.ColumnDefinitions><ColumnDefinition Width='Auto'/><ColumnDefinition Width='*'/></Grid.ColumnDefinitions>
    <Border Width='52' Height='52' CornerRadius='12' Background='#F3F4F8' VerticalAlignment='Top'>
      <TextBlock Text='$glyph' FontFamily='$IF' FontSize='24' Foreground='#334155' HorizontalAlignment='Center' VerticalAlignment='Center'/>
    </Border>
    <StackPanel Grid.Column='1' Margin='14,0,0,0'>
      <TextBlock Text='$(X $target)' FontWeight='Bold' FontSize='15' TextTrimming='CharacterEllipsis' ToolTip='$(X $target)'/>
      <StackPanel Orientation='Horizontal' Margin='0,6,0,0'>
        <Ellipse Width='7' Height='7' Fill='$dot' VerticalAlignment='Center' Margin='0,0,7,0'/>
        <TextBlock Text='$(X $st)' Foreground='#475569'/>
      </StackPanel>
      <TextBlock x:Name='Det' Text='$(X $detTxt)' Foreground='#64748B' Margin='0,5,0,0'/>
      <Button x:Name='Act' Style='{DynamicResource Soft}' HorizontalAlignment='Left' Margin='0,11,0,0'>
        <StackPanel Orientation='Horizontal'>
          <TextBlock Text='&#xE713;' FontFamily='$IF' VerticalAlignment='Center' Margin='0,0,7,0'/>
          <TextBlock Text='$(X (T 'printer_settings'))'/>
        </StackPanel>
      </Button>
    </StackPanel>
  </Grid>
</Border>
"@
    if (-not $script:PcCache.ContainsKey($target)) {
        if ($online) { [void]$script:PendingDetails.Add(@{ Tb = (FN $el 'Det'); Target = $target; Cfg = $cfg }) }
        else { $script:PcCache[$target] = @{ Paper = $null; Color = $null }; (FN $el 'Det').Text = Format-PrinterDetails $target $cfg }
    }
    $btn = (FN $el 'Act'); $btn.Tag = $target
    $btn.Add_Click({ try {
        $t = [string]$this.Tag
        if ($t -match '"') { return }
        Start-Process rundll32.exe -ArgumentList "printui.dll,PrintUIEntry /e /n `"$t`""
     } catch { Report-UiError $_ } })
    return $el
}

$script:PcCache = @{}
$script:PendingDetails = New-Object System.Collections.ArrayList

function Format-PrinterDetails([string]$target, $cfg, [bool]$paperOnly = $false) {
    $details = @()
    $info = if ($script:PcCache.ContainsKey($target)) { $script:PcCache[$target] } else { @{ Paper = $null; Color = $null } }
    $paperTxt = if ($cfg.PaperSize -and $cfg.PaperSize -ne 'auto') { $Culture.TextInfo.ToTitleCase($cfg.PaperSize) } else { $info.Paper }
    if ($paperTxt) { $details += $paperTxt }
    if ($null -ne $info.Color) { $details += $(if ($info.Color) { T 'color' } else { T 'mono' }) }
    if ($paperOnly -and -not $details) { return '…' }
    return ($details -join '  •  ')
}

# Printer details (paper size/colors) are slow, so they load one by one after the window appears
function Start-DetailsLoad {
    if ($script:PendingDetails.Count -eq 0) { return }
    $item = $script:PendingDetails[0]; $script:PendingDetails.RemoveAt(0)
    try {
        $t = $item.Target
        if (-not $script:PcCache.ContainsKey($t)) {
            $info = @{ Paper = $null; Color = $null }
            try {
                $pc = Get-PrintConfiguration -PrinterName $t -ErrorAction Stop
                $info.Paper = [string]$pc.PaperSize; $info.Color = [bool]$pc.Color
            } catch {}
            $script:PcCache[$t] = $info
        }
        $item.Tb.Text = Format-PrinterDetails $t $item.Cfg
    } catch {}
    [void]$win.Dispatcher.BeginInvoke([Action]{ Start-DetailsLoad }, [Windows.Threading.DispatcherPriority]::Background)
}

function New-PrinterCard($cfg, $states) {
    $targets = @(Get-Targets $cfg)
    $offline = @($targets | Where-Object { $_ -and $_ -ne $PdfTarget -and $states.ContainsKey([string]$_) -and -not $states[[string]$_] }).Count
    if ($offline -eq 0) { $chipBg = '#E8F8EE'; $chipFg = '#15803D'; $chipTxt = T 'ready' }
    else { $chipBg = '#FFF7E6'; $chipFg = '#B45309'; $chipTxt = T 'partial' $offline }
    $hasPdf = $targets -contains $PdfTarget
    $isDef = ($script:DefaultPrinter -eq $cfg.Name)
    $defVis = if ($isDef) { 'Visible' } else { 'Collapsed' }
    $defBtnOn = if ($isDef) { 'False' } else { 'True' }
    $defGlyph = if ($isDef) { '&#xE73E;' } else { '&#xE735;' }
    $defTxt = if ($isDef) { T 'is_default' } else { T 'set_default' }
    $el = New-El @"
<Border Style='{DynamicResource Card}' Margin='0,0,0,18'>
  <StackPanel>
    <Grid Margin='0,0,0,12'>
      <StackPanel>
        <StackPanel Orientation='Horizontal'>
          <TextBlock Text='$(X $cfg.Name)' FontSize='19' FontWeight='Bold' VerticalAlignment='Center'/>
          <Button x:Name='Pencil' Style='{DynamicResource IconBtn}' Content='&#xE70F;' Margin='8,0,0,0' ToolTip='$(X (T 'edit'))'/>
          <Border x:Name='DefBadge' Visibility='$defVis' CornerRadius='10' Padding='9,3' Background='#EEEBFE' Margin='6,0,0,0' VerticalAlignment='Center'>
            <StackPanel Orientation='Horizontal'>
              <TextBlock Text='&#xE735;' FontFamily='$IF' FontSize='10' Foreground='#5B45E6' VerticalAlignment='Center' Margin='0,0,5,0'/>
              <TextBlock Text='$(X (T 'default_badge'))' Foreground='#4F3BD6' FontSize='11' FontWeight='SemiBold'/>
            </StackPanel>
          </Border>
        </StackPanel>
        <TextBlock Text='$(X (T 'card_sub' $targets.Count))' Foreground='#64748B' Margin='0,2,0,0'/>
      </StackPanel>
      <Border HorizontalAlignment='Right' VerticalAlignment='Top' CornerRadius='14' Padding='14,6' Background='$chipBg'>
        <StackPanel Orientation='Horizontal'>
          <Ellipse Width='8' Height='8' Fill='$chipFg' VerticalAlignment='Center' Margin='0,0,8,0'/>
          <TextBlock Text='$(X $chipTxt)' Foreground='$chipFg' FontWeight='SemiBold'/>
        </StackPanel>
      </Border>
    </Grid>
    <UniformGrid x:Name='Targets' Columns='2' Margin='-6,0'/>
    <Border Height='1' Background='#EEF0F4' Margin='0,16'/>
    <StackPanel Orientation='Horizontal'>
      <TextBlock Text='$(X (T 'paper_size'))' VerticalAlignment='Center' FontWeight='SemiBold' Foreground='#334155'/>
      <ComboBox x:Name='Paper' Width='170' Height='34' Margin='14,0,0,0' VerticalContentAlignment='Center' FontSize='13'/>
      <Border x:Name='Sep' Width='1' Height='26' Background='#E5E7EB' Margin='26,0'/>
      <StackPanel x:Name='PdfBox' Orientation='Horizontal'>
        <CheckBox x:Name='PdfToggle' Style='{DynamicResource Switch}' VerticalAlignment='Center'/>
        <TextBlock Text='$(X (T 'pdf_toggle'))' VerticalAlignment='Center' Margin='10,0,0,0' FontWeight='SemiBold' Foreground='#334155'/>
      </StackPanel>
    </StackPanel>
    <Grid Margin='0,18,0,0'>
      <Grid.ColumnDefinitions><ColumnDefinition Width='*'/><ColumnDefinition Width='12'/><ColumnDefinition Width='Auto'/><ColumnDefinition Width='12'/><ColumnDefinition Width='Auto'/></Grid.ColumnDefinitions>
      <Button x:Name='Test' Style='{DynamicResource Btn}' HorizontalAlignment='Stretch' MaxWidth='420' MinWidth='240'>
        <StackPanel Orientation='Horizontal'>
          <TextBlock Text='&#xE749;' FontFamily='$IF' VerticalAlignment='Center' Margin='0,0,9,0'/>
          <TextBlock Text='$(X (T 'test_page'))'/>
        </StackPanel>
      </Button>
      <Button x:Name='SetDef' Grid.Column='2' Style='{DynamicResource Outline}' IsEnabled='$defBtnOn'>
        <StackPanel Orientation='Horizontal'>
          <TextBlock Text='$defGlyph' FontFamily='$IF' VerticalAlignment='Center' Margin='0,0,8,0'/>
          <TextBlock Text='$(X $defTxt)'/>
        </StackPanel>
      </Button>
      <Button x:Name='Edit' Grid.Column='4' Style='{DynamicResource Outline}' MinWidth='120'>
        <StackPanel Orientation='Horizontal'>
          <TextBlock Text='&#xE70F;' FontFamily='$IF' VerticalAlignment='Center' Margin='0,0,8,0'/>
          <TextBlock Text='$(X (T 'edit'))'/>
        </StackPanel>
      </Button>
    </Grid>
  </StackPanel>
</Border>
"@
    $grid = (FN $el 'Targets')
    foreach ($t in $targets) {
        $tc = $null
        try { $tc = New-TargetCard $t $cfg $states } catch { Write-Log "Target card error [$t]: $_" }
        if (-not $tc) {
            $tc = New-Object Windows.Controls.Border
            $tc.Margin = New-Object Windows.Thickness(6); $tc.Padding = New-Object Windows.Thickness(16)
            $tc.CornerRadius = New-Object Windows.CornerRadius(14)
            $tc.BorderThickness = New-Object Windows.Thickness(1)
            $tc.BorderBrush = (New-Object Windows.Media.BrushConverter).ConvertFromString('#ECEDF3')
            $tb = New-Object Windows.Controls.TextBlock
            $tb.Text = $t; $tb.FontWeight = 'Bold'; $tb.FontSize = 15
            $tc.Child = $tb
        }
        [void]$grid.Children.Add($tc)
    }
    if ($targets.Count -le 1) { $grid.Columns = 1 }

    $paper = (FN $el 'Paper')
    Fill-Paper $paper $(if ($cfg.PaperSize) { $cfg.PaperSize } else { 'auto' })
    $paper.Tag = $cfg.Name
    $paper.Add_SelectionChanged({ try {
        if ($this.SelectedItem) {
            Update-Cfg ([string]$this.Tag) @{ PaperSize = [string]$this.SelectedItem.Tag }
            Show-Toast (T 'saved')
        }
     } catch { Report-UiError $_ } })

    $tog = (FN $el 'PdfToggle')
    if ($hasPdf -and $targets.Count -gt 1) {
        $tog.IsChecked = ($cfg.PdfEnabled -ne $false)
        $tog.Tag = $cfg.Name
        $tog.Add_Click({ try {
            Update-Cfg ([string]$this.Tag) @{ PdfEnabled = [bool]$this.IsChecked }
            Refresh-Printers
            Show-Toast (T 'saved')
         } catch { Report-UiError $_ } })
    } else {
        (FN $el 'PdfBox').Visibility = 'Collapsed'
        (FN $el 'Sep').Visibility = 'Collapsed'
    }

    foreach ($bn in 'Pencil', 'Edit') {
        $b = (FN $el $bn); $b.Tag = $cfg.Name
        $b.Add_Click({ try { Open-Editor ([string]$this.Tag)  } catch { Report-UiError $_ } })
    }
    $sd = (FN $el 'SetDef'); $sd.Tag = $cfg.Name
    $sd.Add_Click({ try {
        $n = [string]$this.Tag
        try { Set-DefaultMultiPrinter $n; Refresh-Printers; Show-Toast (T 'default_done' $n) }
        catch { Show-Toast (T 'error' $_.Exception.Message) $false }
     } catch { Report-UiError $_ } })
    $test = (FN $el 'Test'); $test.Tag = $cfg.Name
    $test.Add_Click({ try {
        $n = [string]$this.Tag
        try {
            $p = Get-CimInstance Win32_Printer | Where-Object { $_.Name -eq $n } | Select-Object -First 1
            if (-not $p) { throw (T 'err_notfound') }
            [void](Invoke-CimMethod -InputObject $p -MethodName PrintTestPage)
            Show-Toast (T 'test_sent' $n)
        } catch { Show-Toast (T 'error' $_.Exception.Message) $false }
     } catch { Report-UiError $_ } })
    return $el
}

function New-ErrorCard([string]$name, [string]$err) {
    $bc = New-Object Windows.Media.BrushConverter
    $card = New-Object Windows.Controls.Border
    $card.Background = $bc.ConvertFromString('#FFFFFF')
    $card.BorderBrush = $bc.ConvertFromString('#FECACA'); $card.BorderThickness = New-Object Windows.Thickness(1)
    $card.CornerRadius = New-Object Windows.CornerRadius(16)
    $card.Padding = New-Object Windows.Thickness(22); $card.Margin = New-Object Windows.Thickness(0, 0, 0, 18)
    $sp = New-Object Windows.Controls.StackPanel
    $t1 = New-Object Windows.Controls.TextBlock
    $t1.Text = $name; $t1.FontSize = 19; $t1.FontWeight = 'Bold'
    $t2 = New-Object Windows.Controls.TextBlock
    $t2.Text = $err; $t2.Foreground = $bc.ConvertFromString('#B91C1C'); $t2.TextWrapping = 'Wrap'
    $t2.Margin = New-Object Windows.Thickness(0, 8, 0, 14); $t2.FlowDirection = 'LeftToRight'
    $btn = New-Object Windows.Controls.Button
    $btn.Content = T 'edit'; $btn.Style = $win.FindResource('Outline'); $btn.HorizontalAlignment = 'Left'
    $btn.Tag = $name
    $btn.Add_Click({ try { Open-Editor ([string]$this.Tag)  } catch { Report-UiError $_ } })
    [void]$sp.Children.Add($t1); [void]$sp.Children.Add($t2); [void]$sp.Children.Add($btn)
    $card.Child = $sp
    return $card
}

function Fill-Paper($cmb, [string]$val) {
    $cmb.Items.Clear()
    foreach ($p in $PaperSizes) {
        $it = New-Object Windows.Controls.ComboBoxItem
        $it.Content = if ($p -eq 'auto') { T 'paper_auto' } elseif ($p -match '^[a-z]') { $Culture.TextInfo.ToTitleCase($p) } else { $p }
        $it.Tag = $p
        [void]$cmb.Items.Add($it)
        if ($p -eq $val) { $cmb.SelectedItem = $it }
    }
    if (-not $cmb.SelectedItem) { $cmb.SelectedIndex = 0 }
}

# ---------------------------------------------------------------- Page refresh
function Refresh-Printers {
    $snap = Get-PrinterSnapshot
    $script:DefaultPrinter = $snap.Default
    $states = $snap.States
    $config = @(Get-Config)
    if ($script:ConfigError) { Show-Toast (T 'err_config') $false }
    $script:PendingDetails.Clear()
    $PrintersList.Children.Clear()
    if ($config.Count -eq 0) {
        $empty = New-El @"
<Border Style='{DynamicResource Card}' Margin='0,0,0,18' Padding='30,36'>
  <StackPanel HorizontalAlignment='Center'>
    <Border Width='64' Height='64' CornerRadius='18' Background='#EEEBFE' HorizontalAlignment='Center'>
      <TextBlock Text='&#xE749;' FontFamily='$IF' FontSize='28' Foreground='#5B45E6' HorizontalAlignment='Center' VerticalAlignment='Center'/>
    </Border>
    <TextBlock Text='$(X (T 'empty_title'))' FontSize='17' FontWeight='Bold' HorizontalAlignment='Center' Margin='0,14,0,4'/>
    <TextBlock Text='$(X (T 'empty_sub'))' Foreground='#64748B' HorizontalAlignment='Center' TextAlignment='Center' TextWrapping='Wrap'/>
    <Button x:Name='Add2' Style='{DynamicResource Btn}' HorizontalAlignment='Center' Margin='0,18,0,0'>
      <StackPanel Orientation='Horizontal'>
        <TextBlock Text='&#xE710;' FontFamily='$IF' VerticalAlignment='Center' Margin='0,0,8,0'/>
        <TextBlock Text='$(X (T 'add_printer'))'/>
      </StackPanel>
    </Button>
  </StackPanel>
</Border>
"@
        (FN $empty 'Add2').Add_Click({ try { Open-Editor $null  } catch { Report-UiError $_ } })
        [void]$PrintersList.Children.Add($empty)
    }
    foreach ($c in $config) {
        try { [void]$PrintersList.Children.Add((New-PrinterCard $c $states)) }
        catch {
            $err = "$($_.Exception.Message)  @ $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
            Write-Log "Card error [$($c.Name)]: $err"
            [void]$PrintersList.Children.Add((New-ErrorCard $c.Name $err))
        }
    }

    $allTargets = @($config | ForEach-Object { Get-Targets $_ } | Where-Object { $_ -and $_ -ne $PdfTarget } | Select-Object -Unique)
    $off = @($allTargets | Where-Object { $_ -and $states.ContainsKey([string]$_) -and -not $states[[string]$_] }).Count
    if ($config.Count -eq 0) { $FooterText.Text = '' ; $FooterIcon.Visibility = 'Collapsed' }
    else {
        $FooterIcon.Visibility = 'Visible'
        $FooterText.Text = if ($off -eq 0) { T 'footer_ok' } else { T 'footer_bad' $off }
    }
    Refresh-Recent
    if ($script:PendingDetails.Count) {
        [void]$win.Dispatcher.BeginInvoke([Action]{ Start-DetailsLoad }, [Windows.Threading.DispatcherPriority]::Background)
    }
}

function Refresh-Recent {
    if (-not $RecentHeader.Content) { $RecentHeader.Content = New-TableHeader $false }
    $RecentRows.Children.Clear()
    $items = @(Get-History 5)
    if ($items.Count -eq 0) { [void]$RecentRows.Children.Add((New-EmptyText (T 'no_jobs'))); return }
    foreach ($h in $items) { try { [void]$RecentRows.Children.Add((New-HistoryRow $h $false)) } catch {} }
}

function Refresh-HistoryPage {
    if (-not $HistoryHeader.Content) { $HistoryHeader.Content = New-TableHeader $true }
    $HistoryRows.Children.Clear()
    $items = @(Get-History 200)
    if ($items.Count -eq 0) { [void]$HistoryRows.Children.Add((New-EmptyText (T 'no_jobs'))); return }
    foreach ($h in $items) { try { [void]$HistoryRows.Children.Add((New-HistoryRow $h $true)) } catch {} }
}

$script:LastHistoryStamp = $null
function Get-HistoryStamp {
    if (Test-Path $HistoryPath) { return (Get-Item $HistoryPath).LastWriteTimeUtc.Ticks }
    return 0
}

function Refresh-Service {
    $bc = New-Object Windows.Media.BrushConverter
    if (Test-ServiceRunning) {
        $SvcBox.Background = $bc.ConvertFromString('#E8F8EE'); $SvcDot.Fill = $bc.ConvertFromString('#16A34A')
        $SvcText.Foreground = $bc.ConvertFromString('#166534'); $SvcText.Text = T 'service_on'
        $SvcBox.ToolTip = $null
    } else {
        $SvcBox.Background = $bc.ConvertFromString('#FEF2F2'); $SvcDot.Fill = $bc.ConvertFromString('#DC2626')
        $SvcText.Foreground = $bc.ConvertFromString('#991B1B'); $SvcText.Text = T 'service_off'
        $SvcBox.ToolTip = T 'service_click'
    }
}

function Start-ServiceNow {
    try {
        if (@(Get-Config).Count -eq 0) { Show-Toast (T 'empty_title') $false; return }
        Register-Watcher; Start-Sleep -Milliseconds 800; Refresh-Service; Show-Toast (T 'service_started')
    } catch { Show-Toast (T 'error' $_.Exception.Message) $false }
}

# ---------------------------------------------------------------- Add / edit dialog
$script:EditName = $null

function Update-PdfPanel {
    $on = @($EdTargets.Children | Where-Object { $_.IsChecked -and [string]$_.Tag -eq $PdfTarget }).Count -gt 0
    $PdfPanel.Visibility = if ($on) { 'Visible' } else { 'Collapsed' }
}

function Update-Example {
    $base = $TxtPrefix.Text.Trim()
    if (-not $base) { $base = $TxtName.Text.Trim() }
    $base = $base -replace '[\\/:*?"<>|]', '_'
    $TxtExample.Text = T 'example' ("{0}_{1:yyyy-MM-dd_HH-mm-ss}.pdf" -f $base, (Get-Date))
}
$TxtPrefix.Add_TextChanged({ try { Update-Example  } catch { Report-UiError $_ } })
$TxtName.Add_TextChanged({ try { Update-Example  } catch { Report-UiError $_ } })

function Open-Editor($name) {
    $script:EditName = $name
    $cfg = $null
    if ($name) { $cfg = @(Get-Config) | Where-Object { $_.Name -eq $name } | Select-Object -First 1 }
    $EdTitle.Text = if ($cfg) { T 'editor_edit' } else { T 'editor_new' }
    $TxtName.Text = if ($cfg) { $cfg.Name } else { T 'default_name' }
    $BtnDelete.Visibility = if ($cfg) { 'Visible' } else { 'Collapsed' }

    $multi = @(Get-Config | ForEach-Object { $_.Name })
    $states = Get-PrinterStates
    $EdTargets.Children.Clear()
    @($states.Keys) | Where-Object { $multi -notcontains $_ -and $_ -notmatch 'Fax|OneNote' } | Sort-Object | ForEach-Object {
        $pn = [string]$_
        $isPdf = $pn -eq $PdfTarget
        $online = if ($states.ContainsKey($pn)) { $states[$pn] } else { $true }
        $icon = if ($isPdf) { Get-BadgeXaml '#E5484D' 'PDF' 20 24 } else { "<TextBlock Text='&#xE749;' FontFamily='$IF' FontSize='18' Foreground='#334155' VerticalAlignment='Center'/>" }
        $dot = if ($isPdf -or $online) { '#16A34A' } else { '#DC2626' }
        $content = New-El @"
<StackPanel Orientation='Horizontal' Margin='0,0,24,0'>
  <Border Width='34' Height='34' CornerRadius='9' Background='#F1F2F6'>$icon</Border>
  <StackPanel Margin='10,0,0,0' VerticalAlignment='Center'>
    <TextBlock Text='$(X $pn)' FontWeight='SemiBold' TextTrimming='CharacterEllipsis' MaxWidth='150' ToolTip='$(X $pn)'/>
    <StackPanel Orientation='Horizontal' Margin='0,2,0,0'>
      <Ellipse Width='6' Height='6' Fill='$dot' VerticalAlignment='Center' Margin='0,0,5,0'/>
      <TextBlock Text='$(X $(if ($isPdf) { T 'pdf_title' } elseif ($online) { T 'connected' } else { T 'offline' }))' FontSize='11' Foreground='#64748B'/>
    </StackPanel>
  </StackPanel>
</StackPanel>
"@
        $cb = New-Object Windows.Controls.CheckBox
        $cb.Style = $win.FindResource('Sel')
        $cb.Content = $content
        $cb.Tag = $pn
        if ($cfg -and @(Get-Targets $cfg) -contains $pn) { $cb.IsChecked = $true }
        $cb.Add_Click({ try { Update-PdfPanel  } catch { Report-UiError $_ } })
        [void]$EdTargets.Children.Add($cb)
    }
    Fill-Paper $CmbPaper $(if ($cfg -and $cfg.PaperSize) { $cfg.PaperSize } else { 'auto' })
    $TxtPdf.Text = if ($cfg -and $cfg.PdfFolder) { $cfg.PdfFolder } else { $DefaultPdf }
    $TxtPrefix.Text = if ($cfg -and $cfg.PdfPrefix) { $cfg.PdfPrefix } else { '' }
    Update-PdfPanel; Update-Example
    $Overlay.Visibility = 'Visible'
    $TxtName.Focus() | Out-Null
}

$BtnCancel.Add_Click({ try { $Overlay.Visibility = 'Collapsed'  } catch { Report-UiError $_ } })

$BtnBrowse.Add_Click({ try {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = T 'folder_desc'
    $dlg.ShowNewFolderButton = $true
    if (Test-Path $TxtPdf.Text) { $dlg.SelectedPath = $TxtPdf.Text }
    if ($dlg.ShowDialog() -eq 'OK') { $TxtPdf.Text = $dlg.SelectedPath }
 } catch { Report-UiError $_ } })

$BtnSave.Add_Click({ try {
    try {
        $name = $TxtName.Text.Trim()
        $targets = @($EdTargets.Children | Where-Object { $_.IsChecked } | ForEach-Object { [string]$_.Tag })
        if (-not $name) { throw (T 'err_name') }
        if (-not (Test-PrinterName $name)) { throw (T 'err_badname') }
        if ($targets.Count -lt 1) { throw (T 'err_one') }
        $paper = [string]$CmbPaper.SelectedItem.Tag
        $pdfFolder = $null; $pdfPrefix = $null
        if ($targets -contains $PdfTarget) {
            $pdfFolder = $TxtPdf.Text.Trim(); $pdfPrefix = $TxtPrefix.Text.Trim()
            if (-not $pdfFolder) { throw (T 'err_folder') }
            New-Item -ItemType Directory -Force -Path $pdfFolder | Out-Null
        }
        $win.Cursor = [Windows.Input.Cursors]::Wait
        $BtnSave.IsEnabled = $false
        if (($targets | Where-Object { $_ -ne $PdfTarget }) -and -not (Find-Sumatra)) { throw (T 'err_sumatra') }

        if ($script:EditName) {
            $old = $script:EditName
            if ($name -ne $old) {
                if (Get-Printer -Name $name -ErrorAction SilentlyContinue) { throw (T 'err_exists') }
                Rename-Printer -Name $old -NewName $name
                Update-Cfg $old @{ Name = $name }
            }
            Update-Cfg $name @{ Targets = [string[]]$targets; PdfFolder = $pdfFolder; PdfPrefix = $pdfPrefix; PaperSize = $paper }
            Show-Toast (T 'saved')
        } else {
            New-MultiPrinter $name $targets $pdfFolder $pdfPrefix $paper
            Register-Watcher
            Show-Toast (T 'created' $name ($targets -join ' + '))
        }
        $Overlay.Visibility = 'Collapsed'
        Refresh-Printers; Refresh-Service
    } catch {
        Show-Toast (T 'error' $_.Exception.Message) $false
    } finally {
        $win.Cursor = $null
        $BtnSave.IsEnabled = $true
    }
 } catch { Report-UiError $_ } })

$BtnDelete.Add_Click({ try {
    $nm = $script:EditName
    if (-not $nm) { return }
    $r = [Windows.MessageBox]::Show((T 'confirm_delete' $nm), (T 'confirm_title'), 'YesNo', 'Question')
    if ($r -ne 'Yes') { return }
    try {
        Remove-MultiPrinter $nm
        $Overlay.Visibility = 'Collapsed'
        Refresh-Printers; Show-Toast (T 'deleted' $nm)
    } catch { Show-Toast (T 'error' $_.Exception.Message) $false }
 } catch { Report-UiError $_ } })

# ---------------------------------------------------------------- Navigation and buttons
function Show-Page([string]$p) {
    # Buttons and pages are set up first, then the refresh, so any refresh error does not block navigation
    $NavPrinters.IsChecked = ($p -eq 'printers')
    $NavHistory.IsChecked  = ($p -eq 'history')
    $NavSettings.IsChecked = ($p -eq 'settings')
    $PagePrinters.Visibility = if ($p -eq 'printers') { 'Visible' } else { 'Collapsed' }
    $PageHistory.Visibility  = if ($p -eq 'history')  { 'Visible' } else { 'Collapsed' }
    $PageSettings.Visibility = if ($p -eq 'settings') { 'Visible' } else { 'Collapsed' }
    try {
        if ($p -eq 'history')  { Refresh-HistoryPage }
        if ($p -eq 'printers') { Refresh-Printers }
    } catch {
        Write-Log "Page refresh [$p]: $_"
        Show-Toast (T 'error' $_.Exception.Message) $false
    }
}
foreach ($nb in @($NavPrinters, $NavHistory, $NavSettings)) {
    $nb.Add_PreviewMouseLeftButtonDown({
        param($sender, $e)
 try {        $e.Handled = $true
        $page = switch ($sender.Name) { 'NavHistory' { 'history' } 'NavSettings' { 'settings' } default { 'printers' } }
        Show-Page $page
     } catch { Report-UiError $_ } })
}
$BtnViewLog.Add_Click({ try { Show-Page 'history'  } catch { Report-UiError $_ } })
$BtnAdd.Add_Click({ try { Open-Editor $null  } catch { Report-UiError $_ } })

$SvcBox.Add_MouseLeftButtonUp({ try { if (-not (Test-ServiceRunning)) { Start-ServiceNow }  } catch { Report-UiError $_ } })
$BtnRestartSvc.Add_Click({ try { Start-ServiceNow  } catch { Report-UiError $_ } })

$BtnLog.Add_Click({ try {
    if (Test-Path $LogPath) { Start-Process notepad.exe $LogPath } else { Show-Toast (T 'no_log') }
 } catch { Report-UiError $_ } })

$BtnRemoveAll.Add_Click({ try {
    $r = [Windows.MessageBox]::Show((T 'ra_confirm'), (T 'remove_all'), 'YesNo', 'Warning')
    if ($r -ne 'Yes') { return }
    try { Uninstall-All; Refresh-Printers; Refresh-Service; Show-Toast (T 'ra_done') }
    catch { Show-Toast (T 'error' $_.Exception.Message) $false }
 } catch { Report-UiError $_ } })

$BtnLang.Add_Click({ try {
    $new = Show-LanguagePicker
    if ($new -and $new -ne $Lang) {
        Set-Lang $new
        Start-Process -FilePath $AppExe
        $win.Close()
    }
 } catch { Report-UiError $_ } })

$win.Add_KeyDown({ try { if ($_.Key -eq 'Escape' -and $Overlay.Visibility -eq 'Visible') { $Overlay.Visibility = 'Collapsed' }  } catch { Report-UiError $_ } })

# Auto-refresh of the log and service status
$RefreshTimer = New-Object Windows.Threading.DispatcherTimer
$RefreshTimer.Interval = [TimeSpan]::FromSeconds(3)
$RefreshTimer.Add_Tick({ try {
    try {
        $stamp = Get-HistoryStamp
        if ($stamp -ne $script:LastHistoryStamp) {
            $script:LastHistoryStamp = $stamp
            if ($PagePrinters.Visibility -eq 'Visible') { Refresh-Recent }
            if ($PageHistory.Visibility -eq 'Visible') { Refresh-HistoryPage }
        }
        Refresh-Service
    } catch {}
 } catch { Report-UiError $_ } })

# ---------------------------------------------------------------- Startup
# The window appears immediately; data loads after it

function Test-RootOpen {
    try {
        foreach ($r in (Get-Acl $Root).Access) {
            $sid = try { $r.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { '' }
            if ($sid -in @('S-1-5-11', 'S-1-1-0', 'S-1-5-32-545') -and ($r.FileSystemRights -band [Security.AccessControl.FileSystemRights]::WriteData)) { return $true }
        }
    } catch {}
    return $false
}

function Update-WatcherIfNeeded {
    try { if (Test-RootOpen) { Protect-RootFolder } } catch { Write-Log "ACL check: $_" }
    if (@(Get-Config).Count -eq 0) { try { Refresh-Service } catch {}; return }
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        $oldTask = Get-ScheduledTask -TaskName $OldTaskName -ErrorAction SilentlyContinue
        $needs = (-not $task) -or $oldTask -or ($task.Actions[0].Execute -ne $RootExe) -or (-not (Test-Path $RootExe)) -or (@($task.Triggers).Count -lt 2) -or (@($task.Triggers | Where-Object { $_.Repetition.Interval -eq 'PT1M' }).Count -eq 0)
        if (-not $needs -and $AppExe -ne $RootExe) {
            $a = Get-Item $AppExe; $b = Get-Item $RootExe
            $needs = ($a.Length -ne $b.Length) -or ($a.VersionInfo.FileVersion -ne $b.VersionInfo.FileVersion) -or
                     ((Get-FileHash $AppExe).Hash -ne (Get-FileHash $RootExe).Hash)
        }
        if ($needs) { Register-Watcher }
        elseif (-not (Test-ServiceRunning)) { Start-ScheduledTask -TaskName $TaskName }
    } catch { Write-Log "Watcher upgrade: $_" }
    Refresh-Service
}

function Start-InitialLoad {
    try { Refresh-Printers } catch { Write-Log "Initial load: $_"; Show-Toast (T 'error' $_.Exception.Message) $false }
    try { $script:LastHistoryStamp = Get-HistoryStamp } catch {}
    $RefreshTimer.Start()
    [void]$win.Dispatcher.BeginInvoke([Action]{ Update-WatcherIfNeeded }, [Windows.Threading.DispatcherPriority]::ApplicationIdle)
}

[void]$PrintersList.Children.Add((New-EmptyText (T 'loading')))
Refresh-Service
$win.Add_ContentRendered({
    [void]$win.Dispatcher.BeginInvoke([Action]{ Start-InitialLoad }, [Windows.Threading.DispatcherPriority]::Background)
})
[void]$win.ShowDialog()
$RefreshTimer.Stop()
