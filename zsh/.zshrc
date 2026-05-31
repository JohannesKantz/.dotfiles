# If not running interactively, don't do anything
[[ $- != *i* ]] && return


setopt PROMPT_SUBST         # enable substitution in the prompt
setopt AUTOCD               # optional cd
setopt AUTO_PUSHD           # cd push the old directory onto the directory stack
setopt PUSHD_MINUS          # exchanges the meanings of '+' and '-'
setopt PUSHD_IGNORE_DUPS    # don't push multiple copies of the same directory onto the directory stack
setopt PUSHD_SILENT         # don't print the directory stack after pushd or popd
setopt APPEND_HISTORY       # append history to the history file, rather than replace it
setopt HISTIGNOREDUPS       # prevents the current line from being saved in the history if it is the same as the previous one
setopt HISTIGNORESPACE      # prevents the current line from being saved if it begins with a space

DISABLE_AUTO_TITLE="true"
COMPLETION_WAITING_DOTS="true"

################
#  COMPLETION  #
################

ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

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


#####################
#  AUTOSUGGESTIONS  #
#####################

# suggestions style
#   use xterm-256color or just 'fg=#ffffff'
#   fg=forground; bg=background,
#   example: "fg=#ff00ff,bg=cyan,bold,underline"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
# defines how suggestions are generated
#   match_prev_cmd: chooses a suggestion based on the current input and the previous command (default)
#   history: chooses the most recent match from history
#   completion: chooses a suggestion based on what tab-completion would suggest (requires zpty module)
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history completion)


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

if (( $+commands[fnm] )); then
    eval "$(fnm env --use-on-cd --shell zsh)"
fi


##################
# USER SETTINGS  #
##################

# load aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# load functions
[[ -f "$HOME/.functions" ]] && source "$HOME/.functions"


############
#  PROMPT  #
############

PROMPT='$(git_branch)%F{green}%~ %F{white}$ '
