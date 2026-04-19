#!/usr/bin/env bash
# installers/macos.sh — macOS package installation via Homebrew
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECURITY="${1:-0}"

_parse_pkg_list() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$'
}

ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "[macos] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_base() {
  ensure_homebrew
  echo "[macos] Installing base packages..."
  local pkgs
  pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/macos-base.txt")
  # shellcheck disable=SC2086
  brew install $pkgs || true
}

install_security() {
  echo "[macos] Installing security tools..."
  local pkgs
  pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/macos-security.txt")
  # shellcheck disable=SC2086
  brew install $pkgs || true

  # Brew cask for GUI tools
  brew install --cask burp-suite ghidra || true
}

main() {
  install_base
  [[ "$SECURITY" == "1" ]] && install_security
}

main "$@"
