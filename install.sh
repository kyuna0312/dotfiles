#!/usr/bin/env bash
# install.sh — BOX UK // CyberMac dotfiles bootstrap (config-mirror layout)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${REPO_ROOT}/lib/link.sh"

usage() {
  cat <<'EOF'
install.sh — BOX UK // CyberMac dotfiles bootstrap

Usage:
  bash install.sh [options]

Options:
  --security        Also install pentest tools
  --skip-packages   Symlinks only (re-link after editing configs)
  --dry-run         Print actions without making any changes
  -h, --help        Show this help and exit
EOF
}

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
  elif [[ "$DRY_RUN" == "1" ]]; then
    _info "[dry-run] would install sheldon → $HOME/.local/bin"
    return 0
  else
    _info "Installing sheldon..."
    mkdir -p "$HOME/.local/bin"
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
      | bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin" 2>/dev/null \
      || { _warn "sheldon auto-install failed; install it manually."; return 0; }
  fi
  if command -v sheldon >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == "1" ]]; then
      _info "[dry-run] would lock sheldon plugins"
    else
      _info "Locking sheldon plugins..."
      sheldon --config-dir "${REPO_ROOT}/config/sheldon" lock 2>/dev/null || true
    fi
  fi
}

# ── Submodules ────────────────────────────────────────────────────────────────
setup_submodules() {
  # NyanVim (config/nvim) and any other submodules ship as git submodules.
  if git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1 \
     && [[ -f "${REPO_ROOT}/.gitmodules" ]]; then
    _info "Syncing submodules (nvim → NyanVim)..."
    run git -C "${REPO_ROOT}" submodule update --init --recursive || \
      _warn "submodule sync failed; nvim config may be empty."
  fi
}

# ── Linking ───────────────────────────────────────────────────────────────────
link_home() {
  _info "Linking \$HOME dotfiles..."
  link_force "${REPO_ROOT}/home/.zshenv" "$HOME/.zshenv"
  link_force "${REPO_ROOT}/home/.bashrc" "$HOME/.bashrc"
}

link_config() {
  _info "Linking ~/.config entries..."
  local dir name
  for dir in "${REPO_ROOT}/config/"*/; do
    name="$(basename "$dir")"
    link_force "${dir%/}" "$HOME/.config/${name}"
  done

  # Compat symlinks for tools that also read $HOME paths.
  link_if_exists "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"
}

setup_tmux_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    return 0
  elif [[ "$DRY_RUN" == "1" ]]; then
    _info "[dry-run] would clone TPM → $tpm_dir"
  else
    _info "Cloning TPM..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

link_extras() {
  local uname_s; uname_s="$(uname -s 2>/dev/null || echo unknown)"

  if [[ "$uname_s" == Darwin* ]]; then
    _info "Linking macOS-specific configs..."
    [[ -d "${REPO_ROOT}/macos/aerospace"   ]] && link_force "${REPO_ROOT}/macos/aerospace"   "$HOME/.config/aerospace"
    [[ -d "${REPO_ROOT}/macos/hammerspoon" ]] && link_force "${REPO_ROOT}/macos/hammerspoon" "$HOME/.hammerspoon"
    [[ -d "${REPO_ROOT}/macos/skhd"        ]] && link_force "${REPO_ROOT}/macos/skhd"        "$HOME/.config/skhd"
    [[ -d "${REPO_ROOT}/macos/karabiner"   ]] && link_force "${REPO_ROOT}/macos/karabiner"   "$HOME/.config/karabiner"
    [[ -d "${REPO_ROOT}/macos/alfred"      ]] && link_force "${REPO_ROOT}/macos/alfred"      "$HOME/.config/alfred"

    # Übersicht widgets live under Application Support, not ~/.config
    if [[ -d "${REPO_ROOT}/macos/ubersicht/boxuk-bar.widget" ]]; then
      local uber_dir="$HOME/Library/Application Support/Übersicht/widgets"
      mkdir -p "$uber_dir"
      link_force "${REPO_ROOT}/macos/ubersicht/boxuk-bar.widget" "$uber_dir/boxuk-bar.widget"
    fi
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local security_flag="0" skip_packages="0"
  for arg in "$@"; do
    case "$arg" in
      --security)      security_flag="1" ;;
      --skip-packages) skip_packages="1" ;;
      --dry-run)       DRY_RUN="1" ;;
      -h|--help)       usage; exit 0 ;;
      *)               _warn "Unknown option: $arg"; usage; exit 2 ;;
    esac
  done
  export DRY_RUN REPO_ROOT

  [[ "$DRY_RUN" == "1" ]] && _warn "Dry run — no changes will be made."

  local distro; distro="$(detect_distro)"

  printf "${_C_PINK}\n  ✦  BOX UK // CyberMac Dotfiles${_C_RST}\n"
  printf "${_C_DIM}     ────────────────────────────${_C_RST}\n"
  _info "Distro: ${distro}"

  if [[ "$skip_packages" == "0" ]]; then
    _info "Installing packages..."
    install_packages "$distro" "$security_flag"
  else
    _warn "Skipping package installation (--skip-packages)"
  fi

  setup_submodules
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
