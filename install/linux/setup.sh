#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/../.." && pwd)"

usage() {
    printf 'Usage: %s [--extras] [--backup]\n' "${0##*/}"
    printf '\nInstall base Linux packages and dotfiles.\n'
    printf '  --extras  Also install optional development and CLI packages.\n'
    printf '  --backup  Back up existing files that conflict with managed dotfiles.\n'
}

install_extras=false
backup_conflicts=false
while (($#)); do
    case "$1" in
        --extras)
            install_extras=true
            ;;
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

if [[ "$(uname -s)" != "Linux" ]]; then
    printf 'This setup script only targets Linux.\n' >&2
    exit 1
fi

packages=(
    aliases
    agents
    bash
    bat
    btop
    curl
    functions
    git
    linux
    mise
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
            # Avoid debconf prompts (for example, iperf3's optional daemon).
            # This setup installs command-line tools only; services are started
            # explicitly when needed.
            "${as_root[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
            ;;
        dnf)
            "${as_root[@]}" dnf install -y "$@"
            ;;
        pacman)
            "${as_root[@]}" pacman -S --needed --noconfirm "$@"
            ;;
    esac
}

apt_package_available() {
    apt-cache show "$1" >/dev/null 2>&1
}

select_apt_fetch_package() {
    # neofetch was removed from current Debian repositories.  Older Debian and
    # Ubuntu releases may not carry fastfetch yet, so retain a safe fallback.
    if apt_package_available fastfetch; then
        base_packages+=(fastfetch)
        packages+=(fastfetch)
    elif apt_package_available neofetch; then
        base_packages+=(neofetch)
        packages+=(neofetch)
    else
        printf 'Neither fastfetch nor neofetch is available from the configured APT repositories. Skipping system-info tool.\n' >&2
    fi
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

install_mise() {
    if command -v mise >/dev/null 2>&1; then
        return
    fi

    printf 'Installing mise from mise.run\n'
    curl -fsSL https://mise.run | sh

    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v mise >/dev/null 2>&1; then
        printf 'mise was installed but is not available on PATH.\n' >&2
        exit 1
    fi
}

set_zsh_as_default_shell() {
    local zsh_path
    local current_shell

    zsh_path="$(command -v zsh)"
    current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"

    if [[ "$current_shell" == "$zsh_path" ]]; then
        printf 'Zsh is already the default shell.\n'
        return
    fi

    if ! grep -Fqx "$zsh_path" /etc/shells; then
        printf 'Zsh (%s) is not listed in /etc/shells. Cannot set it as the default shell.\n' "$zsh_path" >&2
        return 1
    fi

    printf 'Setting Zsh as the default shell for %s\n' "$(id -un)"
    chsh -s "$zsh_path"
}

printf 'Setting up Linux\n\n'

if command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
    base_packages=(
        bash
        bash-completion
        bat
        btop
        ca-certificates
        curl
        bind9-dnsutils
        fd-find
        fzf
        gh
        git
        htop
        iperf3
        jq
        libimage-exiftool-perl
        lsof
        neovim
        nmap
        ripgrep
        smartmontools
        sqlite-utils
        sqlite3
        stow
        tealdeer
        tmux
        tree
        unzip
        vim
        wget
        xz-utils
        yt-dlp
        zip
        zoxide
        zsh
    )
    extra_packages=(
        build-essential
        cloc
        cmake
        cmatrix
        ffmpeg
        llvm
        lua5.4
        luajit
        php-cli
        pkg-config
        protobuf-compiler
        rclone
    )
    "${as_root[@]}" apt-get update
    select_apt_fetch_package
    install_packages "${base_packages[@]}"
elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
    base_packages=(
        bash
        bash-completion
        bat
        bind-utils
        btop
        ca-certificates
        curl
        fd-find
        fastfetch
        fzf
        gh
        git
        htop
        iperf3
        jq
        lsof
        neovim
        nmap
        perl-Image-ExifTool
        ripgrep
        smartmontools
        sqlite
        stow
        tldr
        tmux
        tree
        unzip
        vim-enhanced
        wget
        xz
        yt-dlp
        zip
        zoxide
        zsh
    )
    extra_packages=(
        cloc
        cmake
        cmatrix
        ffmpeg-free
        gcc
        gcc-c++
        llvm
        lua
        luajit
        make
        php-cli
        pkgconf-pkg-config
        protobuf-compiler
        python3-sqlite-utils
        rclone
    )
    packages+=(fastfetch)
    install_packages "${base_packages[@]}"
elif command -v pacman >/dev/null 2>&1; then
    package_manager=pacman
    base_packages=(
        bash
        bat
        bind
        btop
        ca-certificates
        curl
        fd
        fastfetch
        fzf
        git
        github-cli
        htop
        iperf3
        jq
        lsof
        neovim
        nmap
        perl-image-exiftool
        ripgrep
        smartmontools
        sqlite
        sqlite-utils
        stow
        tealdeer
        tmux
        tree
        unzip
        vim
        wget
        xz
        yt-dlp
        zip
        zoxide
        zsh
    )
    extra_packages=(
        base-devel
        cloc
        cmake
        cmatrix
        ffmpeg
        gcc
        llvm
        lua
        luajit
        php
        pkgconf
        protobuf
        rclone
    )
    packages+=(fastfetch)
    "${as_root[@]}" pacman -Syu --noconfirm
    install_packages "${base_packages[@]}"
else
    printf 'Unsupported package manager. Install packages manually.\n' >&2
    exit 1
fi

if [[ "$install_extras" == true ]]; then
    install_extra_packages "${extra_packages[@]}"
else
    printf 'Skipping optional packages (rerun with --extras to install them).\n'
fi

install -d -m 700 "$HOME/.ssh"
install -d -m 755 "$HOME/.config" "$HOME/.cache" "$HOME/.local/bin" "$HOME/dev"

# mise is not available in every distribution repository (including the default
# Debian/Ubuntu repositories), so install it from its official installer.
install_mise

# Debian-family packages expose these commands under different names.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

if [[ "$backup_conflicts" == true ]]; then
    "$repo_dir/install/backup-conflicts.sh" \
        "$repo_dir" \
        "$HOME" \
        "${packages[@]}"
fi

stow --dir "$repo_dir" --target "$HOME" --restow --verbose "${packages[@]}"

set_zsh_as_default_shell

# Install the runtimes declared in the now-linked global Mise configuration.
mise install

printf '\nLinux setup complete. Restart your shell.\n'
