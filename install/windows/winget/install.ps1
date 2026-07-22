$ErrorActionPreference = 'Stop'

## Install the baseline and personal package groups from this directory.
## Run from any working directory; package paths are based on this script.

$packageRoot = Join-Path $PSScriptRoot 'packages'
$wingetImportFiles = @('basic.json', 'personal.json') |
    ForEach-Object { Join-Path $packageRoot $_ }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is not installed. Install App Installer, then run this script again.'
}

$failedImports = @()
foreach ($importFile in $wingetImportFiles) {
    if (-not (Test-Path -LiteralPath $importFile -PathType Leaf)) {
        throw "Package list is missing: $importFile"
    }
    Write-Host "Installing packages from $importFile"
    & winget import --import-file $importFile --ignore-unavailable --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        $failedImports += "$importFile (exit code $LASTEXITCODE)"
    }
}

if ($failedImports.Count -gt 0) {
    throw "WinGet could not import: $($failedImports -join ', '). Review the output, fix the unavailable package or installer, then run setup.ps1 again."
}
