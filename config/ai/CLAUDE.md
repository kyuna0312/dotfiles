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
- A file write is not working code. Run the project's verify commands (from its CLAUDE.md, Makefile or package.json) before saying "done"; report failures with their output.
- Rename = several greps: calls, types, string literals, config keys, tests. One grep is not enough.
- Ask before adding a dependency, entitlement or changing the stack. Check the neighbouring file and match its style.
- Commit and push only when asked. Never push to `main` directly on a repo that uses PRs.

## Clean code (summary; depth in the `clean-code` skill, `~/.claude/skills/clean-code/SKILL.md`)
- Load the `clean-code` skill before non-trivial writing, review or refactoring. Read `.clean/*` first if the project has it; a recorded decision is settled.
- Dependencies point inward: business rules never name the DB, web, UI or framework. SQL stays in the data layer; rows and request objects never travel inward.
- Placement: mirror where similar files live; wire a new file completely (imports, exports, registration) or it is dead code. No `_v2` / `_new` / `_copy` siblings, no `utils`/`helpers` junk drawers.
- One job per unit at every scale. If it needs "and" to describe, split it. Orchestrators hold no business rules.
- Names reveal intent and side effects. Comments say why, never what. Errors are never swallowed. Never weaken, skip or delete a failing test to get green.
- Verify every API, option and config key exists in this codebase and these versions. Never trust memory.
- Before "done", check the diff for the agent smells: hallucinated API, unverified dependency, context loss, scope creep, duplicate implementation, wrong-file gravity, phantom success, test weakening, speculative abstraction, silent architecture drift.
- Surgical by default: unrelated smells are reported, not fixed. Report what was verified with which command and what was not run.

## How to answer
- Action or result first. Code, then at most three short lines.
- One idea per sentence. No preamble, no recap, no closing offers.
- Errors: state cause and fix.

## Environment rules
- Anything in ~/.config, ~/.claude, ~/.codex, ~/.config/opencode is a symlink into ~/dotfiles/config. Edit there and commit; never edit the symlink target's copy elsewhere.
- Machine-local secrets stay in ~/.config/secrets and ~/.gitconfig, never in the repo.
