#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This setup script only targets macOS.\n' >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/../.." && pwd)"

usage() {
    printf 'Usage: %s [--backup]\n' "${0##*/}"
    printf '\nInstall macOS packages, dotfiles, runtimes, and system settings.\n'
    printf '  --backup  Back up existing files that conflict with managed dotfiles.\n'
}

setup_failed() {
    local exit_code=$?

    trap - ERR
    printf '\nFAILED: macOS setup stopped with exit code %s.\n' "$exit_code" >&2
    printf 'Fix the error above, then run the same command again.\n' >&2
    exit "$exit_code"
}
trap setup_failed ERR

backup_conflicts=false
while (($#)); do
    case "$1" in
        --backup)
            backup_conflicts=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

printf 'Setting up macOS\n\n'

if ! xcode-select -p >/dev/null 2>&1; then
    printf 'Xcode Command Line Tools not found. Opening installer.\n'
    xcode-select --install || true
    printf 'Finish the Command Line Tools installation, then run this script again.\n'
    exit 0
fi

printf 'Xcode Command Line Tools already installed.\n'

printf 'Requesting administrator access once for the complete setup.\n'
sudo -v
while true; do
    sudo -n true || exit
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &
sudo_keepalive_pid="$!"
trap 'kill "$sudo_keepalive_pid" 2>/dev/null || true' EXIT

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

if ! command -v stow >/dev/null 2>&1; then
    printf 'Installing GNU Stow for dotfile linking.\n'
    brew install stow
fi

if [[ "$backup_conflicts" == true ]]; then
    "$repo_dir/install/link.sh" --backup
else
    "$repo_dir/install/link.sh"
fi

"$script_dir/packages.sh"

mise install

"$script_dir/system-settings.sh"

printf '\nSUCCESS: macOS setup completed.\n'
printf 'Restart your shell or reboot the machine.\n'
