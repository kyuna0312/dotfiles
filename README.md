<div align="center">

<img src="assets/logo.png" width="120" alt="NIGHT CITY" />

# ✦ NIGHT CITY Dotfiles

**Cyberpunk: Edgerunners-themed development environment — one palette, ten tools**  
Neovim · Zsh · Tmux · Starship · Ghostty · WezTerm · Kitty · AeroSpace · Übersicht · Zellij

[![License](https://img.shields.io/github/license/kyuna0312/dotfiles?color=2bbcd5&labelColor=101a1f)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Mint%20%7C%20Debian%20%7C%20Arch%20%7C%20macOS-0cc7c2?labelColor=101a1f)](install.sh)
[![Stars](https://img.shields.io/github/stars/kyuna0312/dotfiles?color=f2c74b&labelColor=101a1f)](https://github.com/kyuna0312/dotfiles)

</div>

---

## Preview

<div align="center">

<img src="assets/preview.png" width="820" alt="NIGHT CITY desktop — Neovim in tmux, teal palette, Aeroline bar on the right" />

<sub>Neovim + tmux in the teal Night City palette · Aeroline vertical bar (right edge) with AeroSpace workspaces + clock · Starship `λ` prompt with git status</sub>

</div>

---

## Quick Install

```bash
git clone --recurse-submodules https://github.com/kyuna0312/dotfiles ~/dotfiles
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
| **Zsh** | `home/.zshenv` → `config/zsh/.zshrc` + `lib/` | Modular OS-split shell; NIGHT CITY greeting, fzf, zoxide, lazy NVM |
| **Starship** | `config/starship/starship.toml` | `λ` prompt, NIGHT CITY ribbon on stack tokens, OS badge, git status |
| **Neovim** | `config/nvim/` → [NyanVim](https://github.com/kyuna0312/NyanVim) v1.4 | ~30 ms startup, live theme switcher, `:Nyan*` menu, git-ignored `lua/user/` overrides; Night City Mix via nightcity.nvim (git submodule) · [nyanvim.vercel.app](https://nyanvim.vercel.app) |
| **Themes** | `themes/night-city-palettes/` → [night-city-palettes](https://github.com/kyuna0312/night-city-palettes) | Palette source of truth (git submodule); Ghostty/Kitty/WezTerm include their colors from it via `~/.config/themes` |
| **Tmux** | `config/tmux/tmux.conf` | Teal window tabs, undercurl passthrough, sessionx/floax popups, AI-CLI popups |
| **Ghostty** | `config/ghostty/config` | Full 16-color Night City Mix palette, teal cursor, 0.8 opacity + blur |
| **WezTerm** | `config/wezterm/wezterm.lua` | Same palette in lua; yellow active tab bar |
| **Kitty** | `config/kitty/kitty.conf` | Same palette + cmd-based keybindings mirroring Ghostty |
| **Übersicht** | `macos/ubersicht/` | [Aeroline](https://github.com/kyuna0312/aeroline) — right-edge vertical bar: AeroSpace workspaces + clock (sketchybar is horizontal-only) |
| **AeroSpace** | `macos/aerospace/aerospace.toml` | Tiling WM + JankyBorders teal focus ring |
| **Zellij** | `config/zellij/config.kdl` | Custom `nightcity` theme |
| **Nushell** | `config/nushell/` | Explicit-hex `nightcity_theme` color_config |
| **Git** | `config/git/config` + `delta.gitconfig` | Shared aliases + delta pager with NIGHT CITY syntax colors |
| **Atuin** | `config/atuin/config.toml` | Shell history search (sync-ready) |
| **Security** | `config/zsh/lib/security.zsh` | Pentest alias layer (`sectools` for reference) |

---

## OS Support

| OS | Package manager | Notes |
|----|----------------|-------|
| **Arch / Manjaro** | pacman + paru (AUR) | Full support |
| **Debian / Ubuntu** | apt | `bat`→`batcat`, `fd`→`fdfind` aliased automatically |
| **macOS** | Homebrew | Aerospace, Übersicht, Hammerspoon, Karabiner |

---

## Color Palette — Night City Mix

One token set across every tool — terminal, editor, prompt, bar, window borders.
Based on **[Night City Mix](https://github.com/kyuna0312/night-city-palettes)**
— a gamma-correct blend of Box UK Contrast, Solarized Osaka and Cyberpunk Lucy:
calm blue-grey grounds with a neon pop, easy on the eyes. It's the blend
palette of [kyuna0312/night-city-palettes](https://github.com/kyuna0312/night-city-palettes)
— a four-palette collection that carries the whole design kit: drop-in terminal themes, a matching
[desktop wallpaper](https://github.com/kyuna0312/night-city-palettes/tree/main/wallpapers),
and a [teal folder icon](https://github.com/kyuna0312/night-city-palettes/tree/main/extras)
with an apply script.

| Name | Hex | Role |
|------|-----|------|
| **Blue-Grey** | `#101a1f` | the ground everywhere — terminal, editor, bar |
| **Surface** | `#15242d` / `#1d2c36` | panels, floats, inactive tabs |
| **Cyan** | `#2bbcd5` | active only: current tab, selected row, keywords, focus |
| **Yellow** | `#f2c74b` | active tab background, warnings, modified |
| **Teal** | `#0cc7c2` | where attention goes: cursor mode, links, clock, strings |
| **Green** | `#49d575` | structure: functions, classes, attributes |
| **Purple** | `#be59d6` | secondary accent: picker frame, dates, numbers |
| **Coral** | `#f37c4b` | errors, deleted lines |
| **Grey-Blue FG** | `#b6c5d3` | running text on the blue-grey ground |

---

## Keymap

tmux prefix is **`C-Space`** (`C-b` unbound). Press the prefix, then the key.

| Key | Action | Scope |
|-----|--------|-------|
| `prefix i` | NyanVim session manager for this directory | tmux |
| `prefix s` | sessionx — jump / kill sessions | tmux |
| `prefix p` | floax floating pane | tmux |
| `prefix y` | Claude Code popup for this directory | tmux |
| `prefix Y` | Claude Code in a split | tmux |
| `prefix o` | opencode popup for this directory | tmux |
| `prefix g` | lazygit popup | tmux |
| `prefix F` | Open this directory in Finder | tmux |
| `prefix \|` / `prefix -` | Split vertical / horizontal | tmux |
| `prefix c` | New window in cwd | tmux |
| `C-S-←/→` | Reorder windows | tmux |
| `alt-hjkl` | Focus window left/down/up/right | AeroSpace |
| `alt-shift-hjkl` | Move window left/down/up/right | AeroSpace |
| `alt-1…9` | Jump to workspace | AeroSpace |
| `alt-shift-1…9` | Move window to workspace | AeroSpace |
| `alt-f` / `alt-q` | Toggle float-tiling / close window | AeroSpace |
| `alt-s/t/o/g` | Quick-launch Safari / Telegram / Obsidian / WezTerm | AeroSpace |
| `alt-shift-enter` | Enter the app launcher (`apps` mode) | AeroSpace |
| `alt-shift-z` | Toggle the Übersicht bar (HUD) | AeroSpace |

---

## App Launcher

Press **`alt-shift-enter`** to enter `apps` mode, then one key to open an app
(it drops back to the main mode afterwards). **`esc`** leaves without launching.
A `shift-` variant is the second app sharing a letter.

| Key | App | | Key | App |
|-----|-----|-|-----|-----|
| `b` | Brave Browser | | `a` | Claude |
| `f` | Firefox | | `shift-a` | ChatGPT |
| `s` | Safari | | `o` | Obsidian |
| `z` | Zen | | `t` | Telegram |
| `g` | Ghostty | | `shift-t` | TeamViewer |
| `w` | WezTerm | | `i` | Discord |
| `shift-w` | Warp | | `l` | LINE |
| `c` | Cursor | | `shift-v` | Viber |
| `v` | Visual Studio Code | | `m` | Spotify |
| `x` | Xcode | | `shift-s` | Steam |
| `d` | Docker | | `shift-b` | Blender |
| `shift-d` | DBeaver | | `shift-u` | Audacity |
| `p` | Postman | | `shift-p` | Burp Suite |
| `shift-f` | FileZilla | | `h` | Hydra |

---

## Shell Features

Zsh uses `ZDOTDIR=~/.config/zsh` (set by `home/.zshenv`), so all zsh config lives under `config/zsh/`. Plugins are managed by [Sheldon](https://sheldon.cli.rs/) (`config/sheldon/plugins.toml`).

### NIGHT CITY Zsh Layer (`config/zsh/lib/nightcity.zsh`)

Sourced last, after syntax highlighting. Provides:

| Command | Description |
|---------|-------------|
| `nightcity` | Identity card with system info |
| `jack-in <host>` | Styled SSH wrapper |
| `flatline <name>` | Kill process by name (`pkill -f`) |
| `breach [dir]` | `cd` into directory then open `$EDITOR` |
| `ghost` | Browse history with fzf and re-run |
| `ports` | Open listening ports (`ss -tulnp`) |

> `dp-tools` (alias `nightcity-tools`) prints the CLI stack reference card — defined in `config/zsh/lib/common.zsh`.

### Security Layer (`config/zsh/lib/security.zsh`)

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

Shared git config (aliases, editor, delta) is tracked in `config/git/config`.
Machine-local identity stays in `~/.gitconfig`, which git reads last so it
overrides anything shared:

```ini
[user]
    name = Your Name
    email = you@example.com
```

### NVM lazy loading

`nvm`, `node`, `npm`, `npx` are stub functions — NVM loads on first call to keep shell startup fast. Run `nvm` once to initialize.

### Kubectl completion

Set `CYBERPUNK_KUBECTL_COMPLETION=0` to disable kubectl completion (removes startup latency when kubectl is installed but not actively used).

### Tmux plugins

On first launch, install TPM plugins:

```
Start tmux → prefix + I   (C-Space, then Shift-i)
```

### Neovim

Plugins install themselves on the first launch, pinned to NyanVim's
`lazy-lock.json`. Then:

```
:NyanHealth     " check tools, compiler, Nerd Font
:NyanConfig     " your overrides in lua/user/ (git-ignored, survive updates)
:NyanUpdate     " git pull + :Lazy restore
```

Keys: `Space` then wait (which-key), `Space t h` theme picker, `Space n` NyanVim menu.
Docs: [docs/wiki](https://github.com/kyuna0312/NyanVim/tree/main/docs/wiki) · site: [nyanvim.vercel.app](https://nyanvim.vercel.app)

---

## Directory Structure

```
dotfiles/
├── install.sh              # thin linker (packages + symlinks)
├── lib/link.sh             # symlink + logging helpers
├── home/                   # files linked to $HOME
│   ├── .zshenv             # sets ZDOTDIR=~/.config/zsh
│   └── .bashrc             # minimal bash fallback
├── config/                 # mirrors ~/.config, linked dir-by-dir
│   ├── zsh/
│   │   ├── .zshrc          # zsh entrypoint
│   │   └── lib/
│   │       ├── common.zsh   # shared: aliases, fzf, nvm, zoxide
│   │       ├── linux.zsh    # Linux: tmux auto-attach, EDITOR, security
│   │       ├── macos.zsh    # macOS specifics
│   │       ├── nightcity.zsh    # NIGHT CITY layer: greeting, themed helpers
│   │       └── security.zsh # pentest alias layer
│   ├── sheldon/plugins.toml # zsh plugin manifest (Sheldon)
│   ├── starship/starship.toml
│   ├── nvim/               # NyanVim (git submodule)
│   ├── tmux/tmux.conf
│   ├── ghostty/config
│   ├── kitty/kitty.conf
│   ├── wezterm/wezterm.lua
│   ├── zellij/config.kdl
│   ├── git/                # config (shared) + delta.gitconfig + ignore
│   ├── bat/config
│   ├── nushell/
│   └── atuin/
├── installers/             # per-distro package installers
│   ├── arch.sh
│   ├── debian.sh
│   └── macos.sh
├── packages/               # package lists (edit to add tools)
│   ├── arch-base.txt
│   ├── arch-security.txt
│   └── ...
├── macos/                  # aerospace, ubersicht, skhd, karabiner, hammerspoon
├── scripts/
│   └── apply-theme.sh      # hot-reload running apps
└── assets/                 # README images (preview.png, logo.png)
```

---

## Related projects

Split out of this repo so they're reusable on their own:

- **[night-city-palettes](https://github.com/kyuna0312/night-city-palettes)** — a four-palette collection (Box UK Contrast, Solarized Osaka, Cyberpunk Lucy, Night City Mix) as a portable design kit: drop-in terminal themes, a matching desktop wallpaper, and a teal folder icon.
- **[aeroline](https://github.com/kyuna0312/aeroline)** — the vertical Übersicht + AeroSpace status bar (right-edge workspaces + clock), one-block themeable.
- **[NyanVim](https://github.com/kyuna0312/NyanVim)** — the Neovim distribution linked in as `config/nvim` (git submodule): NvChad-class startup, LunarVim-style `:Nyan*` menu and try-before-you-switch installer, doom-style user layer. Website: [nyanvim.vercel.app](https://nyanvim.vercel.app).

---

## Prerequisites

- `git`, `zsh`, `curl`
- Recommended: `neovim`, `tmux`, `starship`, `fzf`, `eza`

---

<div align="center">

**NIGHT CITY — Netrunner Online**  
<sub>built with ✦ and calm teal</sub>

</div>
