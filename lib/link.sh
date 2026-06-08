#!/usr/bin/env bash
# lib/link.sh — shared library: colors, logging, dry-run runner,
# package-list parsing, and symlink helpers. Sourced by install.sh
# and every installers/*.sh.

# ── Colors ────────────────────────────────────────────────────────────────────
_C_PINK='\033[38;5;212m'; _C_CYAN='\033[38;5;51m'; _C_GOLD='\033[38;5;221m'
_C_ROSE='\033[38;5;204m'; _C_DIM='\033[38;5;239m';  _C_RST='\033[0m'
_info()  { printf "${_C_CYAN}[✦]${_C_RST} %s\n" "$*"; }
_warn()  { printf "${_C_GOLD}[!]${_C_RST} %s\n" "$*"; }
_ok()    { printf "${_C_PINK}[✓]${_C_RST} %s\n" "$*"; }
_error() { printf "${_C_ROSE}[✗]${_C_RST} %s\n" "$*" >&2; }

# ── Shared environment ──────────────────────────────────────────────────────────
# REPO_ROOT defaults to this lib's parent; honored if the caller already set it.
: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# DRY_RUN=1 prints actions instead of performing them (exported by install.sh).
: "${DRY_RUN:=0}"

# ── Helpers ───────────────────────────────────────────────────────────────────
# run: execute a command, or print it when DRY_RUN=1. For simple argv commands
# only (no pipes/redirection — guard those with `[[ "$DRY_RUN" == 1 ]]` inline).
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf "${_C_DIM}     [dry-run] %s${_C_RST}\n" "$*"
  else
    "$@"
  fi
}

# _parse_pkg_list: strip comments and blank lines from a package list file.
_parse_pkg_list() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$'
}

backup_if_exists() {
  local dst="$1"
  if [[ -e "$dst" || -L "$dst" ]]; then
    local ts; ts="$(date +%Y%m%d-%H%M%S)"
    mv -f "$dst" "${dst}.bak.${ts}"
  fi
}

link_force() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf "${_C_DIM}     [dry-run] link %s → %s${_C_RST}\n" "$dst" "$src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -sf "$src" "$dst"
  _ok "  $dst"
}

link_if_exists() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] && link_force "$src" "$dst" || true
}
