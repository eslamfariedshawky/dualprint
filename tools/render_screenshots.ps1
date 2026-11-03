# Renders the website screenshots (website/assets/screenshot-<lang>.png) from the real DualPrint UI.
#
# Safe by design: the app's own script (build/DualPrint.ps1) runs against a throw-away sandbox folder with
# sample printers and history. System-touching functions are replaced with stubs, so this script does NOT
# need admin, create printers, register the scheduled task, touch C:\DualPrint, or remove any old install.
#
# Usage (from the repository root, after .\build.ps1):
#   powershell -NoProfile -ExecutionPolicy Bypass -STA -File tools\render_screenshots.ps1
param(
    [string[]]$Langs = @('en', 'ar', 'es', 'fr', 'de'),
    [string]$OutDir = (Join-Path $PSScriptRoot '..\website\assets')
)
$ErrorActionPreference = 'Stop'
$repo   = Split-Path $PSScriptRoot -Parent
$appPs1 = Join-Path $repo 'build\DualPrint.ps1'
$appExe = Join-Path $repo 'build\DualPrint.exe'
if (-not (Test-Path $appPs1)) { throw "Run .\build.ps1 first ($appPs1 not found)" }
$OutDir = (Resolve-Path $OutDir).Path
$src = [IO.File]::ReadAllText($appPs1)
if ($src.Contains('__STRINGS_JSON__')) { throw 'build\DualPrint.ps1 has no embedded strings; run .\build.ps1' }

# Everything the UI needs before the window is shown stays as is; the startup tail is replaced by the renderer.
$tailMarker = "[void]`$PrintersList.Children.Add((New-EmptyText (T 'loading')))"
$cut = $src.LastIndexOf($tailMarker)
if ($cut -lt 0) { throw 'Startup marker not found in DualPrint.ps1; update render_screenshots.ps1' }

$renderTail = @'
# ---------------------------------------------------------------- Screenshot stubs (no system changes)
function Get-PrinterSnapshot { return @{ States = @{ 'EPSON L4150 Series' = $true; 'Microsoft Print to PDF' = $true }; Default = 'Office Printer' } }
function Test-ServiceRunning { return $true }
function Update-WatcherIfNeeded { }
function Register-Watcher { }
function Remove-LegacyServices { return $false }
$script:PcCache['EPSON L4150 Series'] = @{ Paper = 'A4'; Color = $true }
$win.MaxHeight = [double]::PositiveInfinity
$win.MinWidth = 0; $win.MinHeight = 0
$win.Content.Width = 1080; $win.Content.Height = 830
$win.SizeToContent = 'WidthAndHeight'
$win.WindowStartupLocation = 'Manual'; $win.Left = -20000; $win.Top = -20000
$win.ShowInTaskbar = $false; $win.ShowActivated = $false

$script:Shot = $null
$win.Add_ContentRendered({
    Refresh-Service
    Refresh-Printers
    $t = New-Object Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMilliseconds(1500)
    $t.Add_Tick({
        $this.Stop()
        try {
            $root = $win.Content
            $w = $root.ActualWidth; $h = $root.ActualHeight
            $scale = 1.5
            $dv = New-Object Windows.Media.DrawingVisual
            $dc = $dv.RenderOpen()
            $dc.DrawRectangle($win.Background, $null, (New-Object Windows.Rect 0, 0, $w, $h))
            $dc.Close()
            $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap ([int]($w * $scale)), ([int]($h * $scale)), (96 * $scale), (96 * $scale), ([Windows.Media.PixelFormats]::Pbgra32)
            $bmp.Render($dv)
            $bmp.Render($root)
            $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
            # A right-to-left window renders mirrored when captured on its own; flip it back
            $img = if ($win.FlowDirection -eq 'RightToLeft') { New-Object Windows.Media.Imaging.TransformedBitmap $bmp, (New-Object Windows.Media.ScaleTransform -1, 1) } else { $bmp }
            $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($img))
            $fs = [IO.File]::Create($env:DP_SHOT_OUT); $enc.Save($fs); $fs.Close()
        } catch { [IO.File]::WriteAllText($env:DP_SHOT_OUT + '.error.txt', "$_") }
        $win.Close()
    })
    $t.Start()
})
[void]$win.ShowDialog()
'@

$sandboxBase = Join-Path ([IO.Path]::GetTempPath()) ('dualprint-shots-' + [Guid]::NewGuid().ToString('N'))
$utf8 = New-Object Text.UTF8Encoding($false)
try {
    foreach ($lang in $Langs) {
        $sb = Join-Path $sandboxBase $lang
        New-Item -ItemType Directory -Force -Path $sb | Out-Null
        $docs = 'C:\Users\User\Documents\DualPrint PDFs'
        $cfg = @(@{ Name = 'Office Printer'; Targets = @('EPSON L4150 Series', 'Microsoft Print to PDF'); PdfFolder = $docs; PdfPrefix = ''; PaperSize = 'A4'; PdfEnabled = $true })
        [IO.File]::WriteAllText((Join-Path $sb 'printers.json'), (ConvertTo-Json -InputObject $cfg -Depth 5), $utf8)
        [IO.File]::WriteAllText((Join-Path $sb 'settings.json'), (@{ Lang = $lang } | ConvertTo-Json), $utf8)
        $today = (Get-Date).Date
        $hist = foreach ($j in @(@('Account statement.pdf', 15, 25), @('Sales report.xlsx', 15, 38), @('Sales invoice.pdf', 15, 42))) {
            $res = @(@{ Target = 'Microsoft Print to PDF'; Ok = $true }, @{ Target = 'EPSON L4150 Series'; Ok = $true })
            [pscustomobject]@{ Time = $today.AddHours($j[1]).AddMinutes($j[2]).ToString('o'); Printer = 'Office Printer'; Doc = $j[0]; Results = $res } | ConvertTo-Json -Compress -Depth 5
        }
        [IO.File]::WriteAllText((Join-Path $sb 'history.jsonl'), (($hist -join "`r`n") + "`r`n"), $utf8)

        $head = $src.Substring(0, $cut).Replace('C:\DualPrint', $sb)
        if ($head -match 'C:\\DualPrint') { throw 'An unsandboxed C:\DualPrint path remains' }
        $paramLine = 'param([switch]$Watch)'
        if (-not $head.Contains($paramLine)) { throw 'param line not found in DualPrint.ps1; update render_screenshots.ps1' }
        $head = $head.Replace($paramLine, "`$Watch = `$false; `$AppExe = '$appExe'")
        $script = $head + $renderTail
        $runner = Join-Path $sandboxBase "run-$lang.ps1"
        [IO.File]::WriteAllText($runner, $script, (New-Object Text.UTF8Encoding($true)))

        $out = Join-Path $OutDir "screenshot-$lang.png"
        $env:DP_SHOT_OUT = $out
        $p = Start-Process powershell.exe -PassThru -WindowStyle Hidden -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$runner`"")
        if (-not $p.WaitForExit(90000)) {
            Stop-Process -Id $p.Id -Force
            $err = Join-Path $sb 'error.txt'
            throw "Render timed out for $lang. $(if (Test-Path $err) { Get-Content $err -Raw })"
        }
        if (Test-Path "$out.error.txt") { throw "Render failed for ${lang}: $(Get-Content "$out.error.txt" -Raw)" }
        if (-not (Test-Path $out)) { throw "No screenshot written for $lang" }
        Write-Host "OK $lang -> $out"
    }
} finally {
    Remove-Item -LiteralPath $sandboxBase -Recurse -Force -ErrorAction SilentlyContinue
}
