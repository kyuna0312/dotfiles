# Linux-specific cyberpunk zsh layer

export CYBERPUNK_OS="linux"

# ---------- Tmux auto-start ----------
# Wrap every interactive login shell in tmux.
# Skip: already inside tmux, Zellij, VS Code/Cursor integrated terminal, non-interactive.
if [[ -z "$TMUX" && -z "$ZELLIJ" && -z "$VSCODE_INJECTION" && -z "$CURSOR_TRACE" ]] \
   && [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session
fi

export PATH="$HOME/.local/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

# Security aliases — only load when at least nmap or burpsuite is installed
if command -v nmap >/dev/null 2>&1 || command -v burpsuite >/dev/null 2>&1; then
  [[ -f "${CYBERPUNK_DOTFILES_DIR}/config/zsh/lib/security.zsh" ]] && \
    source "${CYBERPUNK_DOTFILES_DIR}/config/zsh/lib/security.zsh"
fi
