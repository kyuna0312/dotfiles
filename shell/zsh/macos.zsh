# macOS-specific cyberpunk zsh layer

export CYBERPUNK_OS="macos"

# Prefer Homebrew tool locations.
[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:$PATH"
[[ -d "/usr/local/bin" ]] && export PATH="/usr/local/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

__dp_file_mtime_epoch() {
  local f="$1"
  [[ -e "$f" ]] || return 0
  # BSD stat: %m = mtime as epoch seconds
  stat -f %m "$f"
}

# macOS often has pbcopy/pbpaste; clipboard helper in common handles it.

