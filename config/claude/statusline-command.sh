#!/usr/bin/env bash
# Claude Code status line — mirrors the tmux "Night City" status bar
# (same palette + powerline segments as ~/.tmux.conf status-left).
# Reads JSON from stdin, outputs a single line.

input=$(cat)

# ── Palette (r;g;b) — keep in sync with ~/.tmux.conf ─────────────────────────
bg="16;26;31"        # #101a1f  status bg
panel="29;44;54"     # #1d2c36  status-left second segment
panel2="21;36;45"    # #15242d  current-window segment
fg="182;197;211"     # #b6c5d3  text
dim="91;113;137"     # #5b7189  inactive window text
cyan="43;188;213"    # #2bbcd5  accent
green="73;213;117"   # #49d575
yellow="242;199;75"  # #f2c74b  prefix / warning
purple="190;89;214"  # #be59d6  copy-mode / high
red="224;108;117"    # danger (not in tmux palette — nothing there is "critical")
F() { printf '\033[38;2;%sm' "$1"; }
B() { printf '\033[48;2;%sm' "$1"; }
bold=$'\033[1m'; reset=$'\033[0m'

# ── Extract fields (\x1f-separated: model names and paths contain spaces) ───
# ponytail: spawns python3 every refresh (~30 ms); jq is not guaranteed on macOS, bash has no JSON. Fine at refreshInterval 30.
IFS=$'\x1f' read -r cwd model used_pct rl_pct <<< "$(echo "$input" | python3 -c "
import json, sys
d = json.load(sys.stdin)
w = d.get('workspace', {})
cw = d.get('context_window', {})
rl = d.get('rate_limits', {}).get('5h', {})
print('\x1f'.join(str(x) for x in (
    w.get('current_dir', d.get('cwd', '')),
    d.get('model', {}).get('display_name', ''),
    cw.get('used_percentage', ''),
    rl.get('used_percentage', ''),
)))
" 2>/dev/null || printf '\x1f\x1f\x1f')"

# ── Directory: like tmux #{b:pane_current_path} — basename only ───────────────
# ponytail: basename only, so two projects named `api` look identical; show parent/basename if that bites
short_dir="${cwd##*/}"; [ -n "$short_dir" ] || short_dir="${cwd/#$HOME/\~}"

# ── Git branch ────────────────────────────────────────────────────────────────
branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ── Context usage bar ─────────────────────────────────────────────────────────
ctx_part=""; ctx_color="$green"
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo 0)
  [ "$used_int" -ge 50 ] && ctx_color="$yellow"
  [ "$used_int" -ge 75 ] && ctx_color="$purple"
  [ "$used_int" -ge 90 ] && ctx_color="$red"
  filled=$(( used_int / 10 )); [ "$filled" -gt 10 ] && filled=10
  full="██████████"; hollow="░░░░░░░░░░"
  ctx_part="ctx ${full:0:filled}$(F "$dim")${hollow:0:10-filled}$(F "$ctx_color") ${used_int}%"
fi

# ── Instruction-file token estimate (CLAUDE.md, words × 1.3) ──────────────────
count_tokens() { [ -f "$1" ] && echo "$(( $(wc -w < "$1") * 13 / 10 ))" || echo 0; }
md_for_dir() {
  [ -n "$1" ] || { echo 0; return; }
  if [ -f "$1/CLAUDE.md" ]; then count_tokens "$1/CLAUDE.md"; else count_tokens "$1/claude.md"; fi
}
total_md=$(( $(md_for_dir "$HOME/.claude") + $(md_for_dir "$cwd") ))
md_part=""; md_color="$green"
if [ "$total_md" -gt 0 ]; then
  [ "$total_md" -ge 390  ] && md_color="$yellow"
  [ "$total_md" -ge 780  ] && md_color="$purple"
  [ "$total_md" -ge 1300 ] && md_color="$red"
  md_part="md ~${total_md}t"
fi

# ── Rate limit (only when it matters) ─────────────────────────────────────────
# ponytail: reads only the 5h window; add 7d when Claude Code exposes one users actually watch
rl_part=""; rl_color="$yellow"
if [ -n "$rl_pct" ]; then
  rl_int=$(printf "%.0f" "$rl_pct" 2>/dev/null || echo 0)
  if [ "$rl_int" -ge 70 ]; then
    [ "$rl_int" -ge 90 ] && rl_color="$red"
    rl_part="rate ${rl_int}%"
  fi
fi

# ── Assemble: powerline segments, each "fg|bg|text"; separator  = E0B0 ───────
segs=("$bg|$cyan|${bold} $short_dir ")
[ -n "$branch" ]   && segs+=("$fg|$panel|  $branch ")
[ -n "$model" ]    && segs+=("$cyan|$panel2| $model ")
[ -n "$ctx_part" ] && segs+=("$ctx_color|$panel| $ctx_part ")
[ -n "$md_part" ]  && segs+=("$md_color|$panel2| $md_part ")
[ -n "$rl_part" ]  && segs+=("$rl_color|$panel| $rl_part ")

prev_bg=""
for s in "${segs[@]}"; do
  IFS='|' read -r sfg sbg text <<< "$s"
  [ -n "$prev_bg" ] && printf '%s%s' "$(F "$prev_bg")$(B "$sbg")" "$reset"
  printf '%s%s%s%s' "$(F "$sfg")" "$(B "$sbg")" "$text" "$reset"
  prev_bg="$sbg"
done
[ -n "$prev_bg" ] && printf '%s%s' "$(F "$prev_bg")" "$reset"
printf '\n'
