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

detect_distro() {
  if [[ "$(uname -s)" == Darwin* ]]; then
    echo "macos"
  elif command -v pacman >/dev/null 2>&1; then
    echo "arch"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "debian"
  else
    echo "unknown"
  fi
}

install_packages() {
  local distro="$1"
  local security="${2:-0}"
  local installer="${REPO_ROOT}/installers/${distro}.sh"
  if [[ -f "$installer" ]]; then
    bash "$installer" "$security"
  else
    echo "[warn] No installer found for distro: $distro"
  fi
}

main() {
  local security_flag="0"
  for arg in "$@"; do
    [[ "$arg" == "--security" ]] && security_flag="1"
  done

  local distro
  distro="$(detect_distro)"
  echo "[install] Detected: $distro"

  install_packages "$distro" "$security_flag"

  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"

  if [[ "$uname_s" == Darwin* ]]; then
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
    # Hyprland (Arch/Linux only)
    if [[ -d "${REPO_ROOT}/hyprland" ]]; then
      mkdir -p "$HOME/.config/hypr"
      link_force "${REPO_ROOT}/hyprland/hyprland.conf"  "$HOME/.config/hypr/hyprland.conf"
      link_force "${REPO_ROOT}/hyprland/keybinds.conf"  "$HOME/.config/hypr/keybinds.conf"
      link_force "${REPO_ROOT}/hyprland/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
    fi

    if [[ -d "${REPO_ROOT}/waybar" ]]; then
      mkdir -p "$HOME/.config/waybar"
      link_force "${REPO_ROOT}/waybar/config.jsonc" "$HOME/.config/waybar/config"
      link_force "${REPO_ROOT}/waybar/style.css"    "$HOME/.config/waybar/style.css"
    fi
  fi

  # Shells (entrypoints)
  link_force "${REPO_ROOT}/zshrc/.zshrc" "$HOME/.zshrc"
  link_force "${REPO_ROOT}/bashrc/.bashrc" "$HOME/.bashrc"

  # Starship
  mkdir -p "$HOME/.config/starship"
  link_force "${REPO_ROOT}/starship/starship.toml" "$HOME/.config/starship/starship.toml"

  # Tmux
  mkdir -p "$HOME/.config/tmux"
  link_force "${REPO_ROOT}/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"
  link_force "${REPO_ROOT}/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  link_force "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"

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

  # Claude Code (plugins, MCP config, skills)
  if [[ -d "${REPO_ROOT}/claude" ]]; then
    mkdir -p "$HOME/.claude/skills"
    [[ -f "${REPO_ROOT}/claude/settings.json" ]] && \
      link_force "${REPO_ROOT}/claude/settings.json" "$HOME/.claude/settings.json"
    [[ -f "${REPO_ROOT}/claude/.caveman-active" ]] && \
      link_force "${REPO_ROOT}/claude/.caveman-active" "$HOME/.claude/.caveman-active"
    [[ -d "${REPO_ROOT}/claude/skills/code-reviewer" ]] && \
      link_dir_force "${REPO_ROOT}/claude/skills/code-reviewer" "$HOME/.claude/skills/code-reviewer"
    # Install MCP server dependencies
    if command -v uv >/dev/null 2>&1 && [[ -d "${REPO_ROOT}/claude/mcp-servers/inari" ]]; then
      uv sync --project "${REPO_ROOT}/claude/mcp-servers/inari" --quiet
    fi
  fi

  # Ollama local models (pull if ollama is installed)
  if command -v ollama >/dev/null 2>&1; then
    ollama pull llama4:scout  || true
    ollama pull qwen3:8b      || true
  fi

  echo "Done. Open a new shell. For tmux plugins: start tmux and press Ctrl+I."
}

main "$@"

