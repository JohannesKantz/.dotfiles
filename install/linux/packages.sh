#!/usr/bin/env bash
set -euo pipefail

packages=(bash curl git stow vim zsh)

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

