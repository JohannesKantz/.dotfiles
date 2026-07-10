#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
    printf 'This setup script only targets Linux.\n' >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/../.." && pwd)"

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

as_root=()
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    as_root=(sudo)
fi

install_packages() {
    case "$package_manager" in
        apt)
            "${as_root[@]}" apt-get install -y "$@"
            ;;
        dnf)
            "${as_root[@]}" dnf install -y "$@"
            ;;
        pacman)
            "${as_root[@]}" pacman -S --needed --noconfirm "$@"
            ;;
    esac
}

install_extra_packages() {
    local package
    local failed_packages=()

    for package in "$@"; do
        if ! install_packages "$package"; then
            failed_packages+=("$package")
        fi
    done

    if ((${#failed_packages[@]})); then
        printf '\nSome extra packages were not available from this distro repo:\n' >&2
        printf '  %s\n' "${failed_packages[@]}" >&2
    fi
}

printf 'Setting up Linux\n\n'

if command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
    base_packages=(
        bash
        ca-certificates
        curl
        git
        neovim
        ripgrep
        stow
        tmux
        vim
        wget
        zsh
    )
    extra_packages=(
        bash-completion
        bat
        btop
        build-essential
        bun
        cloc
        cmake
        cmatrix
        default-jdk
        deno
        dnsutils
        fd-find
        fastfetch
        ffmpeg
        fzf
        gcc
        gh
        golang-go
        htop
        iperf3
        jq
        libimage-exiftool-perl
        llvm
        lua5.4
        luajit
        make
        mise
        neofetch
        nmap
        nodejs
        npm
        php-cli
        pkg-config
        protobuf-compiler
        python3
        python3-pip
        python3-venv
        rclone
        rustup
        smartmontools
        sqlite-utils
        sqlite3
        tldr
        tree
        unzip
        uv
        xz-utils
        yt-dlp
        zip
        zoxide
    )
    "${as_root[@]}" apt-get update
    install_packages "${base_packages[@]}"
    install_extra_packages "${extra_packages[@]}"
elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
    base_packages=(
        bash
        ca-certificates
        curl
        git
        neovim
        ripgrep
        stow
        tmux
        vim-enhanced
        wget
        zsh
    )
    extra_packages=(
        bash-completion
        bat
        bind-utils
        btop
        bun
        cloc
        cmake
        cmatrix
        deno
        fd-find
        fastfetch
        ffmpeg-free
        fzf
        gcc
        gcc-c++
        gh
        golang
        htop
        iperf3
        jq
        java-latest-openjdk-devel
        llvm
        lua
        luajit
        make
        mise
        neofetch
        nmap
        nodejs
        npm
        perl-Image-ExifTool
        php-cli
        pkgconf-pkg-config
        protobuf-compiler
        python3
        python3-pip
        python3-sqlite-utils
        rclone
        rustup
        smartmontools
        sqlite
        tldr
        tree
        unzip
        uv
        xz
        yt-dlp
        zip
        zoxide
    )
    install_packages "${base_packages[@]}"
    install_extra_packages "${extra_packages[@]}"
elif command -v pacman >/dev/null 2>&1; then
    package_manager=pacman
    base_packages=(
        bash
        ca-certificates
        curl
        git
        neovim
        ripgrep
        stow
        tmux
        vim
        wget
        zsh
    )
    extra_packages=(
        base-devel
        bat
        bind
        btop
        bun
        cloc
        cmake
        cmatrix
        deno
        fd
        fastfetch
        ffmpeg
        fzf
        gcc
        github-cli
        go
        htop
        iperf3
        jdk-openjdk
        jq
        llvm
        lua
        luajit
        mise
        neofetch
        nmap
        nodejs
        npm
        perl-image-exiftool
        php
        pkgconf
        protobuf
        python
        python-pip
        rclone
        rustup
        smartmontools
        sqlite
        sqlite-utils
        tealdeer
        tree
        unzip
        uv
        xz
        yt-dlp
        zip
        zoxide
    )
    "${as_root[@]}" pacman -Syu --noconfirm
    install_packages "${base_packages[@]}"
    install_extra_packages "${extra_packages[@]}"
else
    printf 'Unsupported package manager. Install packages manually.\n' >&2
    exit 1
fi

install -d -m 700 "$HOME/.ssh"
install -d -m 755 "$HOME/.config" "$HOME/.cache" "$HOME/.local/bin" "$HOME/dev"

# Debian-family packages expose these commands under different names.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

stow --dir "$repo_dir" --target "$HOME" --restow --verbose "${packages[@]}"

printf '\nLinux setup complete. Restart your shell.\n'
