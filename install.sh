#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

backup_if_exists() {
  local dst="$1"
  if [[ -e "$dst" || -L "$dst" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    mv -f "$dst" "${dst}.bak.${ts}"
  fi
}

link_force() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
}

link_dir_force() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
}

install_linux_packages() {
  # Manjaro/Arch (pacman) first.
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --noconfirm --needed \
      zsh tmux git curl wget \
      starship fzf fd bat eza zoxide direnv \
      cmake make gcc gdb \
      nodejs npm \
      docker docker-compose \
      util-linux

    sudo systemctl enable --now docker >/dev/null 2>&1 || true
    return 0
  fi

  echo "No supported Linux package manager found (install packages manually)."
  return 0
}

install_macos_packages() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Install it first, then re-run."
    return 1
  fi

  brew install \
    zsh tmux git curl wget \
    starship fzf fd bat eza zoxide direnv \
    cmake make gcc \
    node docker-compose
}

main() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"

  if [[ "$uname_s" == Darwin* ]]; then
    install_macos_packages || true

    # macOS-only configs
    if [[ -d "${REPO_ROOT}/macos/hammerspoon" ]]; then
      link_dir_force "${REPO_ROOT}/macos/hammerspoon" "$HOME/.hammerspoon"
    fi

    if [[ -d "${REPO_ROOT}/macos/sketchybar" ]]; then
      link_dir_force "${REPO_ROOT}/macos/sketchybar" "$HOME/.config/sketchybar"
    fi

    if [[ -d "${REPO_ROOT}/macos/skhd" ]]; then
      link_dir_force "${REPO_ROOT}/macos/skhd" "$HOME/.config/skhd"
    fi

    if [[ -d "${REPO_ROOT}/macos/karabiner" ]]; then
      link_dir_force "${REPO_ROOT}/macos/karabiner" "$HOME/.config/karabiner"
    fi

    if [[ -f "${REPO_ROOT}/macos/aerospace/aerospace.toml" ]]; then
      link_force "${REPO_ROOT}/macos/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
    fi
  else
    install_linux_packages || true
  fi

  # Shells (entrypoints)
  link_force "${REPO_ROOT}/zshrc/.zshrc" "$HOME/.zshrc"
  link_force "${REPO_ROOT}/bashrc/.bashrc" "$HOME/.bashrc"

  # Starship
  mkdir -p "$HOME/.config/starship"
  backup_if_exists "$HOME/.config/starship/starship.toml"
  ln -s "${REPO_ROOT}/starship/starship.toml" "$HOME/.config/starship/starship.toml"

  # Tmux
  mkdir -p "$HOME/.config/tmux"
  link_force "${REPO_ROOT}/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"
  link_force "${REPO_ROOT}/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  backup_if_exists "$HOME/.tmux.conf"
  ln -s "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

  # TPM (tmux plugin manager)
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  # WezTerm (terminal emulator)
  if [[ -d "${REPO_ROOT}/wezterm" ]] && [[ -f "${REPO_ROOT}/wezterm/wezterm.lua" ]]; then
    mkdir -p "$HOME/.config/wezterm"
    link_force "${REPO_ROOT}/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
    # WezTerm also supports ~/.wezterm.lua
    link_force "${REPO_ROOT}/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  fi

  echo "Done. Open a new shell. For tmux plugins: start tmux and press Ctrl+I."
}

main "$@"

