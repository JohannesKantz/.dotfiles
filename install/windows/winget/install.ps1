[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
if (Test-Path Variable:\PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is not installed. Install App Installer, then run this script again.'
}

$wingetOptions = @(
    '--exact'
    '--silent'
    '--accept-source-agreements'
    '--accept-package-agreements'
    '--disable-interactivity'
)
$failedPackages = @()
$failedRequiredPackages = @()
$changesRequired = $false

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)

    & winget list --id $Id --exact --accept-source-agreements *> $null
    return $LASTEXITCODE -eq 0
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$InstallerArguments,
        [switch]$Force,
        [switch]$Required
    )

    if (-not $Force -and (Test-WingetPackageInstalled -Id $Id)) {
        Write-Host "$Id already installed."
        return
    }

    if ($Check) {
        $action = if ($Force) { 'reconfigure' } else { 'install' }
        Write-Host "Would $action $Id."
        $script:changesRequired = $true
        return
    }

    Write-Host "Installing $Id..."
    $arguments = @('install', '--id', $Id) + $script:wingetOptions
    if ($InstallerArguments) {
        $arguments += @('--override', $InstallerArguments)
    }
    if ($Force) {
        $arguments += '--force'
    }

    & winget @arguments
    if ($LASTEXITCODE -ne 0) {
        $failure = "$Id (exit code $LASTEXITCODE)"
        if ($Required) {
            $script:failedRequiredPackages += $failure
        }
        else {
            $script:failedPackages += $failure
        }
    }
}

function Test-VSCodeInstallerTasks {
    $requiredTasks = @(
        'addcontextmenufiles'
        'addcontextmenufolders'
        'associatewithfiles'
        'addtopath'
    )
    $uninstallRoots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $selectedTasks = Get-ItemProperty -Path $uninstallRoots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'Microsoft Visual Studio Code*' } |
        ForEach-Object { $_.'Inno Setup: Selected Tasks' } |
        Where-Object { $_ } |
        Select-Object -First 1

    if (-not $selectedTasks) {
        return $false
    }

    $selectedTaskNames = @($selectedTasks -split ',')
    return @($requiredTasks | Where-Object { $selectedTaskNames -notcontains $_ }).Count -eq 0
}

# Browsers and media
Install-WingetPackage 'Google.Chrome'
Install-WingetPackage 'Mozilla.Firefox'
Install-WingetPackage 'VideoLAN.VLC'

# Personal apps
# Install-WingetPackage 'Brave.Brave'
# Install-WingetPackage 'RARLab.WinRAR'
Install-WingetPackage 'Spotify.Spotify'
Install-WingetPackage 'Discord.Discord'
# Install-WingetPackage 'TeamSpeakSystems.TeamSpeakClient'
Install-WingetPackage 'AgileBits.1Password'
# Install-WingetPackage 'Figma.Figma'

# Developer tools
Install-WingetPackage 'Git.Git' -Required
Install-WingetPackage 'GitHub.cli'
Install-WingetPackage 'Gyan.FFmpeg'
Install-WingetPackage 'GnuWin32.Grep'
Install-WingetPackage 'GnuWin32.Tree'
Install-WingetPackage 'GnuWin32.Zip'
Install-WingetPackage 'GnuWin32.Tar'
Install-WingetPackage 'GnuWin32.UnZip'
Install-WingetPackage 'GnuWin32.Make'
Install-WingetPackage 'Kitware.CMake'
Install-WingetPackage 'Insecure.Nmap'
Install-WingetPackage 'Neovim.Neovim'
# Install-WingetPackage 'Docker.DockerDesktop'
Install-WingetPackage 'Microsoft.WindowsTerminal'
Install-WingetPackage 'Microsoft.PowerShell'
Install-WingetPackage 'Microsoft.PowerToys'
Install-WingetPackage 'GoLang.Go'

# VS Code needs installer tasks that cannot be represented by a WinGet package list.
$vsCodeInstalled = Test-WingetPackageInstalled -Id 'Microsoft.VisualStudioCode'
$vsCodeConfigured = $vsCodeInstalled -and (Test-VSCodeInstallerTasks)
$vsCodeInstallerArguments = '/VERYSILENT /SP- /SUPPRESSMSGBOXES /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
Install-WingetPackage 'Microsoft.VisualStudioCode' `
    -InstallerArguments $vsCodeInstallerArguments `
    -Force:($vsCodeInstalled -and -not $vsCodeConfigured)

# Optional apps: uncomment the lines you want.
# Install-WingetPackage 'TablePlus.TablePlus'
# Install-WingetPackage 'Amazon.AWSCLI'
# Install-WingetPackage 'Microsoft.AzureCLI'
# Install-WingetPackage 'GIMP.GIMP'
# Install-WingetPackage 'Inkscape.Inkscape'
# Install-WingetPackage 'HandBrake.HandBrake'
# Install-WingetPackage 'OBSProject.OBSStudio'
# Install-WingetPackage 'BlenderFoundation.Blender'

if ($failedPackages.Count -gt 0) {
    Write-Warning "WinGet could not install these non-critical packages: $($failedPackages -join ', '). Setup will continue."
}

if ($failedRequiredPackages.Count -gt 0) {
    throw "WinGet could not install required packages: $($failedRequiredPackages -join ', ')."
}

if ($Check) {
    return $changesRequired
}
