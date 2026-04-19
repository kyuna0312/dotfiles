#!/usr/bin/env bash
# install-hyprland.sh — install Hyprland + deps on Manjaro (Intel+NVIDIA hybrid)
set -euo pipefail

info()  { printf "\033[38;5;219m[hypr]\033[0m %s\n" "$*"; }
ok()    { printf "\033[38;5;158m[  ok]\033[0m %s\n" "$*"; }

# ── 1. Core packages ──────────────────────────────────────────────────────────
info "Installing Hyprland and core Wayland tools..."
sudo pacman -S --noconfirm --needed \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    waybar \
    wofi \
    dunst \
    polkit-gnome \
    qt5-wayland \
    qt6-wayland \
    wl-clipboard \
    cliphist \
    grim \
    slurp \
    brightnessctl \
    playerctl \
    network-manager-applet \
    nwg-look
ok "Core packages installed"

# ── 2. NVIDIA modeset kernel param ───────────────────────────────────────────
info "Enabling nvidia-drm.modeset=1 in GRUB..."
GRUB_CFG="/etc/default/grub"
if grep -q "nvidia-drm.modeset=1" "$GRUB_CFG"; then
    ok "modeset already set"
else
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' "$GRUB_CFG"
    sudo update-grub
    ok "nvidia-drm.modeset=1 added — takes effect after reboot"
fi

# ── 3. NVIDIA env vars in hyprland.conf ──────────────────────────────────────
HYPR_CONF="$HOME/dotfiles/hyprland/hyprland.conf"
info "Adding NVIDIA env vars to hyprland.conf..."

if grep -q "LIBVA_DRIVER_NAME" "$HYPR_CONF"; then
    ok "NVIDIA env vars already present"
else
    # Insert after the AUTOSTART section
    NVIDIA_BLOCK='\n# ── NVIDIA (Intel+NVIDIA Prime hybrid) ──────────────────────────────────────\nenv = LIBVA_DRIVER_NAME,nvidia\nenv = XDG_SESSION_TYPE,wayland\nenv = GBM_BACKEND,nvidia-drm\nenv = __GLX_VENDOR_LIBRARY_NAME,nvidia\nenv = NVD_BACKEND,direct\nenv = ELECTRON_OZONE_PLATFORM_HINT,auto\ncursor {\n    no_hardware_cursors = true\n}\n'
    sed -i "/^exec-once = waybar/a\\${NVIDIA_BLOCK}" "$HYPR_CONF"
    ok "NVIDIA env vars added to hyprland.conf"
fi

# ── 4. SDDM display manager (to launch Hyprland from login screen) ───────────
info "Checking display manager..."
if ! pacman -Q sddm &>/dev/null; then
    sudo pacman -S --noconfirm --needed sddm
    sudo systemctl enable sddm
    ok "SDDM installed and enabled"
else
    ok "SDDM already installed"
fi

# ── 5. Link dotfiles ──────────────────────────────────────────────────────────
info "Re-running dotfiles install to ensure symlinks..."
bash "$HOME/dotfiles/install.sh"

printf "\n\033[38;5;219m✦ Hyprland ready ♡\033[0m\n"
printf "\nNext steps:\n"
printf "  1. Reboot to apply nvidia-drm.modeset=1\n"
printf "  2. At login screen — select 'Hyprland' session\n"
printf "  3. Run: bash ~/dotfiles/scripts/apply-theme.sh\n\n"
