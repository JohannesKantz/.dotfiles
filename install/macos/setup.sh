#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This setup script only targets macOS.\n' >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/../.." && pwd)"

stow_packages=(
    aliases
    agents
    bash
    bat
    btop
    curl
    fastfetch
    functions
    ghostty
    git
    kitty
    macos
    mise
    neofetch
    nvim
    ripgrep
    ssh
    tmux
    vim
    wget
    zsh
)

printf 'Setting up macOS\n\n'

if ! xcode-select -p >/dev/null 2>&1; then
    printf 'Xcode Command Line Tools not found. Opening installer.\n'
    xcode-select --install || true
    printf 'Finish the Command Line Tools installation, then run this script again.\n'
    exit 0
fi

printf 'Xcode Command Line Tools already installed.\n'

if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew not found. Installing Homebrew.\n'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew installation finished, but brew is still not on PATH.\n' >&2
    exit 1
fi

brew update
"$script_dir/packages.sh"
brew cleanup

install -d -m 700 "$HOME/.ssh"
mkdir -p "$HOME/dev"

stow --dir "$repo_dir" --target "$HOME" --restow --verbose "${stow_packages[@]}"

"$script_dir/system-settings.sh"

printf '\nmacOS setup complete. Restart your shell or reboot the machine.\n'
