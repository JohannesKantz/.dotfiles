#!/usr/bin/env bash
set -euo pipefail

common_packages=(bash bat btop curl fzf git jq neovim ripgrep stow tmux tree vim wget zoxide zsh)

# mise is not in standard repos; install via its official script if missing:
#   mise:    curl https://mise.run | sh
#   yt-dlp:  pip3 install -U yt-dlp

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "${common_packages[@]}" fd-find gh
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "${common_packages[@]}" fd-find gh
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --needed "${common_packages[@]}" fd github-cli
else
    printf 'Unsupported package manager. Install manually: %s\n' "${common_packages[*]}" >&2
    exit 1
fi
