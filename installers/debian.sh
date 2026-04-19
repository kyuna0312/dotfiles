#!/usr/bin/env bash
# installers/debian.sh — Debian/Ubuntu package installation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECURITY="${1:-0}"

_parse_pkg_list() {
  # Strip comments and blank lines from a package list file
  grep -v '^\s*#' "$1" | grep -v '^\s*$'
}

install_base() {
  echo "[debian] Updating package index..."
  sudo apt-get update -qq

  local pkgs
  pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/debian-base.txt")

  echo "[debian] Installing base packages..."
  # shellcheck disable=SC2086
  sudo apt-get install -y --no-install-recommends $pkgs

  # bat ships as 'batcat' on Debian/Ubuntu — alias to bat
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi

  # fd ships as 'fdfind' on Debian/Ubuntu
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi

  # Install starship (not in apt repos)
  if ! command -v starship >/dev/null 2>&1; then
    echo "[debian] Installing starship via official script..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # Install eza (not in apt repos pre-Ubuntu 24.04)
  if ! command -v eza >/dev/null 2>&1; then
    echo "[debian] Installing eza via cargo or direct binary..."
    if command -v cargo >/dev/null 2>&1; then
      cargo install eza
    else
      local arch
      arch="$(dpkg --print-architecture)"
      local eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz"
      curl -sL "$eza_url" | tar xz -C "$HOME/.local/bin/"
    fi
  fi
}

install_security() {
  echo "[debian] Installing security tools..."
  local pkgs
  pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/debian-security.txt")

  # Try Kali repo if available, otherwise fall back to standard apt
  if grep -q "kali" /etc/apt/sources.list 2>/dev/null; then
    # shellcheck disable=SC2086
    sudo apt-get install -y $pkgs
  else
    # Filter to only packages available in standard Debian/Ubuntu
    # shellcheck disable=SC2086
    sudo apt-get install -y --fix-missing $pkgs || true
  fi

  # Install pwndbg (GDB enhancement for exploit development)
  local pwndbg_dir="$HOME/.local/share/pwndbg"
  if [[ ! -d "$pwndbg_dir" ]]; then
    git clone https://github.com/pwndbg/pwndbg "$pwndbg_dir" --depth=1
    (cd "$pwndbg_dir" && ./setup.sh)
  fi
}

main() {
  install_base
  [[ "$SECURITY" == "1" ]] && install_security
}

main "$@"
