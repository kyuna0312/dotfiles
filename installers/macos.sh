#!/usr/bin/env bash
# installers/macos.sh — macOS package installation via Homebrew
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/link.sh
source "${_DIR}/../lib/link.sh"
SECURITY="${1:-0}"

ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    _info "[macos] Installing Homebrew..."
    if [[ "$DRY_RUN" == "1" ]]; then
      _info "[dry-run] would install Homebrew"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  fi
}

install_base() {
  ensure_homebrew
  _info "[macos] Installing base packages..."
  local pkgs; pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/macos-base.txt")
  # shellcheck disable=SC2086
  run brew install $pkgs || true
}

install_security() {
  _info "[macos] Installing security tools..."
  local pkgs; pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/macos-security.txt")
  # shellcheck disable=SC2086
  run brew install $pkgs || true

  # GUI tools via cask
  run brew install --cask burp-suite ghidra || true
}

main() {
  install_base
  if [[ "$SECURITY" == "1" ]]; then install_security; fi
}

main "$@"
