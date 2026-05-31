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


#############
# oh-my-zsh #
#############

# compdump cache file
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"



#############
#  PLUGINS  #
#############

plugins=(
    extract                     # (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract)
    git                         # (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)
    gh                          # (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gh)
    zsh-syntax-highlighting     # (https://github.com/zsh-users/zsh-syntax-highlighting)
    zsh-autosuggestions         # (https://github.com/zsh-users/zsh-autosuggestions)
    fnm                         # (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/fnm)
    rust                        # (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/rust)
)




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
#   history: chooses the most recent match from history
#   completion: chooses a suggestion based on what tab-completion would suggest (requires zpty module)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)


#autoload -Uz compinit && compinit -d
#autoload -Uz +X bashcompinit && bashcompinit -D


# oh my zsh
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"


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


# dotfiles config
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'



# bun completions
[ -s "/Users/johanneskantz/.bun/_bun" ] && source "/Users/johanneskantz/.bun/_bun"


