#!/usr/bin/env bash
# lib/link.sh — colors, logging, and symlink helpers shared by install.sh.

# ── Colors ────────────────────────────────────────────────────────────────────
_C_PINK='\033[38;5;212m'; _C_CYAN='\033[38;5;51m'; _C_GOLD='\033[38;5;221m'
_C_ROSE='\033[38;5;204m'; _C_DIM='\033[38;5;239m';  _C_RST='\033[0m'
_info()  { printf "${_C_CYAN}[✦]${_C_RST} %s\n" "$*"; }
_warn()  { printf "${_C_GOLD}[!]${_C_RST} %s\n" "$*"; }
_ok()    { printf "${_C_PINK}[✓]${_C_RST} %s\n" "$*"; }
_error() { printf "${_C_ROSE}[✗]${_C_RST} %s\n" "$*" >&2; }

# ── Helpers ───────────────────────────────────────────────────────────────────
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
  ln -sf "$src" "$dst"
  _ok "  $dst"
}

link_if_exists() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] && link_force "$src" "$dst" || true
}
