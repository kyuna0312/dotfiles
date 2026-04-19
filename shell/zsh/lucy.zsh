# ── Lucy Kushinada · Cyberpunk Edgerunners zsh layer ─────────────────────────
# Greeting, syntax highlight colors, themed helpers.
# Sourced last in common.zsh (after zsh-syntax-highlighting).

# ── Palette (ANSI 256 ≈ Lucy Edgerunner+ hex) ────────────────────────────────
_L_PINK='\033[38;5;212m'    # #ff6bba sakura
_L_CYAN='\033[38;5;51m'     # #00e5ff neon cyan
_L_LAV='\033[38;5;183m'     # #c8a5ff lavender
_L_MINT='\033[38;5;158m'    # #9dffcc mint
_L_GOLD='\033[38;5;221m'    # #ffd97d gold
_L_ROSE='\033[38;5;204m'    # #ff4d8d rose
_L_DIM='\033[38;5;239m'     # muted surface
_L_BOLD='\033[1m'
_L_RST='\033[0m'

# ── Greeting ──────────────────────────────────────────────────────────────────
# Only in interactive non-tmux shells (tmux status bar already has identity).
_lucy_greet() {
  [[ "${__dp_is_interactive:-0}" != "1" ]] && return
  [[ -n "${TMUX:-}" ]] && return

  local _sys _shell _up _dir
  _sys="$(uname -sr 2>/dev/null)"
  _shell="zsh $(zsh --version 2>/dev/null | awk '{print $2}')"
  _up="$(uptime -p 2>/dev/null | sed 's/up //' || echo 'unknown')"
  _dir="$(pwd | sed "s|$HOME|~|")"

  printf "\n"
  printf "${_L_PINK}${_L_BOLD}  ✦  N E T R U N N E R  O N L I N E${_L_RST}\n"
  printf "${_L_DIM}     ──────────────────────────────────${_L_RST}\n"
  printf "${_L_CYAN}     operator  ${_L_RST}lucy kushinada\n"
  printf "${_L_LAV}     system    ${_L_RST}${_sys}\n"
  printf "${_L_MINT}     shell     ${_L_RST}${_shell}\n"
  printf "${_L_GOLD}     uptime    ${_L_RST}${_up}\n"
  printf "${_L_PINK}     location  ${_L_RST}${_dir}\n"
  printf "${_L_DIM}     ──────────────────────────────────${_L_RST}\n"
  printf "\n"
}
_lucy_greet

# ── Override common.zsh info helpers with themed versions ────────────────────
_dp_info()  { printf "${_L_CYAN}[✦]${_L_RST} %s\n"    "$*"; }
_dp_warn()  { printf "${_L_GOLD}[!]${_L_RST} %s\n"    "$*"; }
_dp_error() { printf "${_L_ROSE}[✗]${_L_RST} %s\n"    "$*" >&2; }

# ── Zsh syntax highlighting colors ───────────────────────────────────────────
if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
  ZSH_HIGHLIGHT_STYLES[command]='fg=212,bold'           # sakura   — commands
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=183,bold'           # lavender — builtins
  ZSH_HIGHLIGHT_STYLES[alias]='fg=212'                  # sakura   — aliases
  ZSH_HIGHLIGHT_STYLES[function]='fg=183'               # lavender — functions
  ZSH_HIGHLIGHT_STYLES[path]='fg=158,underline'         # mint     — paths
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=221' # gold     — strings
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=221' # gold     — strings
  ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=221' # gold
  ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=158'   # mint
  ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=51,bold'      # cyan     — if/for/do
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=51'                # cyan     — * ? **
  ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=51'       # cyan     — !foo
  ZSH_HIGHLIGHT_STYLES[redirection]='fg=204'            # rose     — > < >>
  ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=204'       # rose     — ; && ||
  ZSH_HIGHLIGHT_STYLES[assign]='fg=183'                 # lavender — VAR=val
  ZSH_HIGHLIGHT_STYLES[named-fd]='fg=51'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=239'                # dim      — # comments
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=204,bold'     # rose     — bad cmd
fi

# ── Autosuggestion color ──────────────────────────────────────────────────────
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=239'

# ── Lucy-flavored helper functions ───────────────────────────────────────────

# jack-in: ssh with a netrunner greeting
jack-in() {
  if [[ -z "${1:-}" ]]; then
    _dp_warn "usage: jack-in <host> [ssh args...]"
    return 2
  fi
  printf "${_L_CYAN}  ✦ jacking in ${_L_RST}→ ${_L_PINK}${1}${_L_RST}\n"
  ssh "$@"
}

# flatline: kill process by name
flatline() {
  if [[ -z "${1:-}" ]]; then
    _dp_warn "usage: flatline <process-name>"
    return 2
  fi
  if pkill -f "$1" 2>/dev/null; then
    printf "${_L_ROSE}  ✗ flatlined  ${_L_RST}${1}\n"
  else
    _dp_warn "no process matched: $1"
  fi
}

# breach: cd into directory and open editor
breach() {
  local target="${1:-.}"
  cd "$target" || return
  ${EDITOR:-nvim} .
}

# ghost: browse history with fzf and re-run
ghost() {
  command -v fzf >/dev/null 2>&1 || { _dp_warn "fzf not installed"; return 127; }
  local cmd
  cmd="$(fc -ln 1 | fzf --tac --no-sort --prompt='  ghost λ  ' --height=50%)" || return
  [[ -z "$cmd" ]] && return
  printf "${_L_DIM}  ▸ ${cmd}${_L_RST}\n"
  eval "$cmd"
}

# ports: show open listening ports
ports() {
  printf "${_L_CYAN}  ✦ open ports${_L_RST}\n"
  ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null
}

# lucy: identity card + system info
lucy() {
  local _os _branch=""
  _os="$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -sr)"
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    _branch="$(git branch --show-current 2>/dev/null)"
  fi

  printf "\n${_L_PINK}${_L_BOLD}  ✦  lucy kushinada · netrunner id${_L_RST}\n"
  printf "${_L_DIM}     ──────────────────────────────────${_L_RST}\n"
  printf "${_L_CYAN}     host      ${_L_RST}$(hostname)\n"
  printf "${_L_LAV}     os        ${_L_RST}${_os}\n"
  printf "${_L_MINT}     kernel    ${_L_RST}$(uname -r)\n"
  printf "${_L_GOLD}     shell     ${_L_RST}zsh $(zsh --version 2>/dev/null | awk '{print $2}')\n"
  printf "${_L_ROSE}     uptime    ${_L_RST}$(uptime -p 2>/dev/null | sed 's/up //')\n"
  printf "${_L_PINK}     dir       ${_L_RST}$(pwd | sed "s|$HOME|~|")\n"
  [[ -n "$_branch" ]] && \
    printf "${_L_LAV}     branch    ${_L_RST}${_branch}\n"
  printf "${_L_DIM}     ──────────────────────────────────${_L_RST}\n\n"
}
