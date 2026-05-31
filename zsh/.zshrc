# If not running interactively, don't do anything
[[ $- != *i* ]] && return


#############
#  OPTIONS  #
#############

setopt PROMPT_SUBST         # enable substitution in the prompt
setopt AUTOCD               # optional cd
setopt AUTO_PUSHD           # cd push the old directory onto the directory stack
setopt PUSHD_MINUS          # exchanges the meanings of '+' and '-'
setopt PUSHD_IGNORE_DUPS    # don't push multiple copies of the same directory onto the directory stack
setopt PUSHD_SILENT         # don't print the directory stack after pushd or popd


#############
#  HISTORY  #
#############

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt APPEND_HISTORY           # append history to the history file, rather than replace it
setopt EXTENDED_HISTORY         # save timestamps and durations
setopt HIST_EXPIRE_DUPS_FIRST   # delete duplicates first when the history is full
setopt HIST_IGNORE_DUPS         # don't save a command if it is the same as the previous command
setopt HIST_IGNORE_SPACE        # don't save commands that start with a space
setopt HIST_VERIFY              # show expanded history commands before running them
setopt SHARE_HISTORY            # share history between open shells


#########################
#  SYNTAX HIGHLIGHTING  #
#########################

ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)


#####################
#  AUTOSUGGESTIONS  #
#####################

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)


#############
#  PLUGINS  #
#############

# Bind arrow keys for history substring search.
function hss-bindkey() {
    zmodload zsh/terminfo
    for keymap in main emacs viins; do
        bindkey -M "$keymap" "$terminfo[kcuu1]" history-substring-search-up
        bindkey -M "$keymap" "$terminfo[kcud1]" history-substring-search-down
    done
}

if [[ ! -d "$HOME/.antidote" ]] && (( $+commands[git] )); then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi

if [[ -f "$HOME/.antidote/antidote.zsh" ]]; then
    source "$HOME/.antidote/antidote.zsh"
    antidote load
fi


#######################
#  SHELL INTEGRATION  #
#######################

if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
fi


################
#  COMPLETION  #
################

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZSH_COMPLETION_DIR="$ZSH_CACHE_DIR/completions"
ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump-${ZSH_VERSION}"

[[ -d "$ZSH_COMPLETION_DIR" ]] || command mkdir -p "$ZSH_COMPLETION_DIR"

typeset -U fpath
fpath=("$ZSH_COMPLETION_DIR" $fpath)

if (( $+commands[gh] )) &&
    [[ ! -s "$ZSH_COMPLETION_DIR/_gh" || "${commands[gh]}" -nt "$ZSH_COMPLETION_DIR/_gh" ]]; then
    gh completion --shell zsh > "$ZSH_COMPLETION_DIR/_gh.tmp.$$" &&
        command mv "$ZSH_COMPLETION_DIR/_gh.tmp.$$" "$ZSH_COMPLETION_DIR/_gh"
    command rm -f "$ZSH_COMPLETION_DIR/_gh.tmp.$$"
fi

if (( $+commands[mise] )) &&
    [[ ! -s "$ZSH_COMPLETION_DIR/_mise" || "${commands[mise]}" -nt "$ZSH_COMPLETION_DIR/_mise" ]]; then
    mise completion zsh > "$ZSH_COMPLETION_DIR/_mise.tmp.$$" &&
        command mv "$ZSH_COMPLETION_DIR/_mise.tmp.$$" "$ZSH_COMPLETION_DIR/_mise"
    command rm -f "$ZSH_COMPLETION_DIR/_mise.tmp.$$"
fi

if (( $+commands[bun] )) &&
    [[ ! -s "$ZSH_COMPLETION_DIR/_bun" || "${commands[bun]}" -nt "$ZSH_COMPLETION_DIR/_bun" ]]; then
    SHELL=zsh bun completions > "$ZSH_COMPLETION_DIR/_bun.tmp.$$" &&
        command mv "$ZSH_COMPLETION_DIR/_bun.tmp.$$" "$ZSH_COMPLETION_DIR/_bun"
    command rm -f "$ZSH_COMPLETION_DIR/_bun.tmp.$$"
fi

if (( $+commands[rustup] && $+commands[cargo] )); then
    if [[ ! -s "$ZSH_COMPLETION_DIR/_rustup" || "${commands[rustup]}" -nt "$ZSH_COMPLETION_DIR/_rustup" ]]; then
        rustup completions zsh > "$ZSH_COMPLETION_DIR/_rustup.tmp.$$" &&
            command mv "$ZSH_COMPLETION_DIR/_rustup.tmp.$$" "$ZSH_COMPLETION_DIR/_rustup"
        command rm -f "$ZSH_COMPLETION_DIR/_rustup.tmp.$$"
    fi

    if [[ ! -s "$ZSH_COMPLETION_DIR/_cargo" || "${commands[rustup]}" -nt "$ZSH_COMPLETION_DIR/_cargo" ]]; then
        rustup completions zsh cargo > "$ZSH_COMPLETION_DIR/_cargo.tmp.$$" &&
            command mv "$ZSH_COMPLETION_DIR/_cargo.tmp.$$" "$ZSH_COMPLETION_DIR/_cargo"
        command rm -f "$ZSH_COMPLETION_DIR/_cargo.tmp.$$"
    fi
fi

autoload -Uz compinit
compinit -d "$ZSH_COMPDUMP"

# Group matches and describe
zstyle ':completion:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description ' %F{8}specify:%f %B%F{cyan}%d%f%b'
zstyle ':completion:*:corrections' format ' %F{8}correction:%f %B%F{green}%d (errors: %f%F{red}%e%f%F{green})%f%b'
zstyle ':completion:*:descriptions' format ' %F{8}description:%f %B%F{blue}%d%f%b'
zstyle ':completion:*:messages' format ' %F{8}message:%f %B%F{magenta}%d%f%b'
zstyle ':completion:*:warnings' format ' %F{8}error:%f %B%F{red}no matches found%f%b'
zstyle ':completion:*:default' select-prompt '%B%S%M%b matches, current selection at %p%s'
zstyle ':completion:*' format ' %F{8}completion:%f %B%F{yellow}%d%f%b'
zstyle ':completion:*' list-separator '→'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Fuzzy match mistyped completions
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Ignore multiple entries
zstyle ':completion:*:(rm|kill|diff):*' ignore-line yes
zstyle ':completion:*:rm:*' file-patterns '*:all-files'


###################
#  USER SETTINGS  #
###################

# load aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# load functions
[[ -f "$HOME/.functions" ]] && source "$HOME/.functions"


############
#  PROMPT  #
############

PROMPT='$(git_branch)%F{green}%~ %F{white}$ '
