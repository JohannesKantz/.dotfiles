[CmdletBinding(SupportsShouldProcess)]
param(
    # Git for Windows is the only shell environment this script changes.
    [string]$GitRoot = (Join-Path $env:ProgramFiles 'Git'),

    # Read and compare the current package without changing Git for Windows.
    # The caller receives $true only when an elevated install is necessary.
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-TarCommands {
    param([string]$GitRoot)

    $pathTar = (Get-Command tar.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Path
    $candidates = @(@(
        (Join-Path $env:SystemRoot 'System32\tar.exe')
        (Join-Path $GitRoot 'usr\bin\tar.exe')
        $pathTar
    ) | Where-Object {
        $_ -and (Test-Path -LiteralPath $_ -PathType Leaf)
    } | Select-Object -Unique)

    if ($candidates.Count -eq 0) {
        throw 'tar.exe was not found. Reinstall Git for Windows, then run this script again.'
    }

    return $candidates
}

function Get-DatabaseField {
    param(
        [string]$Metadata,
        [string]$Field
    )

    $lines = $Metadata -split "`r?`n"
    $index = [Array]::IndexOf($lines, "%$Field%")
    if ($index -lt 0 -or $index + 1 -ge $lines.Count) {
        return $null
    }

    return $lines[$index + 1]
}

function Get-LatestZshPackage {
    param(
        [string]$DatabasePath,
        [string[]]$TarCandidates
    )

    # msys.db is the package index consumed by Pacman itself. It contains the
    # current archive filename and SHA-256, without relying on web-page HTML.
    foreach ($tar in $TarCandidates) {
        $entries = @(& $tar -tf $DatabasePath 2>$null | Where-Object { $_ -like 'zsh-*/desc' })
        if ($LASTEXITCODE -ne 0 -or $entries.Count -eq 0) {
            continue
        }

        foreach ($entry in $entries) {
            $metadata = (& $tar -xOf $DatabasePath $entry) -join "`n"
            if ($LASTEXITCODE -ne 0) {
                throw 'Could not read Zsh metadata from the MSYS2 package index. Nothing was installed.'
            }

            if ((Get-DatabaseField -Metadata $metadata -Field 'NAME') -eq 'zsh') {
                $filename = Get-DatabaseField -Metadata $metadata -Field 'FILENAME'
                $sha256 = Get-DatabaseField -Metadata $metadata -Field 'SHA256SUM'
                if (-not $filename -or $filename -notmatch '^zsh-.+\.pkg\.tar\.zst$' -or $sha256 -notmatch '^[a-fA-F0-9]{64}$') {
                    throw 'The MSYS2 package index returned incomplete Zsh metadata. Nothing was installed.'
                }

                return [PSCustomObject]@{
                    Url = "https://mirror.msys2.org/msys/x86_64/$filename"
                    Sha256 = $sha256
                    Tar = $tar
                }
            }
        }
    }

    throw 'No available tar.exe could read the Zstandard-compressed MSYS2 package index. Nothing was installed.'
}

function Get-RelativePath {
    param(
        [string]$Root,
        [string]$Path
    )

    return $Path.Substring($Root.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

if ([Environment]::Is64BitOperatingSystem -eq $false) {
    throw 'This installer contains the x86_64 Zsh package and requires 64-bit Windows.'
}

if (-not (Test-Path -LiteralPath $GitRoot -PathType Container)) {
    throw "Git for Windows was not found at '$GitRoot'. Pass -GitRoot if it is installed elsewhere."
}

$GitRoot = (Resolve-Path -LiteralPath $GitRoot).Path
$bashPath = Join-Path $GitRoot 'bin\bash.exe'
if (-not (Test-Path -LiteralPath $bashPath -PathType Leaf)) {
    throw "'$GitRoot' is not a Git for Windows installation (bin\\bash.exe is missing)."
}

$zshPath = Join-Path $GitRoot 'usr\bin\zsh.exe'
$workRoot = Join-Path ([IO.Path]::GetTempPath()) ("dotfiles-git-bash-zsh-" + [guid]::NewGuid().ToString('N'))
$databasePath = Join-Path $workRoot 'msys.db'
$packagePath = Join-Path $workRoot 'zsh.pkg.tar.zst'
$extractRoot = Join-Path $workRoot 'extract'
$backupRoot = Join-Path $env:USERPROFILE (".dotfiles-backups\git-bash-zsh\" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))

try {
    New-Item -ItemType Directory -Path $workRoot, $extractRoot -Force | Out-Null

    $tarCandidates = @(Get-TarCommands -GitRoot $GitRoot)
    Write-Host 'Reading the current Zsh package from the MSYS2 package index...'
    Invoke-WebRequest -Uri 'https://repo.msys2.org/msys/x86_64/msys.db' -OutFile $databasePath
    $package = Get-LatestZshPackage -DatabasePath $databasePath -TarCandidates $tarCandidates
    $tar = $package.Tar
    Write-Host "Downloading $($package.Url)..."
    Invoke-WebRequest -Uri $package.Url -OutFile $packagePath

    $actualHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $package.Sha256.ToLowerInvariant()) {
        throw "Package checksum mismatch. Expected $($package.Sha256), received $actualHash. Nothing was installed."
    }

    & $tar -xf $packagePath -C $extractRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not unpack the Zsh package. Git for Windows must provide a tar.exe with Zstandard support.'
    }

    $sourceRoots = @(@('etc', 'usr') | ForEach-Object { Join-Path $extractRoot $_ } | Where-Object {
        Test-Path -LiteralPath $_ -PathType Container
    })
    if ($sourceRoots.Count -ne 2) {
        throw 'The package did not contain the expected etc and usr directories. Nothing was installed.'
    }

    $operations = foreach ($sourceRoot in $sourceRoots) {
        Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force | ForEach-Object {
            $relativePath = Get-RelativePath -Root $extractRoot -Path $_.FullName
            $destination = Join-Path $GitRoot $relativePath
            $exists = Test-Path -LiteralPath $destination -PathType Leaf
            $same = $false

            if ($exists) {
                $sourceHash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                $targetHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
                $same = $sourceHash -eq $targetHash
            }

            [PSCustomObject]@{
                Source = $_.FullName
                RelativePath = $relativePath
                Destination = $destination
                Exists = $exists
                Same = $same
            }
        }
    }

    $changes = @($operations | Where-Object { -not $_.Same })
    if ($changes.Count -eq 0) {
        Write-Host 'The latest Zsh version is already installed.'
        if ($Check) { return $false }
        return
    }

    if ($Check) {
        Write-Host "Zsh needs an update ($($changes.Count) files)."
        return $true
    }

    if ($GitRoot.StartsWith($env:ProgramFiles, [StringComparison]::OrdinalIgnoreCase) -and -not (Test-Administrator)) {
        throw 'Git for Windows is installed in Program Files. Run this script as Administrator.'
    }

    if (-not $PSCmdlet.ShouldProcess($GitRoot, "install Zsh ($($changes.Count) files)")) {
        return
    }

    $completed = [System.Collections.Generic.List[object]]::new()
    try {
        foreach ($change in $changes) {
            $destinationDirectory = Split-Path -Parent $change.Destination
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

            $backup = $null
            if ($change.Exists) {
                $backup = Join-Path $backupRoot $change.RelativePath
                New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
                Move-Item -LiteralPath $change.Destination -Destination $backup
            }

            $completed.Add([PSCustomObject]@{ Destination = $change.Destination; Backup = $backup })
            Copy-Item -LiteralPath $change.Source -Destination $change.Destination
        }

        $oldPath = $env:Path
        try {
            $env:Path = "$(Join-Path $GitRoot 'usr\bin');$env:Path"
            & $zshPath --version
            if ($LASTEXITCODE -ne 0) {
                throw "Zsh exited with code $LASTEXITCODE."
            }
        }
        finally {
            $env:Path = $oldPath
        }
    }
    catch {
        for ($index = $completed.Count - 1; $index -ge 0; $index--) {
            $entry = $completed[$index]
            Remove-Item -LiteralPath $entry.Destination -Force -ErrorAction SilentlyContinue
            if ($entry.Backup) {
                New-Item -ItemType Directory -Path (Split-Path -Parent $entry.Destination) -Force | Out-Null
                Move-Item -LiteralPath $entry.Backup -Destination $entry.Destination -Force
            }
        }
        throw
    }

    Write-Host 'Zsh was installed in Git for Windows.'
    Write-Host 'Run manage.ps1 Link once, then open Git Bash. Its .bash_profile will start Zsh automatically.'
    if (Test-Path -LiteralPath $backupRoot) {
        Write-Host "Replaced files were backed up to '$backupRoot'."
    }
}
finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}
