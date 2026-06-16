# dotfiles

## New Machine

```bash
git clone <repository-url> ~/.dotfiles
cd ~/.dotfiles
```

Install packages:

```bash
# macOS. Install Homebrew first if it is missing: https://brew.sh
./install/macos/packages.sh

# Linux
./install/linux/packages.sh
```

Create the private SSH directory before linking. This prevents Stow from
linking the entire directory into the repository.

```bash
install -d -m 700 "$HOME/.ssh"
```

Preview and link files:

```bash
# macOS
stow -n -v -t "$HOME" aliases bash bat btop curl fastfetch functions ghostty git kitty macos mise neofetch nvim ripgrep ssh tmux vim wget zsh
stow -v -t "$HOME" aliases bash bat btop curl fastfetch functions ghostty git kitty macos mise neofetch nvim ripgrep ssh tmux vim wget zsh

# Linux
stow -n -v -t "$HOME" aliases bash bat btop curl fastfetch functions ghostty git kitty linux mise neofetch nvim ripgrep ssh tmux vim wget zsh
stow -v -t "$HOME" aliases bash bat btop curl fastfetch functions ghostty git kitty linux mise neofetch nvim ripgrep ssh tmux vim wget zsh
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

## Neovim

The Neovim package uses [LazyVim](https://www.lazyvim.org/) and requires Neovim
0.11.2 or newer. Plugins install automatically the first time Neovim starts.

```text
:Lazy         Manage and update plugins
:LazyExtras   Enable language and editor features
:LazyHealth   Check the installation
:Mason        Manage language servers and tools
```

Personal overrides live in `nvim/.config/nvim/lua/config/`. Add or override
plugins in `nvim/.config/nvim/lua/plugins/custom.lua`. Commit `lazy-lock.json`
after updating plugins.

Language support is enabled through LazyVim extras in
`nvim/.config/nvim/lua/config/lazy.lua`. The current extras cover C/C++, Docker,
Git, Go, JSON, Markdown, Python, Rust, Tailwind CSS, TOML, TypeScript, and YAML,
plus Prettier, ESLint, testing, and debugging. Use `:LazyExtras` to discover
additional maintained integrations.

## SSH

The tracked SSH client configuration keeps OpenSSH's authentication and
security defaults, hashes hostnames in `known_hosts`, and detects dead
connections. Put private hosts and machine-specific settings in
`~/.ssh/config.local`; that file is intentionally ignored.

```sshconfig
Host example
    HostName example.com
    User username
```

Keep the private file readable only by your user:

```bash
chmod 600 "$HOME/.ssh/config.local"
```

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
aliases/ bash/ bat/ btop/ curl/ fastfetch/ functions/ ghostty/ git/ kitty/ mise/ neofetch/ nvim/ ripgrep/ ssh/ tmux/ vim/ wget/ zsh/
    Shared macOS and Linux Stow packages

macos/ linux/
    Platform-specific Stow packages

install/
    Package lists and setup scripts. Do not pass this folder to Stow.
```
