#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    printf 'Usage: %s [--dry-run]\n' "$0"
}

stow_options=()
dry_run=false
case "${1:-}" in
    "")
        ;;
    --dry-run)
        stow_options+=(--simulate)
        dry_run=true
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

if (($# > 1)); then
    usage >&2
    exit 2
fi

if ! command -v stow >/dev/null 2>&1; then
    printf 'GNU Stow is required. Install it, then run this command again.\n' >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/.." && pwd)"

case "$(uname -s)" in
    Darwin)
        packages=(
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
        ;;
    Linux)
        packages=(
            aliases
            agents
            bash
            bat
            btop
            curl
            fastfetch
            functions
            git
            linux
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
        ;;
    *)
        printf 'This command supports macOS and Linux. Use install/windows/manage.ps1 on Windows.\n' >&2
        exit 1
        ;;
esac

if [[ "$dry_run" == false ]]; then
    install -d -m 700 "$HOME/.ssh"
fi

stow \
    --dir "$repo_dir" \
    --target "$HOME" \
    --restow \
    --verbose \
    "${stow_options[@]}" \
    "${packages[@]}"
