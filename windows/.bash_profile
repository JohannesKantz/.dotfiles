# Git Bash starts a login shell. Prefer the real Zsh installation; Bash remains
# a working fallback until Zsh has been installed into Git for Windows.
if [[ -t 1 ]] && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
fi

[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
