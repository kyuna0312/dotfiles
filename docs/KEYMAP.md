# Keymap

Part of [NIGHT CITY dotfiles](../README.md).


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
| `alt-s/t/o/g` | Quick-launch Safari / Telegram / Obsidian / Ghostty | AeroSpace |
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
| `shift-w` | Warp | | `i` | Discord |
| | | | `l` | LINE |
| `c` | Cursor | | `shift-v` | Viber |
| `v` | Visual Studio Code | | `m` | Spotify |
| `x` | Xcode | | `shift-s` | Steam |
| `d` | Docker | | `shift-b` | Blender |
| `shift-d` | DBeaver | | `shift-u` | Audacity |
| `p` | Postman | | `shift-p` | Burp Suite |
| `shift-f` | FileZilla | | `h` | Hydra |
