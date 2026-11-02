<#
  build.ps1 — يبني MultiPrint.exe من ملفات src/
  التشغيل على ويندوز:   powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 2.0.6
  الناتج:               build\MultiPrint.exe  و  build\MultiPrint.zip
  مش محتاج تسطّب أي حاجة: بيستخدم csc.exe اللي جاي مع .NET Framework في ويندوز.
#>
param([string]$Version = '0.0.0')

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out  = Join-Path $root 'build'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$v = ($Version.TrimStart('v') -split '[^0-9\.]')[0]
$parts = @($v.Split('.') | Where-Object { $_ -ne '' })
while ($parts.Count -lt 4) { $parts += '0' }
$fileVersion = ($parts[0..3] -join '.')
Write-Host "Building MultiPrint $fileVersion"

# 1) دمج النصوص (اللغات) داخل السكربت
$utf8 = New-Object System.Text.UTF8Encoding($false)
$template = [IO.File]::ReadAllText((Join-Path $root 'src\MultiPrint.ps1'), [Text.Encoding]::UTF8)
$strings  = [IO.File]::ReadAllText((Join-Path $root 'src\strings.json'), [Text.Encoding]::UTF8).Trim()
$null = $strings | ConvertFrom-Json                     # يتأكد إن ملف اللغات سليم
if ($strings.Contains("'@")) { throw "strings.json must not contain '@" }
$script = $template.Replace('__STRINGS_JSON__', $strings)
[IO.File]::WriteAllText((Join-Path $out 'MultiPrint.ps1'), $script, $utf8)

# 2) رقم الإصدار داخل الـ exe
$cs = [IO.File]::ReadAllText((Join-Path $root 'src\Launcher.cs'))
$cs = $cs -replace 'AssemblyVersion\("[\d\.]+"\)', "AssemblyVersion(""$fileVersion"")"
$cs = $cs -replace 'AssemblyFileVersion\("[\d\.]+"\)', "AssemblyFileVersion(""$fileVersion"")"
[IO.File]::WriteAllText((Join-Path $out 'Launcher.cs'), $cs, $utf8)

# 3) الترجمة
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path $csc)) { throw "csc.exe not found (.NET Framework 4.x is required)" }

& $csc /nologo /target:winexe /platform:anycpu /optimize+ `
    "/out:$(Join-Path $out 'MultiPrint.exe')" `
    "/win32icon:$(Join-Path $root 'assets\icon.ico')" `
    "/resource:$(Join-Path $out 'MultiPrint.ps1'),MultiPrint.ps1" `
    (Join-Path $out 'Launcher.cs')
if ($LASTEXITCODE -ne 0) { throw "csc failed with exit code $LASTEXITCODE" }

# 4) ملف مضغوط للتحميل
$zip = Join-Path $out 'MultiPrint.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $out 'MultiPrint.exe') -DestinationPath $zip
Write-Host "Done: $zip"
