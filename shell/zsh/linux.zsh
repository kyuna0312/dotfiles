# Linux-specific cyberpunk zsh layer

export CYBERPUNK_OS="linux"

export PATH="$HOME/.local/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

# Helper used by kubectl completion caching.
__dp_file_mtime_epoch() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  # GNU stat: %Y = mtime as epoch seconds
  stat -c %Y "$f"
}

