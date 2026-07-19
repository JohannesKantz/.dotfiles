# Windows

`windows/` mirrors paths below the Windows home directory and can be used with
Stow from WSL. On a new machine run:

```powershell
.\install\windows\setup.ps1
```

It runs as your normal user, installs all WinGet groups, Scoop, Mise and the
Windows Mise tools, then asks for elevation only when links or Zsh actually
need changing. It applies app settings only when their contents differ.
System-wide Windows settings and WSL setup are currently not part of this
script.

`manage.ps1` remains the native-Windows alternative for the entries listed in
`links.psd1`; use it later to inspect or repair individual links/settings.

## Windows Terminal

The profiles and shortcuts are deliberately fixed, rather than generated from
installed shells: Git Bash, PowerShell, elevated PowerShell, Command Prompt,
then Ubuntu. They are `Ctrl+Shift+1` through `Ctrl+Shift+5` in that order.
Ubuntu is visible before WSL is installed; it starts working as soon as the
Ubuntu distribution exists. Debian and old Visual Studio profiles stay removed.

## Git Bash with Zsh

Run these commands in an elevated PowerShell 7 window:

```powershell
.\install\windows\manage.ps1 Link
.\install\windows\zsh\install-git-bash-zsh.ps1
```

The installer reads the current Zsh package and SHA-256 checksum from the
official MSYS2 package index, then copies only its `etc` and `usr` files into
Git for Windows. Replaced Zsh files are backed up below
`$HOME\.dotfiles-backups\git-bash-zsh`. Start Git Bash afterwards:
`.bash_profile` starts Zsh, otherwise it falls back to Bash.

The current `.zshrc` uses Antidote and already declares syntax highlighting and
autosuggestions. Do not install the old, separate Oh-My-Zsh configuration as
well.
