# Linux-specific NIGHT CITY zsh layer

export CYBERPUNK_OS="linux"

# ---------- Tmux auto-start ----------
# Wrap every interactive login shell in tmux.
# Skip: already inside tmux, Zellij, VS Code/Cursor integrated terminal, non-interactive.
if [[ -z "$TMUX" && -z "$ZELLIJ" && -z "$VSCODE_INJECTION" && -z "$CURSOR_TRACE" ]] \
   && [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
  # Not `exec`: if tmux cannot start (unknown $TERM over ssh, broken config)
  # exec would close the login and lock you out; this falls back to plain zsh.
  # Reuse a detached auto-session (numeric name) before creating one, so
  # closed terminals don't pile up sessions. Named sessions are left alone.
  # ponytail: two terminals opened at once can pick the same session and mirror it.
  __dp_tmux="$(tmux ls -F '#{session_attached} #{session_name}' 2>/dev/null \
    | awk '$1 == 0 && $2 ~ /^[0-9]+$/ { print $2; exit }')"
  if [[ -n "$__dp_tmux" ]]; then
    tmux attach-session -t "=$__dp_tmux"
  else
    tmux new-session
  fi && exit
  unset __dp_tmux
fi

export PATH="$HOME/.local/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"
