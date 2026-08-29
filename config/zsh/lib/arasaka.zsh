# ── BOX UK · Cyberpunk 2077 zsh layer ─────────────────────────
# Greeting, syntax highlight colors, themed helpers.
# Sourced last in common.zsh (after zsh-syntax-highlighting).

# ── Palette (ANSI 256 ≈ BOX UK hex) ────────────────────────────────
_A_PINK='\033[38;5;197m'    # #ff6bba sakura
_A_CYAN='\033[38;5;50m'     # #00e5ff neon cyan
_A_LAV='\033[38;5;200m'     # #c8a5ff lavender
_A_MINT='\033[38;5;84m'    # #9dffcc mint
_A_GOLD='\033[38;5;220m'    # #ffd97d gold
_A_ROSE='\033[38;5;197m'    # #ff4d8d rose
_A_DIM='\033[38;5;239m'     # muted surface
_A_BOLD='\033[1m'
_A_RST='\033[0m'

# ── Greeting ──────────────────────────────────────────────────────────────────
# Only in interactive non-tmux shells (tmux status bar already has identity).
_arasaka_greet() {
  [[ "${__dp_is_interactive:-0}" != "1" ]] && return
  [[ -n "${TMUX:-}" ]] && return

  local _sys _shell _up _dir
  _sys="$(uname -sr 2>/dev/null)"
  _shell="zsh $(zsh --version 2>/dev/null | awk '{print $2}')"
  _up="$(uptime -p 2>/dev/null | sed 's/up //' || echo 'unknown')"
  _dir="$(pwd | sed "s|$HOME|~|")"

  printf "\n"
  printf "${_A_PINK}${_A_BOLD}  ✦  N E T R U N N E R  O N L I N E${_A_RST}\n"
  printf "${_A_DIM}     ──────────────────────────────────${_A_RST}\n"
  printf "${_A_CYAN}     operator  netrunner\n"
  printf "${_A_LAV}     system    ${_A_RST}${_sys}\n"
  printf "${_A_MINT}     shell     ${_A_RST}${_shell}\n"
  printf "${_A_GOLD}     uptime    ${_A_RST}${_up}\n"
  printf "${_A_PINK}     location  ${_A_RST}${_dir}\n"
  printf "${_A_DIM}     ──────────────────────────────────${_A_RST}\n"
  printf "\n"
}
_arasaka_greet

# ── Override common.zsh info helpers with themed versions ────────────────────
_dp_info()  { printf "${_A_CYAN}[✦]${_A_RST} %s\n"    "$*"; }
_dp_warn()  { printf "${_A_GOLD}[!]${_A_RST} %s\n"    "$*"; }
_dp_error() { printf "${_A_ROSE}[✗]${_A_RST} %s\n"    "$*" >&2; }

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

# ── BOX UK helper functions ───────────────────────────────────────────

# jack-in: ssh with a netrunner greeting
jack-in() {
  if [[ -z "${1:-}" ]]; then
    _dp_warn "usage: jack-in <host> [ssh args...]"
    return 2
  fi
  printf "${_A_CYAN}  ✦ jacking in ${_A_RST}→ ${_A_PINK}${1}${_A_RST}\n"
  ssh "$@"
}

# flatline: kill process by name
flatline() {
  if [[ -z "${1:-}" ]]; then
    _dp_warn "usage: flatline <process-name>"
    return 2
  fi
  if pkill -f "$1" 2>/dev/null; then
    printf "${_A_ROSE}  ✗ flatlined  ${_A_RST}${1}\n"
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
  printf "${_A_DIM}  ▸ ${cmd}${_A_RST}\n"
  eval "$cmd"
}

# ports: show open listening ports
ports() {
  printf "${_A_CYAN}  ✦ open ports${_A_RST}\n"
  ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null
}

# arasaka: identity card + system info
arasaka() {
  local _os _branch=""
  _os="$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -sr)"
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    _branch="$(git branch --show-current 2>/dev/null)"
  fi

  printf "\n${_A_PINK}${_A_BOLD}  ✦  BOX UK · netrunner id${_A_RST}\n"
  printf "${_A_DIM}     ──────────────────────────────────${_A_RST}\n"
  printf "${_A_CYAN}     host      ${_A_RST}$(hostname)\n"
  printf "${_A_LAV}     os        ${_A_RST}${_os}\n"
  printf "${_A_MINT}     kernel    ${_A_RST}$(uname -r)\n"
  printf "${_A_GOLD}     shell     ${_A_RST}zsh $(zsh --version 2>/dev/null | awk '{print $2}')\n"
  printf "${_A_ROSE}     uptime    ${_A_RST}$(uptime -p 2>/dev/null | sed 's/up //')\n"
  printf "${_A_PINK}     dir       ${_A_RST}$(pwd | sed "s|$HOME|~|")\n"
  [[ -n "$_branch" ]] && \
    printf "${_A_LAV}     branch    ${_A_RST}${_branch}\n"
  printf "${_A_DIM}     ──────────────────────────────────${_A_RST}\n\n"
}
