# ~/.zshenv — points zsh at its XDG config dir. Keep this tiny.
# This is the only zsh file zsh reads from $HOME; everything else lives in $ZDOTDIR.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
