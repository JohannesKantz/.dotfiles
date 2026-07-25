[CmdletBinding()]
param(
    [switch]$ElevatedPhase,
    [switch]$Packages,
    [switch]$Link,
    [switch]$Zsh
)

$ErrorActionPreference = 'Stop'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-PathEntry {
    param([string]$PathEntry)

    if ((Test-Path -LiteralPath $PathEntry -PathType Container) -and
        ($env:Path -notlike "*$PathEntry*")) {
        $env:Path = "$PathEntry;$env:Path"
    }
}

function Add-UserPathEntry {
    param([Parameter(Mandatory)][string]$PathEntry)

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $userPathEntries = @($userPath -split ';' | Where-Object { $_ })
    if ($userPathEntries -notcontains $PathEntry) {
        $newUserPath = (@($PathEntry) + $userPathEntries) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
        Write-Host "Added $PathEntry to the user PATH."
    }

    Add-PathEntry $PathEntry
}

function Install-Scoop {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host 'Scoop already installed.'
        return
    }

    Write-Host 'Installing Scoop...'
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    $installer = Invoke-RestMethod -Uri 'https://get.scoop.sh'
    & ([ScriptBlock]::Create($installer))

    Add-PathEntry (Join-Path $HOME 'scoop\shims')
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw 'Scoop was installed but is not available in this PowerShell session.'
    }
}

function Get-ScoopRoot {
    if ($env:SCOOP) {
        return $env:SCOOP
    }

    return (Join-Path $HOME 'scoop')
}

function Test-ScoopAppInstalled {
    param([Parameter(Mandatory)][string]$Name)

    return Test-Path -LiteralPath (Join-Path (Get-ScoopRoot) "apps\$Name\current") -PathType Container
}

function Test-FontRegistered {
    param([Parameter(Mandatory)][string]$RegistryName)

    $registryPaths = @(
        'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    )

    foreach ($registryPath in $registryPaths) {
        $fonts = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
        if ($fonts -and $fonts.PSObject.Properties.Name -contains $RegistryName) {
            return $true
        }
    }

    return $false
}

function Install-NerdFonts {
    $bucketName = 'nerd-fonts'
    $fontPackages = @(
        @{ Name = 'CascadiaMono-NF-Mono';   RegistryName = 'CaskaydiaMonoNerdFontMono-Regular (TrueType)' }
        @{ Name = 'FiraCode-NF-Mono';       RegistryName = 'FiraCodeNerdFontMono-Regular (TrueType)' }
        @{ Name = 'JetBrainsMono-NF-Mono';  RegistryName = 'JetBrainsMonoNerdFontMono-Regular (TrueType)' }
        @{ Name = 'GeistMono-NF-Mono';      RegistryName = 'GeistMonoNerdFontMono-Regular (TrueType)' }
    )
    $bucketPath = Join-Path (Get-ScoopRoot) "buckets\$bucketName"

    if (-not (Test-Path -LiteralPath $bucketPath -PathType Container)) {
        & scoop bucket add $bucketName
        if ($LASTEXITCODE -ne 0) { throw "Could not add the Scoop $bucketName bucket (exit code $LASTEXITCODE)." }
    }

    foreach ($font in $fontPackages) {
        if ((Test-ScoopAppInstalled -Name $font.Name) -and
            (Test-FontRegistered -RegistryName $font.RegistryName)) {
            Write-Host "$($font.Name) already installed."
            continue
        }

        if (Test-ScoopAppInstalled -Name $font.Name) {
            Write-Host "Repairing $($font.Name)..."
            & scoop uninstall $font.Name
            if ($LASTEXITCODE -ne 0) { throw "$($font.Name) repair failed during uninstall (exit code $LASTEXITCODE)." }
        }

        & scoop install "$bucketName/$($font.Name)"
        if ($LASTEXITCODE -ne 0) { throw "$($font.Name) installation failed (exit code $LASTEXITCODE)." }
    }
}

function Invoke-ElevatedPhase {
    param(
        [switch]$Packages,
        [switch]$Link,
        [switch]$Zsh
    )

    $hostExecutable = (Get-Process -Id $PID).Path
    $phaseArguments = @('-ElevatedPhase')
    if ($Packages) { $phaseArguments += '-Packages' }
    if ($Link) { $phaseArguments += '-Link' }
    if ($Zsh) { $phaseArguments += '-Zsh' }
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($phaseArguments -join ' ')"
    $process = Start-Process -FilePath $hostExecutable -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "The elevated package/link/Zsh phase failed (exit code $($process.ExitCode))."
    }
}

if ($ElevatedPhase) {
    if (-not (Test-Administrator)) {
        throw 'The elevated phase requires Administrator approval.'
    }

    # Batch installers and file operations into one UAC-approved process.
    if ($Packages) {
        & (Join-Path $PSScriptRoot 'winget/install.ps1')
    }
    if ($Link) {
        & (Join-Path $PSScriptRoot 'manage.ps1') Link -Replace
    }
    if ($Zsh) {
        & (Join-Path $PSScriptRoot 'zsh/install-git-bash-zsh.ps1')
    }
    return
}

if (Test-Administrator) {
    throw 'Run setup.ps1 from a normal PowerShell window. It asks for elevation only when needed.'
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required. Install App Installer from the Microsoft Store, then run setup.ps1 again.'
}

Write-Host 'Setting up Windows...'

$wingetInstallScript = Join-Path $PSScriptRoot 'winget/install.ps1'
$packagesRequired = @(& $wingetInstallScript -Check) -contains $true

$linkStatus = @(& (Join-Path $PSScriptRoot 'manage.ps1') Status)
$linkRequired = @($linkStatus | Where-Object { $_.Mode -eq 'Link' -and $_.State -ne 'link current' }).Count -gt 0

$gitRoot = Join-Path $env:ProgramFiles 'Git'
$gitBashPath = Join-Path $gitRoot 'bin\bash.exe'
$zshRequired = if (Test-Path -LiteralPath $gitBashPath -PathType Leaf) {
    @(& (Join-Path $PSScriptRoot 'zsh/install-git-bash-zsh.ps1') -Check) -contains $true
}
else {
    # Git is part of the WinGet package list. Install it before adding Zsh.
    $true
}

if ($packagesRequired -or $linkRequired -or $zshRequired) {
    Invoke-ElevatedPhase `
        -Packages:$packagesRequired `
        -Link:$linkRequired `
        -Zsh:$zshRequired
}
else {
    Write-Host 'WinGet packages, links, and Git Bash Zsh already current; no elevation needed.'
}

# WinGet may have installed Git during this session, without updating this
# PowerShell process's PATH.
Add-PathEntry (Join-Path $env:ProgramFiles 'Git\cmd')

Install-Scoop
& scoop update
if ($LASTEXITCODE -ne 0) { throw "Scoop update failed (exit code $LASTEXITCODE)." }

Install-NerdFonts
Write-Host 'Restart Windows Terminal once if a newly installed font is not visible yet.'

if (-not (Test-ScoopAppInstalled -Name 'mise')) {
    if (Get-Command mise -ErrorAction SilentlyContinue) {
        throw 'Mise is already installed outside Scoop. Refusing to replace it; remove that installation or migrate it to Scoop first.'
    }
    & scoop install mise
    if ($LASTEXITCODE -ne 0) { throw "Mise installation failed (exit code $LASTEXITCODE)." }
}
else {
    Write-Host 'Mise already installed by Scoop.'
}

& scoop update mise
if ($LASTEXITCODE -ne 0) { throw "Mise update failed (exit code $LASTEXITCODE)." }

Add-PathEntry (Join-Path $HOME 'scoop\shims')
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    throw 'Mise was installed but is not available in this PowerShell session.'
}

# Install the global versions declared in windows/.config/mise/config.toml.
& mise install
if ($LASTEXITCODE -ne 0) { throw "Mise tool installation failed (exit code $LASTEXITCODE)." }

& mise reshim
if ($LASTEXITCODE -ne 0) { throw "Mise could not create its command shims (exit code $LASTEXITCODE)." }

Add-UserPathEntry (Join-Path $env:LOCALAPPDATA 'mise\shims')

# App settings replace differing values only; existing settings are backed up.
& (Join-Path $PSScriptRoot 'manage.ps1') Apply -Replace

# Disabled while these system-wide Windows settings are still work in progress.
# Re-enable only after the individual choices have been reviewed.
# & (Join-Path $PSScriptRoot 'settings/basicWindowsSettings.ps1')

Write-Host ''
Write-Host 'Windows setup complete. Open a new terminal, then start Git Bash.'
