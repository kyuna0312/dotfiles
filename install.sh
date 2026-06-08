#!/usr/bin/env bash
# install.sh — Lucy Edgerunner+ dotfiles bootstrap (config-mirror layout)
# Usage:
#   bash install.sh                  # detect OS, install packages + symlinks
#   bash install.sh --security       # also install pentest tools
#   bash install.sh --skip-packages  # symlinks only (re-link after editing)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_ROOT}/lib/link.sh"

# Config dirs handled specially (per-OS filename), excluded from the generic loop.
CONFIG_SKIP_ALWAYS=( ghostty )
# Linux-only window-manager configs, skipped on macOS.
CONFIG_SKIP_MACOS=( waybar )

# ── Distro detection ──────────────────────────────────────────────────────────
detect_distro() {
  if [[ "$(uname -s)" == Darwin* ]]; then echo "macos"
  elif command -v pacman >/dev/null 2>&1; then echo "arch"
  elif command -v apt-get >/dev/null 2>&1; then echo "debian"
  else echo "unknown"; fi
}

install_packages() {
  local distro="$1" security="${2:-0}"
  local installer="${REPO_ROOT}/installers/${distro}.sh"
  if [[ -f "$installer" ]]; then
    bash "$installer" "$security"
  else
    _warn "No installer for distro: $distro"
  fi
}

# ── Sheldon ───────────────────────────────────────────────────────────────────
setup_sheldon() {
  if command -v sheldon >/dev/null 2>&1; then
    _ok "  sheldon present"
  else
    _info "Installing sheldon..."
    mkdir -p "$HOME/.local/bin"
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
      | bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin" 2>/dev/null \
      || { _warn "sheldon auto-install failed; install it manually."; return 0; }
  fi
  if command -v sheldon >/dev/null 2>&1; then
    _info "Locking sheldon plugins..."
    sheldon --config-dir "${REPO_ROOT}/config/sheldon" lock 2>/dev/null || true
  fi
}

# ── Linking ───────────────────────────────────────────────────────────────────
link_home() {
  _info "Linking \$HOME dotfiles..."
  link_force "${REPO_ROOT}/home/.zshenv" "$HOME/.zshenv"
  link_force "${REPO_ROOT}/home/.bashrc" "$HOME/.bashrc"
}

link_config() {
  local uname_s; uname_s="$(uname -s 2>/dev/null || echo unknown)"
  _info "Linking ~/.config entries..."
  local dir name
  for dir in "${REPO_ROOT}/config/"*/; do
    name="$(basename "$dir")"
    _in_list "$name" "${CONFIG_SKIP_ALWAYS[@]}" && continue
    if [[ "$uname_s" == Darwin* ]] && _in_list "$name" "${CONFIG_SKIP_MACOS[@]}"; then
      continue
    fi
    link_force "${dir%/}" "$HOME/.config/${name}"
  done

  # ghostty: pick per-OS config file → ~/.config/ghostty/config
  if [[ "$uname_s" == Darwin* ]]; then
    link_if_exists "${REPO_ROOT}/config/ghostty/config.macos" "$HOME/.config/ghostty/config"
  else
    link_if_exists "${REPO_ROOT}/config/ghostty/config.linux" "$HOME/.config/ghostty/config"
  fi

  # Compat symlinks for tools that also read $HOME paths.
  link_if_exists "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
}

setup_tmux_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    _info "Cloning TPM..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

link_extras() {
  local uname_s; uname_s="$(uname -s 2>/dev/null || echo unknown)"

  if [[ "$uname_s" == Darwin* ]]; then
    _info "Linking macOS-specific configs..."
    link_if_exists "${REPO_ROOT}/macos/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
    [[ -d "${REPO_ROOT}/macos/hammerspoon" ]] && link_force "${REPO_ROOT}/macos/hammerspoon" "$HOME/.hammerspoon"
    [[ -d "${REPO_ROOT}/macos/sketchybar"  ]] && link_force "${REPO_ROOT}/macos/sketchybar"  "$HOME/.config/sketchybar"
    [[ -d "${REPO_ROOT}/macos/skhd"        ]] && link_force "${REPO_ROOT}/macos/skhd"        "$HOME/.config/skhd"
    [[ -d "${REPO_ROOT}/macos/karabiner"   ]] && link_force "${REPO_ROOT}/macos/karabiner"   "$HOME/.config/karabiner"
  fi

  # Claude Code
  if [[ -d "${REPO_ROOT}/claude" ]]; then
    _info "Linking Claude Code config..."
    [[ -d "$HOME/.claude" ]] || mkdir -p "$HOME/.claude/skills"
    link_if_exists "${REPO_ROOT}/claude/settings.json"   "$HOME/.claude/settings.json"
    link_if_exists "${REPO_ROOT}/claude/.caveman-active" "$HOME/.claude/.caveman-active"
    [[ -d "${REPO_ROOT}/claude/skills/code-reviewer" ]] && \
      link_force "${REPO_ROOT}/claude/skills/code-reviewer" "$HOME/.claude/skills/code-reviewer"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local security_flag="0" skip_packages="0"
  for arg in "$@"; do
    [[ "$arg" == "--security"      ]] && security_flag="1"
    [[ "$arg" == "--skip-packages" ]] && skip_packages="1"
  done

  local distro; distro="$(detect_distro)"

  printf "${_C_PINK}\n  ✦  Lucy Edgerunner+ Dotfiles${_C_RST}\n"
  printf "${_C_DIM}     ────────────────────────────${_C_RST}\n"
  _info "Distro: ${distro}"

  if [[ "$skip_packages" == "0" ]]; then
    _info "Installing packages..."
    install_packages "$distro" "$security_flag"
  else
    _warn "Skipping package installation (--skip-packages)"
  fi

  setup_sheldon
  link_home
  link_config
  setup_tmux_tpm
  link_extras

  printf "${_C_DIM}     ────────────────────────────${_C_RST}\n"
  printf "${_C_PINK}  ✓  Done.${_C_RST}\n"
  printf "     Open a new shell. Tmux plugins: ${_C_DIM}start tmux → Ctrl+I${_C_RST}\n\n"
}

main "$@"
