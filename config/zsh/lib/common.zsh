# NIGHT CITY zsh layer - common utilities
# Style goals:
# - Minimal and readable by default
# - Soft visual polish without noisy output
# - Fast startup with lazy loading where possible

# ---------- Shell behavior ----------
setopt NO_BEEP
setopt prompt_subst
setopt auto_cd
setopt interactive_comments
setopt hist_ignore_all_dups
setopt inc_append_history     # write immediately per-session, don't share across terminals
setopt hist_reduce_blanks
setopt extended_history        # save timestamp + duration
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

__dp_is_interactive=0
[[ $- == *i* ]] && __dp_is_interactive=1

# ---------- Locale ----------
export LANG="${LANG:-en_US.UTF-8}"

# ---------- XDG base dirs (must come before HISTFILE and other XDG consumers) ----------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ---------- History persistence ----------
export HISTFILE="${XDG_STATE_HOME}/zsh/history"
export HISTSIZE=100000
export SAVEHIST=100000
mkdir -p "${HISTFILE:h}" "${XDG_CACHE_HOME}/zsh" 2>/dev/null || true

# ---------- Prompt ----------
# Use Starship as the primary prompt renderer.
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship/starship.toml}"
if [[ "$__dp_is_interactive" == "1" ]] && command -v starship >/dev/null 2>&1; then
  # Keep prompt rendering in one place (starship) for a clean look.
  eval "$(starship init zsh)"
fi

_dp_add_path() {
  local p="${1:-}"
  [[ -n "$p" && -d "$p" && ":$PATH:" != *":$p:"* ]] && PATH="$p:$PATH"
}

# Common language/toolchain paths (safe if dirs don't exist).
_dp_add_path "$HOME/.local/bin"
_dp_add_path "$HOME/.cargo/bin"
_dp_add_path "$HOME/go/bin"

# ---------- UX feedback ----------
_dp_info()  { printf "\033[0;36m[info]\033[0m %s\n" "$*"; }
_dp_warn()  { printf "\033[0;33m[warn]\033[0m %s\n" "$*"; }
_dp_error() { printf "\033[0;31m[error]\033[0m %s\n" "$*" >&2; }

# ---------- Clipboard ----------
_dp_copy_to_clipboard() {
  # Tries common clipboard tools (Wayland, X11, macOS). Falls back to /dev/null.
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input
  elif command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  else
    cat >/dev/null
  fi
}

# ---------- Optional completions (kubectl cache) ----------
_dp_init_kubectl_completion() {
  # Cache kubectl completion output to avoid startup latency.
  local cache_file="${XDG_CACHE_HOME}/zsh/kubectl-completion.zsh"
  [[ -s "$cache_file" ]] && source "$cache_file"

  # Refresh weekly in the background; &! keeps the job notice off the prompt.
  local -a fresh=( ${cache_file}(N.md-7) )
  # Per-shell tmp name: two shells starting together must not write one file.
  (( $#fresh )) || {
    kubectl completion zsh > "${cache_file}.$$" 2>/dev/null \
      && mv "${cache_file}.$$" "$cache_file"
  } &!
}

# ---------- zsh basics + completion ----------
if [[ "$__dp_is_interactive" == "1" ]]; then
  # Completion cache in XDG cache keeps startup snappy.
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  autoload -Uz compinit
  # Full compinit once a day; -C trusts the dump the rest of the time.
  # touch: compinit only rewrites the dump when the completion set changed.
  _zcd="${XDG_CACHE_HOME}/zsh/zcompdump"
  _zcd_fresh=( ${_zcd}(N.mh-24) )
  if (( $#_zcd_fresh )); then
    compinit -C -d "$_zcd"
  else
    compinit -d "$_zcd" && touch "$_zcd"
  fi
  unset _zcd _zcd_fresh
fi

if [[ "$__dp_is_interactive" == "1" ]] && command -v kubectl >/dev/null 2>&1 && [[ "${CYBERPUNK_KUBECTL_COMPLETION:-1}" == "1" ]]; then
  _dp_init_kubectl_completion
fi

if [[ "$__dp_is_interactive" == "1" ]] && command -v aws_completer >/dev/null 2>&1; then
  autoload -Uz bashcompinit && bashcompinit   # `complete` is a bash builtin
  complete -C aws_completer aws
fi

# ---------- UI helpers ----------
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'

if command -v eza >/dev/null 2>&1; then
  # NIGHT CITY eza: purple dates, coral user, green sizes, yellow units.
  export EZA_COLORS="${EZA_COLORS:-da=38;5;133:uu=38;5;210:un=38;5;210:sn=38;5;36:sb=38;5;179:xa=38;5;217:gm=38;5;246}"
  alias ls='eza -al --icons --git'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias ltree='eza --tree --level=2 --icons --git'
  alias la='eza -a --icons --git'
  alias ll='eza -l --icons --git'
  alias lla='eza -la --icons --git'
else
  alias ls='ls --color=auto'
  alias la='ls -A'
  alias ll='ls -lh'
  alias lla='ls -lhA'
fi

if command -v bat >/dev/null 2>&1; then
  # Prefer repo-managed bat config when available.
  if [[ -z "${BAT_CONFIG_PATH:-}" && -n "${CYBERPUNK_DOTFILES_DIR:-}" && -f "${CYBERPUNK_DOTFILES_DIR}/config/bat/config" ]]; then
    export BAT_CONFIG_PATH="${CYBERPUNK_DOTFILES_DIR}/config/bat/config"
  fi
  alias cat='bat --paging=never --style=plain'
  # Custom NIGHT CITY theme — config/bat/themes/nightcity.tmTheme
  # (needs `bat cache --build` once after linking).
  export BAT_THEME="${BAT_THEME:-nightcity}"
fi

# ---------- Git (developer-focused) ----------
alias g='git'
alias gst='git status -sb'
if command -v delta >/dev/null 2>&1 && [[ -n "${CYBERPUNK_DOTFILES_DIR:-}" && -f "${CYBERPUNK_DOTFILES_DIR}/config/git/delta.gitconfig" ]]; then
  alias glog="git -c include.path=${CYBERPUNK_DOTFILES_DIR}/config/git/delta.gitconfig log --graph --topo-order --decorate --pretty='%C(auto)%h %d %s'"
  alias gdiff="git -c include.path=${CYBERPUNK_DOTFILES_DIR}/config/git/delta.gitconfig diff"
  alias gshow="git -c include.path=${CYBERPUNK_DOTFILES_DIR}/config/git/delta.gitconfig show"
else
  alias glog='git log --graph --topo-order --decorate --pretty="%C(auto)%h %d %s"'
  alias gdiff='git diff'
  alias gshow='git show'
fi
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcommit='git commit'

alias gc='git commit -m'
alias gca='git commit -a -m'

alias gp='git push origin HEAD'
alias gpu='git pull --ff-only'

# Safe-ish "quick reset" helpers.
alias gre='git reset'
alias gremote='git remote'
alias gundo='git reset --soft HEAD~1'

# ---------- Docker ----------
if command -v docker >/dev/null 2>&1; then
  alias dco='docker compose'
  alias dps='docker ps'
  alias dpa='docker ps -a'
  alias dl='docker ps -l -q'
  alias dx='docker exec -it'
fi

# ---------- Optional fzf defaults ----------
if command -v fzf >/dev/null 2>&1; then
  # NIGHT CITY — teal prompt, cyan highlights.
  export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:- --height=70% --layout=reverse --border=rounded --info=inline --pointer='λ' --marker='●' --prompt='  ' --color=fg:#b6c5d3,bg:-1,hl:#0cc7c2,fg+:#b6c5d3,bg+:-1,hl+:#5bf4f1,info:#5b7189,prompt:#2bbcd5,pointer:#2bbcd5,marker:#49d575,spinner:#0cc7c2,header:#49d575,border:#2bbcd5}"
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS:- --preview 'bat --color=always --style=numbers --line-range=:300 {}' --preview-window=right,60%,border-left}"
  fi
fi

# ---------- Node ----------
# Default node is the package manager's. nvm is only for projects pinned to
# another version: `nvm use 22` loads it on first call, nothing else is shadowed.
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  nvm() { unfunction nvm; . "$NVM_DIR/nvm.sh"; nvm "$@"; }
fi

# ---------- C++ helpers ----------
export CXX="${CXX:-g++}"
cxx() {
  # Compile a single C++ source quickly (use cpp_build for CMake projects).
  # Named cxx, not cc: `cc` is the system C compiler and must stay untouched.
  "${CXX}" -O2 -pipe -Wall -Wextra "$@"
}

cpp_build() {
  # If a CMake project exists, use it; otherwise compile a single file.
  local src="${1:-}"
  if [[ -z "$src" ]]; then
    echo "Usage: cpp_build path/to/main.cpp [args...]"
    return 2
  fi

  if [[ -f "CMakeLists.txt" ]]; then
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j"$(nproc 2>/dev/null || echo 4)"
  else
    local out="${src##*/}"
    out="${out%.*}"
    "${CXX}" -std=c++20 -O2 -pipe -Wall -Wextra "$src" -o "$out"
  fi
}

alias cbuild='cpp_build'

# ---------- zoxide ----------
# Not lazy: its chpwd hook must run from the first cd or it never learns dirs.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ---------- Fast directory/file pickers ----------
_dp_require_fd_fzf() {
  command -v fd  >/dev/null 2>&1 || { _dp_error "fd not installed";  return 127; }
  command -v fzf >/dev/null 2>&1 || { _dp_error "fzf not installed"; return 127; }
}

fcd() {
  # Jump to a directory under $HOME (pass arg to override root).
  _dp_require_fd_fzf || return $?
  local root="${1:-$HOME}"
  local picked
  picked="$(fd -t d --hidden --exclude '.git' --exclude 'node_modules' . "$root" | fzf)" || return
  cd "$picked" || return
}

f() {
  # Pick a file under $HOME, copy its path to clipboard.
  _dp_require_fd_fzf || return $?
  local root="${1:-$HOME}"
  local picked
  picked="$(fd -t f --hidden --exclude '.git' --exclude 'node_modules' . "$root" | fzf)" || return
  printf "%s" "$picked" | _dp_copy_to_clipboard
  _dp_info "copied path: ${picked}"
}

# Ctrl-F: fzf directory jump (craftzdog-style), as a ZLE widget so the prompt redraws.
if command -v fzf >/dev/null 2>&1; then
  _dp_fzf_cd_widget() {
    fcd </dev/tty
    zle reset-prompt
  }
  zle -N _dp_fzf_cd_widget
  bindkey '^f' _dp_fzf_cd_widget
fi

fv() {
  # Pick a file under $HOME and open in $EDITOR.
  _dp_require_fd_fzf || return $?
  local root="${1:-$HOME}"
  local picked
  picked="$(fd -t f --hidden --exclude '.git' --exclude 'node_modules' . "$root" | fzf)" || return
  ${EDITOR:-vi} "$picked"
}

# ---------- Editor / AI CLI shortcuts ----------
command -v nvim >/dev/null 2>&1 && alias vim='nvim'
command -v claude >/dev/null 2>&1 && alias c='claude'
command -v claude >/dev/null 2>&1 && alias claude-yolo='claude --dangerously-skip-permissions'

# ---------- Quick quality-of-life helpers ----------
mkcd() {
  [[ -n "$1" ]] || { _dp_warn "usage: mkcd <directory>"; return 2; }
  mkdir -p "$1" && cd "$1" || return
}

dp-tools() {
  # NIGHT CITY-styled CLI stack reference
  printf "\n\033[38;5;209m\033[1m  ✦  NIGHT CITY CLI stack\033[0m\n"
  printf "\033[38;5;243m     ──────────────────────────────────\033[0m\n"
  printf "\033[38;5;31m     core    \033[0m starship bat eza fzf fd ripgrep zoxide\n"
  printf "\033[38;5;133m     zsh     \033[0m zsh-autosuggestions zsh-syntax-highlighting\n"
  printf "\033[38;5;36m     git     \033[0m lazygit git-delta\n"
  printf "\033[38;5;179m     history \033[0m atuin\n"
  case "${CYBERPUNK_OS:-}" in
    macos) printf "\033[38;5;243m     install \033[0m brew install <packages>   (packages/macos-base.txt)\n" ;;
    *)     printf "\033[38;5;243m     install \033[0m see packages/<distro>-base.txt\n" ;;
  esac
  printf "\033[38;5;243m     ──────────────────────────────────\033[0m\n\n"
}
alias nightcity-tools='dp-tools'
alias netrunner-tools='dp-tools'   # back-compat

# ---------- Plugins (Sheldon) ----------
# Loads zsh-autosuggestions then zsh-syntax-highlighting (last).
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

# autosuggest-* are ZLE widgets (created by `zle -N` at plugin load), not functions.
if (( ${+widgets[autosuggest-execute]} )); then
  bindkey '^w' autosuggest-execute
  bindkey '^e' autosuggest-accept
  bindkey '^u' autosuggest-toggle
fi

# ---------- Security toolkit ----------
# Only when at least nmap or burpsuite is installed.
if command -v nmap >/dev/null 2>&1 || command -v burpsuite >/dev/null 2>&1; then
  source "${CYBERPUNK_DOTFILES_DIR}/config/zsh/lib/security.zsh"
fi

# ---------- NIGHT CITY layer ----------
# Greeting, themed helpers, syntax highlight colors, NIGHT CITY functions.
[[ -f "${CYBERPUNK_DOTFILES_DIR}/config/zsh/lib/nightcity.zsh" ]] && \
  source "${CYBERPUNK_DOTFILES_DIR}/config/zsh/lib/nightcity.zsh"
