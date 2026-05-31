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

##########
#  PATH  #
##########

# user binaries
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# Cargo
[ -s "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"

# Deno
export DENO_INSTALL="$HOME/.deno"
[ -d "$DENO_INSTALL/bin" ] && PATH="$DENO_INSTALL/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && PATH="$BUN_INSTALL/bin:$PATH"
