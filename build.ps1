<#
  build.ps1 — builds DualPrint.exe from the files in src/
  Run on Windows:      powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 3.0.0
  Output:              build\DualPrint.exe  and  build\DualPrint.zip
  Nothing to install: it uses the csc.exe that ships with .NET Framework on Windows.
#>
param([string]$Version = '0.0.0')

$ErrorActionPreference = 'Stop'
$AppName = 'DualPrint'                                  # Drives every input/output/resource name below
$root = $PSScriptRoot
$out  = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$v = ($Version.TrimStart('v') -split '[^0-9\.]')[0]
$parts = @($v.Split('.') | Where-Object { $_ -ne '' })
while ($parts.Count -lt 4) { $parts += '0' }
$fileVersion = ($parts[0..3] -join '.')
Write-Host "Building $AppName $fileVersion"

# 1) Embed the strings (languages) into the script
$utf8 = New-Object System.Text.UTF8Encoding($false)
$template = [IO.File]::ReadAllText((Join-Path $root "src\$AppName.ps1"), [Text.Encoding]::UTF8)
$strings  = [IO.File]::ReadAllText((Join-Path $root 'src\strings.json'), [Text.Encoding]::UTF8).Trim()
$null = $strings | ConvertFrom-Json                     # Checks that the languages file is valid
if ($strings.Contains("'@")) { throw "strings.json must not contain '@" }
$script = $template.Replace('__STRINGS_JSON__', $strings)
[IO.File]::WriteAllText((Join-Path $out "$AppName.ps1"), $script, $utf8)

# 2) Version number inside the exe
$cs = [IO.File]::ReadAllText((Join-Path $root 'src\Launcher.cs'))
$cs = $cs -replace 'AssemblyVersion\("[\d\.]+"\)', "AssemblyVersion(""$fileVersion"")"
$cs = $cs -replace 'AssemblyFileVersion\("[\d\.]+"\)', "AssemblyFileVersion(""$fileVersion"")"
[IO.File]::WriteAllText((Join-Path $out 'Launcher.cs'), $cs, $utf8)

# 3) Compile
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path $csc)) { throw "csc.exe not found (.NET Framework 4.x is required)" }

& $csc /nologo /target:winexe /platform:anycpu /optimize+ `
    "/out:$(Join-Path $out "$AppName.exe")" `
    "/win32icon:$(Join-Path $root 'assets\icon.ico')" `
    "/resource:$(Join-Path $out "$AppName.ps1"),$AppName.ps1" `
    (Join-Path $out 'Launcher.cs')
if ($LASTEXITCODE -ne 0) { throw "csc failed with exit code $LASTEXITCODE" }

# 4) Zip file for download
$zip = Join-Path $out "$AppName.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $out "$AppName.exe") -DestinationPath $zip

# 5) Guard (spec AC-1.1, AC-6.5): the zip holds exactly $AppName.exe and nothing with the old brand name
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try { $entries = @($archive.Entries | ForEach-Object { $_.FullName }) } finally { $archive.Dispose() }
$legacy = @($entries | Where-Object { $_ -match 'MultiPrint' })   # Legacy (v2.x MultiPrint) name must never ship
if ($legacy.Count) { throw "Zip contains legacy MultiPrint entries: $($legacy -join ', ')" }
if ($entries.Count -ne 1 -or $entries[0] -ne "$AppName.exe") { throw "Zip must contain exactly $AppName.exe, found: $($entries -join ', ')" }
Write-Host "Zip check passed: $($entries -join ', ')"
Write-Host "Done: $zip"
