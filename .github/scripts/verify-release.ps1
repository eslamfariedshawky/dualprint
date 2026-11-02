# Local verification of the workflow's real build, packaging, and release metadata.
# Run from the repository root: powershell -File .github/scripts/verify-release.ps1
$ErrorActionPreference = 'Stop'
$workflow = Get-Content .github/workflows/release.yml -Raw
function Get-WorkflowScript([string]$step) {
    $pattern = '(?ms)^      - name: ' + [regex]::Escape($step) + '\r?\n(?:(?!      - ).)*?        run: \|\r?\n(?<code>(?:          [^\r\n]*\r?\n|\r?\n)+)'
    $match = [regex]::Match($workflow, $pattern)
    if (-not $match.Success) { throw "Workflow step missing: $step" }
    [scriptblock]::Create(($match.Groups['code'].Value -replace '(?m)^          ', ''))
}
function Assert([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
}
$build = Get-WorkflowScript 'Build'
$package = Get-WorkflowScript 'Package release assets'
$metadata = Get-WorkflowScript 'Prepare release metadata'
$saved = @{}
foreach ($name in 'REF_TYPE', 'REF_NAME', 'GITHUB_OUTPUT') { $saved[$name] = [Environment]::GetEnvironmentVariable($name) }
try {
    $env:REF_TYPE = 'tag'
    $env:REF_NAME = 'v3.0.0'
    $aliasBefore = if (Test-Path build/MultiPrint.zip) { (Get-FileHash build/MultiPrint.zip -Algorithm SHA256).Hash }
    & $build
    if ($aliasBefore) {
        Assert ($aliasBefore -eq (Get-FileHash build/MultiPrint.zip -Algorithm SHA256).Hash) 'build.ps1 must not modify the compatibility alias.'
    } else {
        Assert (-not (Test-Path build/MultiPrint.zip)) 'build.ps1 must produce only the canonical ZIP.'
    }
    & $package
    $canonical = Get-FileHash build/DualPrint.zip -Algorithm SHA256
    Assert ($canonical.Hash -eq (Get-FileHash build/MultiPrint.zip -Algorithm SHA256).Hash) 'ZIP alias differs.'
    $checksums = @(Get-Content build/SHA256SUMS.txt)
    Assert ($checksums.Count -eq 2) 'Expected exactly two checksum lines.'
    foreach ($name in 'DualPrint.zip', 'MultiPrint.zip') {
        Assert ($checksums -ccontains ($canonical.Hash.ToLower() + '  ' + $name)) "Missing checksum: $name"
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $PWD 'build/DualPrint.zip'))
    try { Assert ($zip.Entries.Count -eq 1 -and $zip.Entries[0].FullName -ceq 'DualPrint.exe') 'Unexpected ZIP contents.' }
    finally { $zip.Dispose() }
    Assert ((Get-Item build/DualPrint.exe).VersionInfo.FileVersion -eq '3.0.0.0') 'Unexpected EXE version.'
    Write-Host 'PASS: canonical build, same-byte alias, both checksums, ZIP contents, EXE version.'

    # Use an isolated fixture directory; never edit real release notes or publish anything.
    $fixture = New-Item -ItemType Directory (Join-Path $PWD ('build/verify-release-' + [guid]::NewGuid()))
    Push-Location $fixture.FullName
    try {
        New-Item -ItemType Directory docs/release-notes -Force | Out-Null
        foreach ($tag in 'v3.0.0', '3.0.0', 'vnext') {
            $env:REF_NAME = $tag
            $env:GITHUB_OUTPUT = Join-Path $PWD 'outputs.txt'
            Set-Content $env:GITHUB_OUTPUT ''
            & $metadata
            $outputs = @(Get-Content $env:GITHUB_OUTPUT)
            Assert ($outputs -contains ('name=DualPrint ' + ($tag -replace '^v', ''))) 'Incorrect release title.'
            Assert (-not ($outputs -match '^body_path=')) 'Missing notes must leave body_path unset.'
            Set-Content "docs/release-notes/$tag.md" 'Release note fixture'
            Set-Content $env:GITHUB_OUTPUT ''
            & $metadata
            Assert ((Get-Content $env:GITHUB_OUTPUT) -contains "body_path=docs/release-notes/$tag.md") 'Existing notes were not selected.'
        }
        Write-Host 'PASS: prefixed/unprefixed/non-numeric tags; present and absent release notes.'
    } finally { Pop-Location }
} finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) }
}
