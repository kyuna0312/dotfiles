#!/usr/bin/env bash
# install.sh — Lucy Edgerunner+ dotfiles bootstrap
# Usage:
#   bash install.sh                  # detect OS, install packages + symlinks
#   bash install.sh --security       # also install pentest tools
#   bash install.sh --skip-packages  # symlinks only (re-link after editing)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
_C_PINK='\033[38;5;212m'; _C_CYAN='\033[38;5;51m'; _C_GOLD='\033[38;5;221m'
_C_ROSE='\033[38;5;204m'; _C_DIM='\033[38;5;239m';  _C_RST='\033[0m'
_info()  { printf "${_C_CYAN}[✦]${_C_RST} %s\n" "$*"; }
_warn()  { printf "${_C_GOLD}[!]${_C_RST} %s\n" "$*"; }
_ok()    { printf "${_C_PINK}[✓]${_C_RST} %s\n" "$*"; }
_error() { printf "${_C_ROSE}[✗]${_C_RST} %s\n" "$*" >&2; }

# ── Symlink helpers ───────────────────────────────────────────────────────────
backup_if_exists() {
  local dst="$1"
  if [[ -e "$dst" || -L "$dst" ]]; then
    local ts; ts="$(date +%Y%m%d-%H%M%S)"
    mv -f "$dst" "${dst}.bak.${ts}"
  fi
}

link_force() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
  _ok "  $dst"
}

link_dir_force() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
  _ok "  $dst"
}

# Link a file only when the source exists
link_if_exists() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] && link_force "$src" "$dst" || true
}

# ── Distro detection ──────────────────────────────────────────────────────────
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
  local distro="$1" security="${2:-0}"
  local installer="${REPO_ROOT}/installers/${distro}.sh"
  if [[ -f "$installer" ]]; then
    bash "$installer" "$security"
  else
    _warn "No installer for distro: $distro"
  fi
}

# ── Symlink all configs ───────────────────────────────────────────────────────
link_configs() {
  local uname_s; uname_s="$(uname -s 2>/dev/null || echo unknown)"

  _info "Linking shell configs..."
  link_force "${REPO_ROOT}/zshrc/.zshrc"   "$HOME/.zshrc"
  link_force "${REPO_ROOT}/bashrc/.bashrc" "$HOME/.bashrc"

  _info "Linking Starship..."
  mkdir -p "$HOME/.config/starship"
  link_force "${REPO_ROOT}/starship/starship.toml" "$HOME/.config/starship/starship.toml"

  _info "Linking Neovim..."
  link_dir_force "${REPO_ROOT}/nvim" "$HOME/.config/nvim"

  _info "Linking Tmux..."
  mkdir -p "$HOME/.config/tmux"
  link_force "${REPO_ROOT}/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"
  link_force "${REPO_ROOT}/tmux/tmux.conf"       "$HOME/.config/tmux/tmux.conf"
  link_force "$HOME/.config/tmux/tmux.conf"      "$HOME/.tmux.conf"

  # TPM (tmux plugin manager)
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    _info "Cloning TPM..."
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  _info "Linking Git..."
  mkdir -p "$HOME/.config/git"
  link_if_exists "${REPO_ROOT}/git/delta.gitconfig" "$HOME/.config/git/delta.gitconfig"

  _info "Linking Atuin..."
  mkdir -p "$HOME/.config/atuin"
  link_if_exists "${REPO_ROOT}/atuin/config.toml" "$HOME/.config/atuin/config.toml"

  _info "Linking Nushell..."
  mkdir -p "$HOME/.config/nushell"
  link_if_exists "${REPO_ROOT}/nushell/env.nu"    "$HOME/.config/nushell/env.nu"
  link_if_exists "${REPO_ROOT}/nushell/config.nu" "$HOME/.config/nushell/config.nu"

  # WezTerm
  if [[ -f "${REPO_ROOT}/wezterm/wezterm.lua" ]]; then
    _info "Linking WezTerm..."
    mkdir -p "$HOME/.config/wezterm"
    link_force "${REPO_ROOT}/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
    link_force "${REPO_ROOT}/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  fi

  if [[ "$uname_s" == Darwin* ]]; then
    _info "Linking macOS-specific configs..."
    link_if_exists "${REPO_ROOT}/macos/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
    [[ -d "${REPO_ROOT}/macos/hammerspoon" ]] && link_dir_force "${REPO_ROOT}/macos/hammerspoon" "$HOME/.hammerspoon"
    [[ -d "${REPO_ROOT}/macos/sketchybar"  ]] && link_dir_force "${REPO_ROOT}/macos/sketchybar"  "$HOME/.config/sketchybar"
    [[ -d "${REPO_ROOT}/macos/skhd"        ]] && link_dir_force "${REPO_ROOT}/macos/skhd"        "$HOME/.config/skhd"
    [[ -d "${REPO_ROOT}/macos/karabiner"   ]] && link_dir_force "${REPO_ROOT}/macos/karabiner"   "$HOME/.config/karabiner"
    # Ghostty (macOS)
    _info "Linking Ghostty (macOS)..."
    mkdir -p "$HOME/.config/ghostty"
    link_if_exists "${REPO_ROOT}/ghostty/config.macos" "$HOME/.config/ghostty/config"
  else
    _info "Linking Hyprland / Waybar..."
    if [[ -d "${REPO_ROOT}/hyprland" ]]; then
      mkdir -p "$HOME/.config/hypr"
      link_force "${REPO_ROOT}/hyprland/hyprland.conf"  "$HOME/.config/hypr/hyprland.conf"
      link_force "${REPO_ROOT}/hyprland/keybinds.conf"  "$HOME/.config/hypr/keybinds.conf"
      link_force "${REPO_ROOT}/hyprland/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
      link_if_exists "${REPO_ROOT}/hyprland/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
      link_if_exists "${REPO_ROOT}/hyprland/hyprlock.conf"  "$HOME/.config/hypr/hyprlock.conf"
    fi
    if [[ -d "${REPO_ROOT}/waybar" ]]; then
      mkdir -p "$HOME/.config/waybar"
      link_force "${REPO_ROOT}/waybar/config.jsonc" "$HOME/.config/waybar/config"
      link_force "${REPO_ROOT}/waybar/style.css"    "$HOME/.config/waybar/style.css"
    fi
    # Ghostty (Linux)
    _info "Linking Ghostty (Linux)..."
    mkdir -p "$HOME/.config/ghostty"
    link_if_exists "${REPO_ROOT}/ghostty/config.linux" "$HOME/.config/ghostty/config"
  fi

  # Claude Code
  if [[ -d "${REPO_ROOT}/claude" ]]; then
    _info "Linking Claude Code config..."
    mkdir -p "$HOME/.claude/skills"
    link_if_exists "${REPO_ROOT}/claude/settings.json"        "$HOME/.claude/settings.json"
    link_if_exists "${REPO_ROOT}/claude/.caveman-active"      "$HOME/.claude/.caveman-active"
    [[ -d "${REPO_ROOT}/claude/skills/code-reviewer" ]] && \
      link_dir_force "${REPO_ROOT}/claude/skills/code-reviewer" "$HOME/.claude/skills/code-reviewer"
    if command -v uv >/dev/null 2>&1 && [[ -d "${REPO_ROOT}/claude/mcp-servers/inari" ]]; then
      _info "Syncing Inari MCP deps..."
      uv sync --project "${REPO_ROOT}/claude/mcp-servers/inari" --quiet
    fi
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

    # Pull local AI models if Ollama is present
    if command -v ollama >/dev/null 2>&1; then
      _info "Pulling Ollama models (background)..."
      ollama pull llama4:scout &>/dev/null &
      ollama pull qwen3:8b    &>/dev/null &
    fi
  else
    _warn "Skipping package installation (--skip-packages)"
  fi

  link_configs

  printf "${_C_DIM}     ────────────────────────────${_C_RST}\n"
  printf "${_C_PINK}  ✓  Done.${_C_RST}\n"
  printf "     Open a new shell. Tmux plugins: ${_C_DIM}start tmux → Ctrl+I${_C_RST}\n\n"
}

main "$@"
