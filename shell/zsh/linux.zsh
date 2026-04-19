# Linux-specific cyberpunk zsh layer

export CYBERPUNK_OS="linux"

# ---------- Tmux auto-start ----------
# Wrap every interactive login shell in tmux.
# Skip: already inside tmux, Zellij, VS Code/Cursor integrated terminal, non-interactive.
if [[ -z "$TMUX" && -z "$ZELLIJ" && -z "$VSCODE_INJECTION" && -z "$CURSOR_TRACE" ]] \
   && [[ $- == *i* ]] && command -v tmux >/dev/null 2>&1; then
  # -A: attach if session exists, else create. -s main: default session name.
  exec tmux new-session -A -s main
fi

export PATH="$HOME/.local/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

# Helper used by kubectl completion caching.
__dp_file_mtime_epoch() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  # GNU stat: %Y = mtime as epoch seconds
  stat -c %Y "$f"
}

# Security aliases — only load when at least nmap or burpsuite is installed
if command -v nmap >/dev/null 2>&1 || command -v burpsuite >/dev/null 2>&1; then
  [[ -f "${CYBERPUNK_DOTFILES_DIR}/security/aliases.zsh" ]] && \
    source "${CYBERPUNK_DOTFILES_DIR}/security/aliases.zsh"
fi
