# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/anishthite/.docker/bin"
# End of Docker Desktop section.

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Hermes Agent — ensure ~/.local/bin is on PATH
export PATH="$HOME/.local/bin:$PATH"

# Added by jcode installer
export PATH="/Users/anishthite/.local/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
