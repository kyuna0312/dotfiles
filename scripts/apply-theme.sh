#!/usr/bin/env bash
# apply-theme.sh — reload LUCY theme across all surfaces
set -euo pipefail

info()  { printf "\033[38;5;219m[theme]\033[0m %s\n" "$*"; }
ok()    { printf "\033[38;5;158m[  ok]\033[0m %s\n" "$*"; }
skip()  { printf "\033[38;5;246m[skip]\033[0m %s\n" "$*"; }

# ── GNOME (if running) ────────────────────────────────────────────────────────
if [[ "${XDG_CURRENT_DESKTOP:-}" == "GNOME" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface accent-color 'pink' 2>/dev/null || true
    ok "GNOME: dark mode + pink accent + adw-gtk3-dark"
fi

# ── Tmux ──────────────────────────────────────────────────────────────────────
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file ~/.config/tmux/tmux.conf
    ok "Tmux config reloaded"
else
    skip "No tmux session running"
fi

# ── Shell env ─────────────────────────────────────────────────────────────────
info "Shell (FZF/EZA/Starship): open a new terminal or run: exec zsh"

printf "\n\033[38;5;219m✦ LUCY theme applied ♡\033[0m\n\n"
