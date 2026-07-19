#requires -Version 5.1
<#
Manage the explicit source-to-target mappings in links.psd1.

Status changes nothing. Link only creates missing links. Apply only copies
copy-managed settings; use -Replace to back up an existing target first.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Status', 'Link', 'Apply')]
    [string]$Action = 'Status',

    [string[]]$Name,
    [switch]$Replace
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'links.psd1')
$roots = @{ Home = $HOME; LocalAppData = $env:LOCALAPPDATA }
$backupRoot = Join-Path $HOME ('.dotfiles-backups/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))

function Get-Paths($entry) {
    if (-not $roots.ContainsKey($entry.TargetRoot)) { throw "Unknown TargetRoot: $($entry.TargetRoot)" }
    @{
        Source = [IO.Path]::GetFullPath((Join-Path $repoRoot $entry.Source))
        Target = [IO.Path]::GetFullPath((Join-Path $roots[$entry.TargetRoot] $entry.Target))
    }
}

function Get-Entries {
    if (-not $Name) { return @($manifest.Entries) }
    $entries = @($manifest.Entries | Where-Object { $Name -contains $_.Name })
    if ($entries.Count -ne $Name.Count) { throw 'Unknown entry name. Run: .\manage.ps1 Status' }
    return $entries
}

function Get-TargetItem {
    param([string]$Target)

    # Get-Item -Force also finds a dangling symbolic link, whereas Test-Path
    # returns $false for it. A dangling link must be repaired, not recreated
    # on top of itself.
    return Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
}

function Get-NormalizedPath {
    param([string]$Path)

    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Test-ExpectedLink {
    param(
        $Item,
        [string]$Source,
        [string]$Target
    )

    if (-not $Item -or -not $Item.LinkType) { return $false }

    $expected = Get-NormalizedPath $Source
    $targetDirectory = Split-Path -Parent $Target
    foreach ($linkTarget in @($Item.Target)) {
        if (-not $linkTarget) { continue }
        $candidate = [string]$linkTarget
        if (-not [IO.Path]::IsPathRooted($candidate)) {
            $candidate = Join-Path $targetDirectory $candidate
        }
        if ((Get-NormalizedPath $candidate) -eq $expected) { return $true }
    }

    return $false
}

function Test-SameFileContent {
    param(
        $Entry,
        [string]$Source,
        [string]$Target
    )

    $targetItem = Get-TargetItem $Target
    if (-not $targetItem -or $targetItem.PSIsContainer -or $targetItem.LinkType) { return $false }

    $ignoredProperties = @($Entry.IgnoreProperties)
    if ($ignoredProperties.Count -gt 0) {
        try {
            $sourceObject = Get-Content -LiteralPath $Source -Raw | ConvertFrom-Json
            $targetObject = Get-Content -LiteralPath $Target -Raw | ConvertFrom-Json
            foreach ($property in $ignoredProperties) {
                $sourceObject.PSObject.Properties.Remove($property)
                $targetObject.PSObject.Properties.Remove($property)
            }
            return (($sourceObject | ConvertTo-Json -Depth 100 -Compress) -eq ($targetObject | ConvertTo-Json -Depth 100 -Compress))
        }
        catch {
            throw "[$($Entry.Name)] could not compare JSON settings: $($_.Exception.Message)"
        }
    }

    $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
    return $sourceHash -eq $targetHash
}

function Backup-Target($entry, $target) {
    $backup = Join-Path $backupRoot $entry.Target
    $parent = Split-Path -Parent $backup
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Move-Item -LiteralPath $target -Destination $backup
    Write-Host "[$($entry.Name)] existing target moved to $backup"
    return $backup
}

function Restore-Target($entry, $target, $backup) {
    $currentItem = Get-TargetItem $target
    if ($currentItem) {
        Remove-Item -LiteralPath $target -Force -ErrorAction Stop
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Move-Item -LiteralPath $backup -Destination $target -ErrorAction Stop
    Write-Warning "[$($entry.Name)] failed change rolled back; the original target was restored."
}

foreach ($entry in (Get-Entries)) {
    $paths = Get-Paths $entry
    $source = $paths.Source
    $target = $paths.Target

    if ($Action -eq 'Status') {
        $item = Get-TargetItem $target
        $state = if (-not (Test-Path -LiteralPath $source)) { 'source missing' }
        elseif (-not $item) { 'target missing' }
        elseif ($entry.Mode -eq 'Link' -and (Test-ExpectedLink -Item $item -Source $source -Target $target)) { 'link current' }
        elseif ($entry.Mode -eq 'Link' -and $item.LinkType) { 'link points elsewhere' }
        elseif ($entry.Mode -eq 'Copy' -and (Test-SameFileContent -Entry $entry -Source $source -Target $target)) { 'copy current' }
        else { 'target differs' }
        [pscustomobject]@{ Name = $entry.Name; Mode = $entry.Mode; State = $state; Source = $source; Target = $target }
        continue
    }

    if (-not (Test-Path -LiteralPath $source)) { throw "[$($entry.Name)] source missing: $source" }

    if ($Action -eq 'Link') {
        if ($entry.Mode -ne 'Link') { Write-Warning "[$($entry.Name)] is Copy mode; use Apply."; continue }
        $item = Get-TargetItem $target
        $backup = $null
        if ($item) {
            if (Test-ExpectedLink -Item $item -Source $source -Target $target) { Write-Host "[$($entry.Name)] link already current"; continue }
            if (-not $Replace) { Write-Warning "[$($entry.Name)] target exists; unchanged. Use -Replace only after checking it."; continue }
            $backup = Backup-Target $entry $target
        }
        try {
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            New-Item -ItemType SymbolicLink -Path $target -Value $source | Out-Null
        }
        catch {
            if ($backup) { Restore-Target $entry $target $backup }
            throw
        }
        Write-Host "[$($entry.Name)] linked"
        continue
    }

    if ($Action -eq 'Apply') {
        if ($entry.Mode -ne 'Copy') { Write-Warning "[$($entry.Name)] is Link mode; use Link."; continue }
        $item = Get-TargetItem $target
        if ($item -and (Test-SameFileContent -Entry $entry -Source $source -Target $target)) {
            Write-Host "[$($entry.Name)] copy already current"
            continue
        }
        $backup = $null
        if ($item) {
            if (-not $Replace) { Write-Warning "[$($entry.Name)] target exists; unchanged. Use -Replace only after checking it."; continue }
            $backup = Backup-Target $entry $target
        }
        try {
            New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $target
        }
        catch {
            if ($backup) { Restore-Target $entry $target $backup }
            throw
        }
        Write-Host "[$($entry.Name)] copied"
    }
}
