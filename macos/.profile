# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export EDITOR='vim'
export VISUAL='vim'
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
#export LANGUAGE=en_US

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# homebrew
eval $(/opt/homebrew/bin/brew shellenv)

########
# Path #
########

#brew
export PATH=/opt/homebrew/bin:$PATH

#code
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#jabba
[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# cargo
[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"

#fnm
eval "$(fnm env --use-on-cd)"

#bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
