#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is required: https://brew.sh/\n' >&2
    exit 1
fi

brew bundle --file "$script_dir/Brewfile"

