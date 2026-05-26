# Linux-specific bash layer

export CYBERPUNK_OS="linux"

# ---------- Tmux auto-start ----------
# Wrap every interactive login shell in tmux.
# Skip: already inside tmux, Zellij, VS Code/Cursor integrated terminal, non-interactive.
if [[ -z "$TMUX" && -z "$ZELLIJ" && -z "$VSCODE_INJECTION" && -z "$CURSOR_TRACE" ]] \
   && [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session
fi

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

