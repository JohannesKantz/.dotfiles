# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export EDITOR='vim'
export VISUAL='vim'
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
#export LANGUAGE=en_US

# if running bash
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        \. "$HOME/.bashrc"
    fi
fi

##########
#  PATH  #
##########

# user binaries
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# VS Code
[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ] &&
    PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Jabba
[ -s "$HOME/.jabba/jabba.sh" ] && . "$HOME/.jabba/jabba.sh"

# JetBrains Toolbox
[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ] &&
    PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Cargo
[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && PATH="$BUN_INSTALL/bin:$PATH"

# Deno
export DENO_INSTALL="$HOME/.deno"
[ -d "$DENO_INSTALL/bin" ] && PATH="$DENO_INSTALL/bin:$PATH"
