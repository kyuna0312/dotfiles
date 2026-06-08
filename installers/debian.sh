#!/usr/bin/env bash
# installers/debian.sh — Debian/Ubuntu package installation
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/link.sh
source "${_DIR}/../lib/link.sh"
SECURITY="${1:-0}"

install_base() {
  _info "[debian] Updating package index..."
  run sudo apt-get update -qq

  local pkgs; pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/debian-base.txt")
  _info "[debian] Installing base packages..."
  # shellcheck disable=SC2086
  run sudo apt-get install -y --no-install-recommends $pkgs

  # bat ships as 'batcat' on some Debian/Ubuntu — alias to bat.
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi

  # fd ships as 'fdfind' from fd-find package on Debian/Ubuntu.
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi

  # starship (not in apt repos)
  if ! command -v starship >/dev/null 2>&1; then
    _info "[debian] Installing starship via official script..."
    if [[ "$DRY_RUN" == "1" ]]; then
      _info "[dry-run] would install starship via starship.rs script"
    else
      curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
  fi

  # eza (not in apt repos pre-Ubuntu 24.04)
  if ! command -v eza >/dev/null 2>&1; then
    _info "[debian] Installing eza..."
    if [[ "$DRY_RUN" == "1" ]]; then
      _info "[dry-run] would install eza (cargo or release tarball)"
    elif command -v cargo >/dev/null 2>&1; then
      cargo install eza
    else
      local arch; arch="$(dpkg --print-architecture)"
      local eza_url="https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz"
      mkdir -p "$HOME/.local/bin"
      curl -sL "$eza_url" | tar xz -C "$HOME/.local/bin/"
    fi
  fi
}

install_security() {
  _info "[debian] Installing security tools..."
  local pkgs; pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/debian-security.txt")

  # Kali repo if present, else standard apt with --fix-missing fallback.
  if grep -q "kali" /etc/apt/sources.list 2>/dev/null; then
    # shellcheck disable=SC2086
    run sudo apt-get install -y $pkgs
  else
    # shellcheck disable=SC2086
    run sudo apt-get install -y --fix-missing $pkgs || true
  fi

  # pwndbg (GDB enhancement for exploit development)
  local pwndbg_dir="$HOME/.local/share/pwndbg"
  if [[ ! -d "$pwndbg_dir" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      _info "[dry-run] would clone + setup pwndbg → $pwndbg_dir"
    else
      git clone https://github.com/pwndbg/pwndbg "$pwndbg_dir" --depth=1
      (cd "$pwndbg_dir" && ./setup.sh)
    fi
  fi
}

main() {
  install_base
  if [[ "$SECURITY" == "1" ]]; then install_security; fi
}

main "$@"
