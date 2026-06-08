# dotfiles

Linux (Manjaro/Arch) + macOS dotfiles. Managed by `install.sh`.

## Structure

- `install.sh` — main entry point (thin linker)
- `lib/link.sh` — symlink + logging helpers
- `home/` — files linked to `$HOME` (`.zshenv`, `.bashrc`)
- `config/` — mirrors `~/.config`, linked dir-by-dir
- `config/zsh/` — zsh entrypoint (`.zshrc`) + `lib/` modules
- `config/sheldon/` — zsh plugin manifest
- `installers/` — per-distro package scripts
- `packages/` — package lists
- `macos/`, `claude/` — special link targets (`~/...`, `~/.claude`)

## Constraints

- Scope: this repo only
- No global memory, no auto-skills, no session carryover
- Explicit requests only
