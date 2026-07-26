# dotfiles

Personal shell, editor, terminal, and operating-system configuration.

## Clone

```bash
git clone https://github.com/JohannesKantz/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

## Dotfiles Only

Use this on an existing machine when you do not want to install packages or
change system settings.

### macOS / Linux

[GNU Stow](https://www.gnu.org/software/stow/) must already be installed.

```bash
# Preview first
./install/link.sh --dry-run

# Back up conflicting files, then create the links
./install/link.sh --backup

# Create or refresh the links
./install/link.sh
```

Existing regular files are not overwritten. Stow reports them as conflicts so
you can compare them first. `--backup` moves only conflicting managed paths to
`~/.dotfiles-backups/<timestamp>` before linking. If `~/.ssh/config` exists,
preserve it as `~/.ssh/config.local` before using `--backup`.

### Windows

Check what would change:

```powershell
.\install\windows\manage.ps1 Status
```

Then open PowerShell as Administrator and link the dotfiles:

```powershell
.\install\windows\manage.ps1 Link -Replace
```

Existing files are backed up below `$HOME\.dotfiles-backups`.

App settings are optional and copied rather than linked:

```powershell
.\install\windows\manage.ps1 Apply -Replace
```

This covers Windows Terminal, PowerToys, and WinGet settings.

## Full Setup

Use these only when you also want the packages and platform setup.

```bash
# macOS: Homebrew packages, links, and system settings
./install/macos/setup.sh

# First run on a Mac with existing dotfiles
./install/macos/setup.sh --backup

# Linux: system packages, links, Mise runtimes, and official agent installers
./install/linux/setup.sh

# First run on Linux with existing dotfiles
./install/linux/setup.sh --backup

# Include optional development and CLI packages
./install/linux/setup.sh --extras
```

Run the Windows setup from a normal, non-administrator PowerShell window. It
requests elevation only when needed and groups the elevated work into one UAC
prompt:

```powershell
.\install\windows\setup.ps1
```

If Windows blocks PowerShell scripts, start this run with a process-only
override:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install\windows\setup.ps1
```

## Update

```bash
cd ~/.dotfiles
git status --short
git pull --rebase
```

Linked files update immediately. Run `./install/link.sh` again after adding,
moving, or deleting paths. On Windows, copied app settings require `Apply`
again.

Changes made through a linked file, such as `~/.zshrc`, are changes inside this
repository:

```bash
git status
git add -A
git commit -m "update dotfiles"
git pull --rebase
git push
```

## Notes

- Zsh plugins are declared in `~/.zsh_plugins.txt` and installed by Antidote.
- Neovim uses LazyVim and requires Neovim 0.11.2 or newer.
- Put private SSH hosts in `~/.ssh/config.local`; it is intentionally ignored.
- Each top-level package mirrors its path below `$HOME`, for example
  `zsh/.zshrc` becomes `~/.zshrc`.
