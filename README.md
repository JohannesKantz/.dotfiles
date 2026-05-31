# dotfiles

## New Machine

```bash
git clone <repository-url> ~/.dotfiles
cd ~/.dotfiles
```

Install Stow:

```bash
# macOS
brew install stow

# Debian / Ubuntu
sudo apt install stow
```

Preview and link files:

```bash
# macOS
stow -n -v -t "$HOME" aliases bash functions ghostty git kitty macos neofetch vim zsh
stow -v -t "$HOME" aliases bash functions ghostty git kitty macos neofetch vim zsh

# Linux
stow -n -v -t "$HOME" aliases bash functions ghostty git kitty linux neofetch vim zsh
stow -v -t "$HOME" aliases bash functions ghostty git kitty linux neofetch vim zsh
```

`-n` previews changes. Remove it after checking the output. Existing files must
be moved or deleted before Stow can create links.

## Sync Changes

```bash
cd ~/.dotfiles
git pull --rebase

# Run the relevant Stow command again after adding, moving, or deleting files.
git status
git add -A
git commit -m "update dotfiles"
git push
```

Edit linked files normally:

```bash
vim ~/.zshrc
```

## Zsh Plugins

```bash
antidote install <user/repository>
antidote list
antidote update
```

Plugins are listed in `~/.zsh_plugins.txt`. Antidote installs itself when Zsh
starts for the first time.

## Add A Dotfile

The first directory is the Stow package. Everything below it is the path inside
`$HOME`.

```text
~/.dotfiles/zsh/.zshrc
              -> ~/.zshrc

~/.dotfiles/ghostty/.config/ghostty/config
                 -> ~/.config/ghostty/config
```

Example: add `~/.tmux.conf`.

```bash
mkdir -p ~/.dotfiles/tmux
mv ~/.tmux.conf ~/.dotfiles/tmux/.tmux.conf

cd ~/.dotfiles
stow -n -v -t "$HOME" tmux
stow -v -t "$HOME" tmux

git add tmux
git commit -m "add tmux config"
git push
```

## Remove A Package

```bash
cd ~/.dotfiles
stow -D -v -t "$HOME" tmux
```

## Folders

```text
aliases/ functions/ bash/ ghostty/ git/ kitty/ neofetch/ vim/ zsh/
    Shared macOS and Linux Stow packages

macos/ linux/
    Platform-specific Stow packages

install/
    Package lists and setup scripts. Do not pass this folder to Stow.
```
