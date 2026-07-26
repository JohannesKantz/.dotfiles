#!/usr/bin/env bash
set -Eeo pipefail

usage() {
    printf 'Usage: %s <repo-dir> <target-dir> <package> [package ...]\n' "${0##*/}"
}

if (($# < 3)); then
    usage >&2
    exit 2
fi

repo_dir="$1"
target_dir="$2"
shift 2
packages=("$@")

conflict_paths=()

add_conflict() {
    local relative_path="$1"
    local existing

    for existing in "${conflict_paths[@]}"; do
        [[ "$existing" == "$relative_path" ]] && return
    done

    conflict_paths+=("$relative_path")
}

check_parent_path() {
    local relative_path="$1"
    local target_path="$target_dir/$relative_path"
    local remaining="$relative_path"
    local component
    local current="$target_dir"

    while [[ "$remaining" == */* ]]; do
        component="${remaining%%/*}"
        remaining="${remaining#*/}"
        current="$current/$component"

        if [[ -L "$current" ]]; then
            printf 'Cannot safely back up %s because parent %s is a symlink.\n' \
                "$target_path" "$current" >&2
            return 0
        fi

        if [[ -e "$current" && ! -d "$current" ]]; then
            printf 'Cannot safely back up %s because parent %s is not a directory.\n' \
                "$target_path" "$current" >&2
            return 0
        fi
    done

    return 1
}

validation_failed=false
for package in "${packages[@]}"; do
    package_dir="$repo_dir/$package"

    if [[ ! -d "$package_dir" ]]; then
        printf 'Dotfile package not found: %s\n' "$package_dir" >&2
        validation_failed=true
        continue
    fi

    while IFS= read -r -d '' source_path; do
        relative_path="${source_path#"$package_dir/"}"
        target_path="$target_dir/$relative_path"

        if [[ -e "$target_path" && "$target_path" -ef "$source_path" ]]; then
            continue
        fi

        if check_parent_path "$relative_path"; then
            validation_failed=true
            continue
        fi

        if [[ -L "$target_path" ]]; then
            add_conflict "$relative_path"
        elif [[ -f "$target_path" ]]; then
            add_conflict "$relative_path"
        elif [[ -e "$target_path" ]]; then
            printf 'Cannot safely back up %s because it is not a regular file or symlink.\n' \
                "$target_path" >&2
            validation_failed=true
        fi
    done < <(find "$package_dir" \( -type f -o -type l \) -print0)
done

if [[ " ${conflict_paths[*]} " == *" .ssh/config "* ]] &&
    [[ ! -e "$target_dir/.ssh/config.local" ]]; then
    printf 'Refusing to back up %s/.ssh/config because config.local is missing.\n' \
        "$target_dir" >&2
    printf 'Preserve the local SSH configuration first:\n' >&2
    printf '  cp -p %s/.ssh/config %s/.ssh/config.local\n' "$target_dir" "$target_dir" >&2
    printf '  chmod 600 %s/.ssh/config.local\n' "$target_dir" >&2
    validation_failed=true
fi

if [[ "$validation_failed" == true ]]; then
    printf 'No files were moved.\n' >&2
    exit 1
fi

if ((${#conflict_paths[@]} == 0)); then
    printf 'No Dotfile conflicts need backup.\n'
    exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$target_dir/.dotfiles-backups/$timestamp"
if [[ -e "$backup_root" || -L "$backup_root" ]]; then
    backup_root="$backup_root.$$"
fi

moved_paths=()
restore_moved_paths() {
    local index
    local relative_path
    local backup_path
    local target_path

    for ((index=${#moved_paths[@]} - 1; index >= 0; index--)); do
        relative_path="${moved_paths[$index]}"
        backup_path="$backup_root/$relative_path"
        target_path="$target_dir/$relative_path"

        if [[ -e "$target_path" || -L "$target_path" ]]; then
            printf 'Could not restore %s because the target exists.\n' "$target_path" >&2
            continue
        fi

        mkdir -p "$(dirname -- "$target_path")"
        mv -- "$backup_path" "$target_path"
    done
}

for relative_path in "${conflict_paths[@]}"; do
    target_path="$target_dir/$relative_path"
    backup_path="$backup_root/$relative_path"

    if ! install -d -m 700 "$(dirname -- "$backup_path")"; then
        restore_moved_paths
        exit 1
    fi

    if ! mv -- "$target_path" "$backup_path"; then
        restore_moved_paths
        exit 1
    fi

    moved_paths+=("$relative_path")
    printf 'Backed up %s\n' "$target_path"
done

printf '\nDotfile backup created: %s\n' "$backup_root"
