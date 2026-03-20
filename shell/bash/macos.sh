# macOS-specific bash layer

export CYBERPUNK_OS="macos"

[[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:$PATH"
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

export EDITOR="${EDITOR:-$(command -v nvim 2>/dev/null || command -v vim 2>/dev/null || echo vi)}"

