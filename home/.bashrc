# ~/.bashrc — minimal fallback. zsh is the primary shell here.
[[ $- != *i* ]] && return

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

# PATH: language/toolchain dirs (safe if missing).
for _d in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin"; do
  [[ -d "$_d" && ":$PATH:" != *":$_d:"* ]] && PATH="$_d:$PATH"
done
unset _d
export PATH

alias ..='cd ..'
alias ...='cd ../..'
command -v eza >/dev/null 2>&1 && alias ls='eza -al --icons --git'

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

printf '\033[38;5;239m» bash fallback — run \033[38;5;212mexec zsh\033[38;5;239m for the full setup.\033[0m\n'
