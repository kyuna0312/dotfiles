#!/usr/bin/env bash
# installers/arch.sh — Arch/Manjaro package installation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECURITY="${1:-0}"

_parse_pkg_list() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$'
}

install_aur_helper() {
  # Install paru if no AUR helper present
  if ! command -v paru >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1; then
    echo "[arch] Installing paru AUR helper..."
    local tmp
    tmp="$(mktemp -d)"
    git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm) || { echo "[arch] paru install failed, continuing without AUR helper"; rm -rf "$tmp"; return 0; }
    rm -rf "$tmp"
  fi
  AUR_CMD="$(command -v paru 2>/dev/null || command -v yay 2>/dev/null)"
}

install_base() {
  echo "[arch] Syncing and installing base packages..."
  local pkgs
  pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/arch-base.txt")
  # shellcheck disable=SC2086
  sudo pacman -Syu --noconfirm --needed $pkgs
  sudo systemctl enable --now docker >/dev/null 2>&1 || true
}

install_security() {
  echo "[arch] Installing security tools..."
  local pkgs
  pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/arch-security.txt")

  # Try pacman first, AUR fallback for packages not in official repos
  # shellcheck disable=SC2086
  sudo pacman -S --noconfirm --needed $pkgs 2>/dev/null || true

  # AUR packages not in official repos
  install_aur_helper
  if [[ -n "${AUR_CMD:-}" ]]; then
    "$AUR_CMD" -S --noconfirm --needed \
      burpsuite \
      pwndbg \
      volatility3 \
      impacket \
      crackmapexec 2>/dev/null || true
  fi

  # BlackArch security repo (optional, uncomment to enable full pentest suite)
  # curl -O https://blackarch.org/strap.sh && chmod +x strap.sh && sudo ./strap.sh
}

main() {
  install_base
  [[ "$SECURITY" == "1" ]] && install_security
}

main "$@"
