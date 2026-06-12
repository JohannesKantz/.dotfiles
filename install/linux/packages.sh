#!/usr/bin/env bash
set -euo pipefail

packages=(bash bat btop curl fd-find fzf gh git jq neovim ripgrep stow tmux tree vim wget zsh)

# zoxide and mise are not in standard repos; install via their official scripts if missing:
#   zoxide:  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
#   mise:    curl https://mise.run | sh
#   yt-dlp:  pip3 install -U yt-dlp

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "${packages[@]}"
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --needed "${packages[@]}"
else
    printf 'Unsupported package manager. Install manually: %s\n' "${packages[*]}" >&2
    exit 1
fi
