# Linux-specific NIGHT CITY zsh layer

export CYBERPUNK_OS="linux"

# ---------- Tmux auto-start ----------
# Wrap every interactive login shell in tmux.
# Skip: already inside tmux, Zellij, VS Code/Cursor integrated terminal, non-interactive.
if [[ -z "$TMUX" && -z "$ZELLIJ" && -z "$VSCODE_INJECTION" && -z "$CURSOR_TRACE" ]] \
   && [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
  # Not `exec`: if tmux cannot start (unknown $TERM over ssh, broken config)
  # exec would close the login and lock you out; this falls back to plain zsh.
  tmux new-session && exit
fi

export PATH="$HOME/.local/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"
