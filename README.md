<div align="center">

<img src="logo.png" width="120" alt="Lucy Edgerunner+" />

# ✦ Lucy Edgerunner+ Dotfiles

**Cyberpunk Edgerunners-themed development environment**  
Hyprland · Neovim · Zsh · Tmux · Starship · Ghostty

[![License](https://img.shields.io/github/license/kyuna0312/dotfiles?color=ff6bba&labelColor=0a0a14)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch%20%7C%20Debian%20%7C%20macOS-00e5ff?labelColor=0a0a14)](install.sh)
[![Stars](https://img.shields.io/github/stars/kyuna0312/dotfiles?color=ffd97d&labelColor=0a0a14)](https://github.com/kyuna0312/dotfiles)

</div>

---

## Quick Install

```bash
git clone https://github.com/kyuna0312/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh
```

Or directly, without cloning:

```bash
# curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/kyuna0312/dotfiles/main/install.sh)"

# wget
sh -c "$(wget -qO- https://raw.githubusercontent.com/kyuna0312/dotfiles/main/install.sh)"
```

> **Re-link only** (skip package installs): `bash install.sh --skip-packages`  
> **With pentest tools**: `bash install.sh --security`

---

## What's Included

| Component | Config path | Description |
|-----------|-------------|-------------|
| **Zsh** | `zshrc/.zshrc` → `shell/zsh/` | Modular OS-split shell; Lucy greeting, fzf, zoxide, lazy NVM |
| **Starship** | `starship/starship.toml` | `λ` prompt, Lucy Edgerunner+ palette, OS badge, git status |
| **Neovim** | `nvim/` | LazyVim base + Lucy catppuccin overrides, custom dashboard |
| **Tmux** | `tmux/tmux.conf` | TPM, vim pane nav, sakura/cyan status bar, session restore |
| **Ghostty** | `ghostty/config.linux` | Void-black bg, neon 16-color ANSI palette |
| **Hyprland** | `hyprland/` | Sakura→cyan window borders, blur, pink shadow glow |
| **Waybar** | `waybar/` | Void-dark bar, pill modules, Lucy-themed module colors |
| **Git** | `git/delta.gitconfig` | Delta pager with Lucy syntax colors |
| **Nushell** | `nushell/` | `λ` and `❮` prompt indicators, custom env |
| **Atuin** | `atuin/config.toml` | Encrypted shell history sync |
| **Security** | `security/aliases.zsh` | Pentest alias layer (`sectools` for reference) |
| **Claude Code** | `claude/` | settings.json, Inari MCP server, caveman mode, code-review skill |

---

## OS Support

| OS | Package manager | Notes |
|----|----------------|-------|
| **Arch / Manjaro** | pacman + paru (AUR) | Full support: Hyprland, Waybar, Ghostty |
| **Debian / Ubuntu** | apt | `bat`→`batcat`, `fd`→`fdfind` aliased automatically |
| **macOS** | Homebrew | Aerospace, Sketchybar, Hammerspoon, Karabiner |

---

## Color Palette — Lucy Edgerunner+

| Name | Hex | Role |
|------|-----|------|
| **Void** | `#0a0a14` | background |
| **Surface** | `#11111e` | panels, tmux bg |
| **Sakura** | `#ff6bba` | primary accent, active borders |
| **Neon Cyan** | `#00e5ff` | secondary accent, clock, links |
| **Lavender** | `#c8a5ff` | git, builtins, audio |
| **Mint** | `#9dffcc` | paths, CPU, success |
| **Gold** | `#ffd97d` | time, memory, warnings |
| **Rose** | `#ff4d8d` | errors, critical, temp high |
| **Text** | `#f0e6ff` | foreground |

---

## Shell Features

### Lucy Zsh Layer (`shell/zsh/lucy.zsh`)

Sourced last, after syntax highlighting. Provides:

| Command | Description |
|---------|-------------|
| `lucy` | Identity card with system info |
| `jack-in <host>` | Styled SSH wrapper |
| `flatline <name>` | Kill process by name (`pkill -f`) |
| `breach [dir]` | `cd` into directory then open `$EDITOR` |
| `ghost` | Browse history with fzf and re-run |
| `ports` | Open listening ports (`ss -tulnp`) |
| `dp-tools` | CLI stack reference card |
| `netrunner-tools` | Alias for `dp-tools` |

### Security Layer (`security/aliases.zsh`)

Auto-loaded when `nmap` or `burpsuite` is detected. Run `sectools` for a quick reference.

| Category | Tools |
|----------|-------|
| Network | `nmap`, `nse`, `nnmap`, `sniff`, `sniffport` |
| Web | `bsuite`, `sqlm`, `nik` |
| Passwords | `jtr`, `hcat` |
| Reverse Eng | `ghidra-launch`, `r2` |
| CTF | `b64d`, `b64e`, `hexdump-clean`, `rot13` |

---

## Configuration

### Git identity

Put user-specific git config in `~/.gitconfig.local` (not tracked):

```ini
[user]
    name = Your Name
    email = you@example.com
    signingkey = GPGKEYID

[commit]
    gpgsign = true
```

### NVM lazy loading

`nvm`, `node`, `npm`, `npx` are stub functions — NVM loads on first call to keep shell startup fast. Run `nvm` once to initialize.

### Kubectl completion

Set `CYBERPUNK_KUBECTL_COMPLETION=0` to disable kubectl completion (removes startup latency when kubectl is installed but not actively used).

### Hyprland (Arch/Manjaro only)

First-time setup requires the full compositor stack:

```bash
bash ~/dotfiles/scripts/install-hyprland.sh
# Reboot → select Hyprland at SDDM login
bash ~/dotfiles/scripts/apply-theme.sh
```

Configs land at `~/.config/hypr/` and `~/.config/waybar/`.

### Tmux plugins

On first launch, install TPM plugins:

```
Start tmux → Ctrl+I
```

### Neovim

On first launch, sync all plugins:

```
nvim → :Lazy sync
```

### Inari MCP Server (local AI for Claude Code)

Inari routes Claude Code prompts to local Ollama models:

| Task | Model |
|------|-------|
| write / fix / complete / test code | Qwen3 8B |
| explain / design / analyze / plan | Llama 4 Scout |

```bash
# Enable Ollama
sudo systemctl enable --now ollama

# Add to dotfiles/claude/settings.json under "mcpServers":
{
  "inari": {
    "command": "uv",
    "args": ["run", "--project", "/home/kyuna/dotfiles/claude/mcp-servers/inari",
             "python", "server.py"]
  }
}
```

---

## Directory Structure

```
dotfiles/
├── install.sh              # bootstrap (packages + symlinks)
├── installers/             # per-distro package installers
│   ├── arch.sh
│   ├── debian.sh
│   └── macos.sh
├── packages/               # package lists (edit to add tools)
│   ├── arch-base.txt
│   ├── arch-security.txt
│   └── ...
├── zshrc/                  # .zshrc OS-detection entrypoint
├── shell/zsh/
│   ├── common.zsh          # shared: aliases, fzf, nvm, zoxide
│   ├── linux.zsh           # Linux: tmux auto-attach, EDITOR, security
│   ├── macos.zsh           # macOS specifics
│   └── lucy.zsh            # Lucy layer: greeting, themed helpers
├── starship/starship.toml
├── nvim/                   # LazyVim config
├── tmux/tmux.conf
├── ghostty/
│   ├── config.linux
│   └── config.macos
├── hyprland/               # Wayland WM (Arch/Linux only)
├── waybar/                 # Status bar (Arch/Linux only)
├── git/delta.gitconfig
├── nushell/
├── atuin/
├── security/aliases.zsh
├── scripts/
│   ├── apply-theme.sh      # hot-reload all running apps
│   └── install-hyprland.sh # first-time Hyprland setup
└── claude/
    ├── settings.json
    ├── mcp-servers/inari/  # local Ollama AI layer
    └── skills/code-reviewer/
```

---

## Prerequisites

- `git`, `zsh`, `curl`
- Recommended: `neovim`, `tmux`, `starship`, `fzf`, `eza`
- Hyprland: Arch/Manjaro only — run `install-hyprland.sh`
- Inari AI: `ollama`, `uv`

---

<div align="center">

**Lucy Kushinada — Netrunner Online**  
<sub>built with ✦ and neon pink</sub>

</div>
