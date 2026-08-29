# ── BOX UK · zsh layer ─────────────────────────────────────────
# Greeting, syntax highlight colors, themed helpers.
# Sourced last in common.zsh (after zsh-syntax-highlighting).

# ── Palette (ANSI 256 ≈ BOX UK hex) ────────────────────────────────
_B_PINK='\033[38;5;209m'    # #ff8a80 coral
_B_CYAN='\033[38;5;37m'     # #15b8ae teal
_B_LAV='\033[38;5;133m'     # #b750ae purple
_B_MINT='\033[38;5;36m'     # #019d76 green
_B_GOLD='\033[38;5;179m'    # #ffcb6e yellow
_B_ROSE='\033[38;5;209m'    # #f77669 coral
_B_DIM='\033[38;5;243m'     # muted surface
_B_BOLD='\033[1m'
_B_RST='\033[0m'

# ── Greeting ──────────────────────────────────────────────────────────────────
# Only in interactive non-tmux shells (tmux status bar already has identity).
_boxuk_greet() {
  [[ "${__dp_is_interactive:-0}" != "1" ]] && return
  [[ -n "${TMUX:-}" ]] && return

  local _sys _shell _up _dir
  _sys="$(uname -sr 2>/dev/null)"
  _shell="zsh $(zsh --version 2>/dev/null | awk '{print $2}')"
  _up="$(uptime -p 2>/dev/null | sed 's/up //' || echo 'unknown')"
  _dir="$(pwd | sed "s|$HOME|~|")"

  printf "\n"
  printf "${_B_PINK}${_B_BOLD}  ✦  B O X   U K   O N L I N E${_B_RST}\n"
  printf "${_B_DIM}     ──────────────────────────────────${_B_RST}\n"
  printf "${_B_CYAN}     operator  kyuna\n"
  printf "${_B_LAV}     system    ${_B_RST}${_sys}\n"
  printf "${_B_MINT}     shell     ${_B_RST}${_shell}\n"
  printf "${_B_GOLD}     uptime    ${_B_RST}${_up}\n"
  printf "${_B_PINK}     location  ${_B_RST}${_dir}\n"
  printf "${_B_DIM}     ──────────────────────────────────${_B_RST}\n"
  printf "\n"
}
_boxuk_greet

# ── Override common.zsh info helpers with themed versions ────────────────────
_dp_info()  { printf "${_B_CYAN}[✦]${_B_RST} %s\n"    "$*"; }
_dp_warn()  { printf "${_B_GOLD}[!]${_B_RST} %s\n"    "$*"; }
_dp_error() { printf "${_B_ROSE}[✗]${_B_RST} %s\n"    "$*" >&2; }

# ── Zsh syntax highlighting colors ───────────────────────────────────────────
if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
  ZSH_HIGHLIGHT_STYLES[command]='fg=36,bold'            # green    — commands
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=31,bold'            # cyan     — builtins
  ZSH_HIGHLIGHT_STYLES[alias]='fg=36'                   # green    — aliases
  ZSH_HIGHLIGHT_STYLES[precommand]='fg=36'              # green    — sudo/env
  ZSH_HIGHLIGHT_STYLES[function]='fg=31'                # cyan     — functions
  ZSH_HIGHLIGHT_STYLES[path]='fg=110,underline'         # blue-grey — paths
  ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=110,underline'  # blue-grey — path prefix
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=37'  # teal     — strings
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=37'  # teal     — strings
  ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=37'  # teal
  ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=37'    # teal
  ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=37,bold'      # teal     — if/for/do
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=37'                # teal     — * ? **
  ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=37'       # teal     — !foo
  ZSH_HIGHLIGHT_STYLES[redirection]='fg=209'            # coral    — > < >>
  ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=209'       # coral    — ; && ||
  ZSH_HIGHLIGHT_STYLES[assign]='fg=133'                 # purple   — VAR=val
  ZSH_HIGHLIGHT_STYLES[named-fd]='fg=37'                # teal
  ZSH_HIGHLIGHT_STYLES[comment]='fg=243'                # dim      — # comments
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=209,bold'     # coral    — bad cmd
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
  printf "${_B_CYAN}  ✦ jacking in ${_B_RST}→ ${_B_PINK}${1}${_B_RST}\n"
  ssh "$@"
}

# flatline: kill process by name
flatline() {
  if [[ -z "${1:-}" ]]; then
    _dp_warn "usage: flatline <process-name>"
    return 2
  fi
  if pkill -f "$1" 2>/dev/null; then
    printf "${_B_ROSE}  ✗ flatlined  ${_B_RST}${1}\n"
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
  printf "${_B_DIM}  ▸ ${cmd}${_B_RST}\n"
  eval "$cmd"
}

# ports: show open listening ports
ports() {
  printf "${_B_CYAN}  ✦ open ports${_B_RST}\n"
  ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null
}

# boxuk: identity card + system info
boxuk() {
  local _os _branch=""
  _os="$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -sr)"
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    _branch="$(git branch --show-current 2>/dev/null)"
  fi

  printf "\n${_B_PINK}${_B_BOLD}  ✦  BOX UK · system id${_B_RST}\n"
  printf "${_B_DIM}     ──────────────────────────────────${_B_RST}\n"
  printf "${_B_CYAN}     host      ${_B_RST}$(hostname)\n"
  printf "${_B_LAV}     os        ${_B_RST}${_os}\n"
  printf "${_B_MINT}     kernel    ${_B_RST}$(uname -r)\n"
  printf "${_B_GOLD}     shell     ${_B_RST}zsh $(zsh --version 2>/dev/null | awk '{print $2}')\n"
  printf "${_B_ROSE}     uptime    ${_B_RST}$(uptime -p 2>/dev/null | sed 's/up //')\n"
  printf "${_B_PINK}     dir       ${_B_RST}$(pwd | sed "s|$HOME|~|")\n"
  [[ -n "$_branch" ]] && \
    printf "${_B_LAV}     branch    ${_B_RST}${_branch}\n"
  printf "${_B_DIM}     ──────────────────────────────────${_B_RST}\n\n"
}
