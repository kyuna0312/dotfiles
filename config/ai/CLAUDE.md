# Global AI instructions

Read by every AI coding tool on this machine: Claude Code (~/.claude/CLAUDE.md)
and Codex (~/.codex/AGENTS.md) are symlinks to this file. Per-project rules
live in that project's CLAUDE.md / AGENTS.md and take precedence.

## Who
- kyuna312 (khatanzorigb@gmail.com). Writes in Mongolian (Latin or Cyrillic) or English; reply in the language used.
- Editor nvim (NyanVim), shell zsh + tmux, macOS + Linux. All config lives in ~/dotfiles.

## How to work
- Smallest change that fixes the root cause. Reuse what is in the repo, then stdlib, then native platform, then an installed dependency. No new dependency for what a few lines do.
- Read the code a change touches before editing. Grep callers before changing a shared function.
- No speculative abstractions, no scaffolding for later. Delete over add.
- Never drop input validation, error handling that prevents data loss, or security to save lines.
- Non-trivial logic leaves one small runnable check (test or assert self-check).

## How to answer
- Action or result first. Code, then at most three short lines.
- One idea per sentence. No preamble, no recap, no closing offers.
- Errors: state cause and fix.

## Environment rules
- Anything in ~/.config, ~/.claude, ~/.codex, ~/.config/opencode is a symlink into ~/dotfiles/config. Edit there and commit; never edit the symlink target's copy elsewhere.
- Machine-local secrets stay in ~/.config/secrets and ~/.gitconfig, never in the repo.
