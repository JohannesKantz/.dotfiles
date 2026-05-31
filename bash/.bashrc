
# If not running interactively, don't do anything
[[ $- != *i* ]] && return


#############
#  HISTORY  #
#############

export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL=ignoreboth:erasedups

# Shell Options
shopt -s cdspell        # autocorrect cd misplelling
shopt -s checkwinsize   # Make sure display get updated when terminal window get resized
shopt -s checkhash      # look for commands in the hash table first, then PATH
shopt -s cmdhist        # save multi-line commands in history as a single line
shopt -s dotglob        # include .files in the expasion of *
shopt -s histappend     # Enable history appending instead of overwriting.


################
#  COMPLETION  #
################

complete -cf sudo
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


#######################
#  SHELL INTEGRATION  #
#######################

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi


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

export PS1='$(git_branch)\[\033[38;5;2m\]\w\[$(tput sgr0)\] \$ \[$(tput sgr0)\]'
