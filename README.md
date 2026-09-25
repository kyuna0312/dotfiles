<div align="center">

<img src="assets/logo.png" width="120" alt="NIGHT CITY" />

# ✦ NIGHT CITY Dotfiles

**Cyberpunk: Edgerunners-themed development environment — one palette, every tool**  
Neovim · Zsh · Tmux · Starship · Ghostty · Kitty · AeroSpace · Übersicht · Zellij

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

Needs `git`, `zsh` and `curl`; everything else comes from `packages/`.

```bash
git clone --recurse-submodules https://github.com/kyuna0312/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh
```

> **Re-link only** (after editing configs): `bash install.sh --skip-packages`  
> **With pentest tools**: `bash install.sh --security`  
> **Preview**: `bash install.sh --dry-run`

The installer backs up anything it replaces as `<file>.bak.<timestamp>`, links every
`config/*` dir into `~/.config`, and ends with the short list of steps macOS still
needs by hand (Accessibility for AeroSpace/Karabiner, the Übersicht widget).

**Update**

```bash
cd ~/dotfiles && git pull --recurse-submodules && bash install.sh --skip-packages
git submodule update --remote config/nvim config/emacs config/ai/clean-code-skills   # newer NyanVim / NyanEmacs / clean-code
```

**Undo**: every file the installer replaced is next to its symlink as `<name>.bak.<timestamp>`;
remove the symlink and rename the backup. There is no uninstall script on purpose.

---

## What's Included

| Component | Config path | Description |
|-----------|-------------|-------------|
| **Zsh** | `home/.zshenv` → `config/zsh/.zshrc` + `lib/` | Modular OS-split shell; NIGHT CITY helpers, fzf, zoxide; nvm only on `nvm use` |
| **Starship** | `config/starship/starship.toml` | `λ` prompt, NIGHT CITY ribbon on stack tokens, OS badge, git status |
| **Neovim** | `config/nvim/` → [NyanVim](https://github.com/Nyanko-labs/NyanVim) v1.4 | ~30 ms startup, live theme switcher, `:Nyan*` menu, git-ignored `lua/user/` overrides; Night City Mix via nightcity.nvim (git submodule) · [nyanvim.vercel.app](https://nyanvim.vercel.app) |
| **Emacs** | `config/emacs/` → [NyanEmacs](https://github.com/Nyanko-labs/NyanEmacs) | NyanVim's keys (evil + `<space>` leader) and Night City Mix theme on [Centaur Emacs](https://github.com/seagle0128/.emacs.d)'s layout; eglot, vertico/consult, corfu, magit, treemacs, `M-x nyan-*` menu, git-ignored `user.el` |
| **Themes** | `themes/night-city-palettes/` → [night-city-palettes](https://github.com/kyuna0312/night-city-palettes) | Palette source of truth (git submodule); Ghostty/Kitty include their colors from it via `~/.config/themes` |
| **AI tools** | `config/ai/` | One `CLAUDE.md` read by Claude Code and Codex; Claude `settings.json` (plugins, model) + Night City status line; `clean-code` skill (git submodule) linked into every tool; opencode agent, commands and theme |
| **Tmux** | `config/tmux/tmux.conf` | Teal window tabs, undercurl passthrough, sessionx/floax popups, AI-CLI popups |
| **Ghostty** | `config/ghostty/config` | Full 16-color Night City Mix palette, teal cursor, 0.8 opacity + blur |
| **Kitty** | `config/kitty/kitty.conf` | Same palette + cmd-based keybindings mirroring Ghostty |
| **Übersicht** | `macos/ubersicht/` | [Aeroline](https://github.com/kyuna0312/aeroline) — right-edge vertical bar: AeroSpace workspaces + clock (sketchybar is horizontal-only) |
| **AeroSpace** | `macos/aerospace/aerospace.toml` | Tiling WM + JankyBorders teal focus ring; app-launcher mode ([keymap](docs/KEYMAP.md)) |
| **Karabiner / Alfred** | `macos/karabiner/`, `macos/alfred/` | Key remaps and launcher preferences |
| **Zellij** | `config/zellij/config.kdl` | Custom `nightcity` theme |
| **Nushell** | `config/nushell/` | Explicit-hex `nightcity_theme` color_config |
| **Git** | `config/git/config` + `delta.gitconfig` | Shared aliases + delta pager with NIGHT CITY syntax colors |
| **Atuin** | `config/atuin/config.toml` | Shell history search (sync-ready) |
| **Security** | `config/zsh/lib/security.zsh` | Pentest alias layer (`sectools` for reference) |

---

## OS Support

| OS | Package manager | Notes |
|----|----------------|-------|
| **Arch / Manjaro** | pacman + paru (AUR) | Full support; pentest extras from the AUR |
| **Debian / Ubuntu** | apt | `bat`→`batcat`, `fd`→`fdfind` linked; starship and eza from their release scripts; lazygit, delta, atuin, sheldon are not in apt (the shell degrades gracefully, sheldon is fetched by the installer) |
| **macOS** | Homebrew | formulae from `packages/macos-base.txt`, apps and the Nerd Font from `packages/macos-cask.txt` |

Package names missing from a distro are skipped with a warning, never fatal.

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

tmux prefix is **`C-Space`**. Every tmux, AeroSpace and app-launcher binding → [docs/KEYMAP.md](docs/KEYMAP.md).

---

## Shell Features

Zsh uses `ZDOTDIR=~/.config/zsh` (set by `home/.zshenv`), so all zsh config lives under `config/zsh/`. Plugins are managed by [Sheldon](https://sheldon.cli.rs/) (`config/sheldon/plugins.toml`).

### NIGHT CITY Zsh Layer (`config/zsh/lib/nightcity.zsh`)

Sourced last, after syntax highlighting. Provides:

| Command | Description |
|---------|-------------|
| `nightcity` | Identity card with system info |
| `jack-in <host>` | Styled SSH wrapper |
| `flatline <name>` | Kill processes named exactly `<name>` (`pkill -x`) |
| `breach [dir]` | `cd` into directory then open `$EDITOR` |
| `ghost` | Browse history with fzf and re-run |
| `ports` | Open listening ports (`ss` on Linux, `lsof` on macOS) |

> `dp-tools` (alias `nightcity-tools`) prints the CLI stack reference card — defined in `config/zsh/lib/common.zsh`.

### Security Layer (`config/zsh/lib/security.zsh`)

Auto-loaded when `nmap` or `burpsuite` is detected. Run `sectools` for a quick reference.

| Category | Tools |
|----------|-------|
| Network | `nse`, `nnmap`, `listen`, `myip`, `sniff`, `sniffport` |
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

### AI tools (`config/ai/`)

One place for every AI coding tool, so a new machine (or a new project) starts with the same rules:

| File | Linked to | Purpose |
|------|-----------|---------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` | global instructions, read in every project; a project's own `CLAUDE.md` adds to it |
| `claude/settings.json` | `~/.claude/settings.json` | plugins, marketplaces, model, permissions |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Night City status line (tmux palette) |
| `skills/<name>/` | `~/.claude/skills/<name>`, `~/.codex/skills/<name>` | one link per skill; `clean-code` comes from the [clean-code-skills](https://github.com/kyuna0312/clean-code-skills) submodule |
| `agents/` | `~/.claude/agents` | custom subagents |
| `opencode/` | `~/.config/opencode` | the `nyan` agent, `nyan-*` commands, theme |

Add a skill: drop a folder with a `SKILL.md` into `config/ai/skills/` and re-run `bash install.sh --skip-packages`.
`~/.claude` and `~/.codex` otherwise stay machine state (sessions, caches); only these files are linked.

### Node

`node` is the package manager's. `nvm` is a stub that loads `~/.nvm` on first call, for projects pinned to another version (`nvm use 22`); it never shadows `node`/`npm`.

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
Docs: [docs/wiki](https://github.com/Nyanko-labs/NyanVim/tree/main/docs/wiki) · site: [nyanvim.vercel.app](https://nyanvim.vercel.app)

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
│   ├── ai/                 # every AI tool: CLAUDE.md, claude/, skills/, agents/, opencode/, clean-code-skills (submodule)
│   ├── zsh/
│   │   ├── .zshrc          # zsh entrypoint
│   │   └── lib/
│   │       ├── common.zsh   # shared: aliases, fzf, zoxide
│   │       ├── linux.zsh    # Linux: tmux auto-attach, EDITOR, security
│   │       ├── macos.zsh    # macOS specifics
│   │       ├── nightcity.zsh    # NIGHT CITY layer: greeting, themed helpers
│   │       └── security.zsh # pentest alias layer
│   ├── sheldon/plugins.toml # zsh plugin manifest (Sheldon)
│   ├── starship/starship.toml
│   ├── nvim/               # NyanVim (git submodule)
│   ├── emacs/              # NyanEmacs (git submodule)
│   ├── tmux/tmux.conf
│   ├── ghostty/config
│   ├── kitty/kitty.conf
│   ├── zellij/config.kdl
│   ├── git/                # config (shared) + delta.gitconfig + ignore
│   ├── bat/config
│   ├── nushell/
│   ├── atuin/
│   └── themes -> ../themes/night-city-palettes
├── themes/night-city-palettes  # palette source of truth (git submodule)
├── docs/KEYMAP.md          # tmux, AeroSpace and launcher bindings
├── installers/             # per-distro package installers
│   ├── arch.sh
│   ├── debian.sh
│   └── macos.sh
├── packages/               # package lists (edit to add tools)
│   ├── arch-base.txt
│   ├── macos-cask.txt      # macOS apps + Nerd Font
│   └── ...
├── macos/                  # aerospace, ubersicht, karabiner, alfred
├── scripts/
│   └── apply-theme.sh      # hot-reload running apps
└── assets/                 # README images (preview.png, logo.png)
```

---

## Related projects

Split out of this repo so they're reusable on their own:

- **[night-city-palettes](https://github.com/kyuna0312/night-city-palettes)** — a four-palette collection (Box UK Contrast, Solarized Osaka, Cyberpunk Lucy, Night City Mix) as a portable design kit: drop-in terminal themes, a matching desktop wallpaper, and a teal folder icon.
- **[aeroline](https://github.com/kyuna0312/aeroline)** — the vertical Übersicht + AeroSpace status bar (right-edge workspaces + clock), one-block themeable.
- **[NyanVim](https://github.com/Nyanko-labs/NyanVim)** — the Neovim distribution linked in as `config/nvim` (git submodule): NvChad-class startup, LunarVim-style `:Nyan*` menu and try-before-you-switch installer, doom-style user layer. Website: [nyanvim.vercel.app](https://nyanvim.vercel.app).

---


<div align="center">

**NIGHT CITY — Netrunner Online**  
<sub>built with ✦ and calm teal</sub>

</div>
