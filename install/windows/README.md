# Windows

`windows/` mirrors paths below the Windows home directory and can be used with
Stow from WSL. On a new machine run:

```powershell
.\install\windows\setup.ps1
```

It runs as your normal user, installs the basic and personal WinGet groups,
Scoop, Mise and the Windows Mise tools, then asks for elevation only when links
or Zsh actually need changing. It applies app settings only when their contents
differ.
System-wide Windows settings and WSL setup are currently not part of this
script.

`manage.ps1` remains the native-Windows alternative for the entries listed in
`links.psd1`; use it later to inspect or repair individual links/settings.

## Windows Terminal

Git Bash, PowerShell, elevated PowerShell and Command Prompt are fixed profiles.
Installed WSL distributions are discovered automatically. Current WSL versions
supply `Microsoft.WSL` profile fragments containing their launch commands and
icons; Terminal's built-in `Windows.Terminal.Wsl` discovery remains enabled as
a fallback for installations without those fragments. No machine-specific WSL
GUID is stored here; `Ctrl+Shift+5` targets the stable profile name `Ubuntu`
instead. The shortcuts are `Ctrl+Shift+1` through `Ctrl+Shift+5` in order.

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

Git Bash uses `windows/.zshrc` and the native Windows Mise shims. WSL, Linux and
macOS keep using `zsh/.zshrc` with normal `mise activate zsh`. PowerShell keeps
using `mise activate pwsh`.
