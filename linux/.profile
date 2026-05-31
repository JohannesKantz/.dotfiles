# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export EDITOR='vim'
export VISUAL='vim'
#export LANG=en_US.UTF-8
#export LANGUAGE=en_US

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	\. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

##########
#  PATH  #
##########


# fnm
export PATH=/home/johannes/.fnm:$PATH
eval "`fnm env`"

#cargo
[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"

#deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# bun completions
[ -s "/home/johannes/.bun/_bun" ] && source "/home/johannes/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
