[CmdletBinding()]
param(
    [switch]$ElevatedPhase,
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

function Invoke-ElevatedPhase {
    param(
        [switch]$Link,
        [switch]$Zsh
    )

    $hostExecutable = (Get-Process -Id $PID).Path
    $phaseArguments = @('-ElevatedPhase')
    if ($Link) { $phaseArguments += '-Link' }
    if ($Zsh) { $phaseArguments += '-Zsh' }
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($phaseArguments -join ' ')"
    $process = Start-Process -FilePath $hostExecutable -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "The elevated link/Zsh phase failed (exit code $($process.ExitCode))."
    }
}

if ($ElevatedPhase) {
    if (-not (Test-Administrator)) {
        throw 'The elevated phase requires Administrator approval.'
    }

    # File symlinks and the Zsh overlay in Program Files need elevation.
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

# All curated WinGet groups: basic, personal, development, and creative tools.
& (Join-Path $PSScriptRoot 'winget/install.ps1')

# WinGet may have installed Git during this session, without updating this
# PowerShell process's PATH.
Add-PathEntry (Join-Path $env:ProgramFiles 'Git\cmd')

Install-Scoop
& scoop update
if ($LASTEXITCODE -ne 0) { throw "Scoop update failed (exit code $LASTEXITCODE)." }

$scoopMisePath = & scoop prefix mise 2>$null
if ($LASTEXITCODE -ne 0) {
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

# Link shell/editor configuration before Mise reads its Windows global config.
# A status check avoids a UAC prompt when every link is already right.
$linkStatus = @(& (Join-Path $PSScriptRoot 'manage.ps1') Status)
$linkRequired = @($linkStatus | Where-Object { $_.Mode -eq 'Link' -and $_.State -ne 'link current' }).Count -gt 0

# Compare the actual Git for Windows files with the current verified MSYS2 Zsh
# package. This is read-only; an elevated process starts only if files differ.
$zshRequired = @(& (Join-Path $PSScriptRoot 'zsh/install-git-bash-zsh.ps1') -Check) -contains $true

if ($linkRequired -or $zshRequired) {
    Invoke-ElevatedPhase -Link:$linkRequired -Zsh:$zshRequired
}
else {
    Write-Host 'Links and Git Bash Zsh already current; no elevation needed.'
}

# Install the global versions declared in windows/.config/mise/config.toml.
& mise install
if ($LASTEXITCODE -ne 0) { throw "Mise tool installation failed (exit code $LASTEXITCODE)." }

# App settings replace differing values only; existing settings are backed up.
& (Join-Path $PSScriptRoot 'manage.ps1') Apply -Replace

# Disabled while these system-wide Windows settings are still work in progress.
# Re-enable only after the individual choices have been reviewed.
# & (Join-Path $PSScriptRoot 'settings/basicWindowsSettings.ps1')

Write-Host ''
Write-Host 'Windows setup complete. Open a new terminal, then start Git Bash.'
