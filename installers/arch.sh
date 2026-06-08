#!/usr/bin/env bash
# installers/arch.sh — Arch/Manjaro package installation
set -euo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/link.sh
source "${_DIR}/../lib/link.sh"
SECURITY="${1:-0}"

install_aur_helper() {
  if ! command -v paru >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1; then
    _info "[arch] Installing paru AUR helper..."
    if [[ "$DRY_RUN" == "1" ]]; then
      _info "[dry-run] would clone + makepkg paru-bin"
      return 0
    fi
    local tmp; tmp="$(mktemp -d)"
    git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm) \
      || { _warn "[arch] paru install failed, continuing without AUR helper"; rm -rf "$tmp"; return 0; }
    rm -rf "$tmp"
  fi
  AUR_CMD="$(command -v paru 2>/dev/null || command -v yay 2>/dev/null)"
}

install_base() {
  _info "[arch] Syncing and installing base packages..."
  local pkgs; pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/arch-base.txt")
  # shellcheck disable=SC2086
  run sudo pacman -Syu --noconfirm --needed $pkgs
  run sudo systemctl enable --now docker >/dev/null 2>&1 || true
}

install_security() {
  _info "[arch] Installing security tools..."
  local pkgs; pkgs=$(_parse_pkg_list "${REPO_ROOT}/packages/arch-security.txt")

  # Try pacman first; AUR fallback for packages not in official repos.
  # shellcheck disable=SC2086
  run sudo pacman -S --noconfirm --needed $pkgs 2>/dev/null || true

  install_aur_helper
  if [[ -n "${AUR_CMD:-}" ]]; then
    run "$AUR_CMD" -S --noconfirm --needed \
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
  if [[ "$SECURITY" == "1" ]]; then install_security; fi
}

main "$@"
