# Cyberpunk (Lucy-inspired) zsh layer - common utilities
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
setopt share_history
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
mkdir -p "${HISTFILE:h}" 2>/dev/null || true

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

# ---------- Lazy loading helpers ----------
__dp_once() { eval "__dp_once_${1}=1"; }
__dp_is_once() { [[ "${(P)__dp_once_${1}}" == 1 ]]; }

_dp_lazy_source() {
  # Usage: _dp_lazy_source <once_key> <command> <file_to_source_path>
  local once_key="$1" cmd="$2" file="$3"
  __dp_is_once "$once_key" && return 0
  command -v "$cmd" >/dev/null 2>&1 || return 0
  [[ -f "$file" ]] || return 0
  source "$file"
  __dp_once "$once_key"
}

# ---------- Optional completions (kubectl cache) ----------
_dp_init_kubectl_completion() {
  # Cache kubectl completion output to avoid startup latency.
  local cache_dir="${XDG_CACHE_HOME}/zsh"
  local cache_file="${cache_dir}/kubectl-completion.zsh"
  local max_age_seconds=$((7 * 24 * 60 * 60)) # 7 days

  mkdir -p "$cache_dir" 2>/dev/null || return 0

  if [[ -s "$cache_file" ]]; then
    source "$cache_file" 2>/dev/null
  fi

  local now epoch_age
  now="$(date +%s 2>/dev/null || echo 0)"
  epoch_age="$(__dp_file_mtime_epoch "$cache_file" 2>/dev/null || echo 0)"
  if [[ ! -s "$cache_file" || $((now - epoch_age)) -gt $max_age_seconds ]]; then
    # Refresh in background; don't block interactive startup.
    (
      kubectl completion zsh > "${cache_file}.tmp" 2>/dev/null \
        && mv "${cache_file}.tmp" "$cache_file"
    ) &
  fi
}

# ---------- zsh basics + completion ----------
if [[ "$__dp_is_interactive" == "1" ]]; then
  # Completion cache in XDG cache keeps startup snappy.
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  autoload -Uz compinit
  # Only regenerate dump if it's older than 24h; -C skips security check on cache hit.
  local _zcd="${XDG_CACHE_HOME}/zsh/zcompdump"
  if [[ -n ${_zcd}(#qN.mh+24) ]]; then
    compinit -d "$_zcd"
  else
    compinit -C -d "$_zcd"
  fi
  unset _zcd
fi

if [[ "$__dp_is_interactive" == "1" ]] && command -v kubectl >/dev/null 2>&1 && [[ "${CYBERPUNK_KUBECTL_COMPLETION:-1}" == "1" ]]; then
  _dp_init_kubectl_completion
fi

# AWS completer: prefer PATH binary if present.
if command -v aws_completer >/dev/null 2>&1; then
  complete -C "$(command -v aws_completer)" aws 2>/dev/null || true
fi

# ---------- Autosuggestions (optional) ----------
_dp_source_first_found() {
  local f; for f in "$@"; do [[ -f "$f" ]] && { source "$f"; return 0; }; done; return 1
}

# Autosuggestions: Manjaro pacman path first, then common fallbacks.
_dp_source_first_found \
  "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

if (( ${+functions[autosuggest-execute]} )); then
  bindkey '^w' autosuggest-execute
  bindkey '^e' autosuggest-accept
  bindkey '^u' autosuggest-toggle
fi

# ---------- Prompt accent ----------
# Neon "pulse" divider at the end of the command line.
# (Starship handles most visuals; this only affects a small character.)
export STARSHIP_DIRTRIM='true'

# ---------- UI helpers ----------
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'

if command -v eza >/dev/null 2>&1; then
  # Lucy Edgerunner+: lavender dates, sakura user, mint sizes, gold units.
  export EZA_COLORS="${EZA_COLORS:-da=38;5;183:uu=38;5;218:un=38;5;218:sn=38;5;158:sb=38;5;221:xa=38;5;223:gm=38;5;246}"
  alias ls='eza -al --icons --git'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias ltree='eza --tree --level=2 --icons --git'
elif command -v ls >/dev/null 2>&1; then
  alias ls='ls --color=auto'
fi

if command -v bat >/dev/null 2>&1; then
  # Prefer repo-managed bat config when available.
  if [[ -z "${BAT_CONFIG_PATH:-}" && -n "${CYBERPUNK_DOTFILES_DIR:-}" && -f "${CYBERPUNK_DOTFILES_DIR}/bat/config" ]]; then
    export BAT_CONFIG_PATH="${CYBERPUNK_DOTFILES_DIR}/bat/config"
  fi
  alias cat='bat --paging=never --style=plain'
  # Static theme — avoids forking `bat --list-themes` on every shell start.
  export BAT_THEME="${BAT_THEME:-Catppuccin Mocha}"   # closest available; swap to custom theme if installed
fi

alias la='eza -a --icons --git 2>/dev/null || ls -A'
alias ll='eza -l --icons --git 2>/dev/null || ls -lh'

# ---------- Git (developer-focused) ----------
alias gst='git status -sb'
if command -v delta >/dev/null 2>&1 && [[ -n "${CYBERPUNK_DOTFILES_DIR:-}" && -f "${CYBERPUNK_DOTFILES_DIR}/git/delta.gitconfig" ]]; then
  alias glog="git -c include.path=${CYBERPUNK_DOTFILES_DIR}/git/delta.gitconfig log --graph --topo-order --decorate --pretty='%C(auto)%h %d %s'"
  alias gdiff="git -c include.path=${CYBERPUNK_DOTFILES_DIR}/git/delta.gitconfig diff"
  alias gshow="git -c include.path=${CYBERPUNK_DOTFILES_DIR}/git/delta.gitconfig show"
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
  # Lucy Edgerunner+ — sakura pink prompt, neon cyan highlights.
  export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:- --height=70% --layout=reverse --border=rounded --info=inline --pointer='λ' --marker='●' --prompt='  ' --color=fg:#f0e6ff,bg:-1,hl:#00e5ff,fg+:#f0e6ff,bg+:-1,hl+:#67e8f9,info:#c4b0d8,prompt:#ff6bba,pointer:#ff6bba,marker:#ff4d8d,spinner:#00e5ff,header:#9dffcc,border:#c8a5ff}"
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS:- --preview 'bat --color=always --style=numbers --line-range=:300 {}' --preview-window=right,60%,border-left}"
  fi
fi

# ---------- Node (nvm) — lazy loaded ----------
# NVM sourcing costs ~200-400ms; defer until first use of nvm/node/npm/npx.
if [[ -z "${NVM_DIR:-}" ]]; then
  if [[ -d "$HOME/.config/nvm" ]]; then
    export NVM_DIR="$HOME/.config/nvm"
  else
    export NVM_DIR="$HOME/.nvm"
  fi
fi

_dp_load_nvm() {
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 1
  . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
}

if [[ -d "$NVM_DIR" ]]; then
  nvm()  { unfunction nvm  2>/dev/null; _dp_load_nvm && nvm  "$@"; }
  node() { unfunction node 2>/dev/null; _dp_load_nvm && node "$@"; }
  npm()  { unfunction npm  2>/dev/null; _dp_load_nvm && npm  "$@"; }
  npx()  { unfunction npx  2>/dev/null; _dp_load_nvm && npx  "$@"; }
fi

# ---------- C++ helpers ----------
export CXX="${CXX:-g++}"
cc() {
  # Compile a single C++ source quickly (use cpp_build for CMake projects).
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

# ---------- Lazy integration for zoxide ----------
__dp_zoxide_loaded=0
__dp_load_zoxide() {
  [[ "$__dp_zoxide_loaded" == "1" ]] && return 0
  command -v zoxide >/dev/null 2>&1 || return 0
  eval "$(zoxide init zsh)"
  __dp_zoxide_loaded=1
}

if command -v zoxide >/dev/null 2>&1; then
  z() {
    __dp_load_zoxide
    unfunction z 2>/dev/null || true
    z "$@"
  }
fi

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

fv() {
  # Pick a file under $HOME and open in $EDITOR.
  _dp_require_fd_fzf || return $?
  local root="${1:-$HOME}"
  local picked
  picked="$(fd -t f --hidden --exclude '.git' --exclude 'node_modules' . "$root" | fzf)" || return
  ${EDITOR:-vi} "$picked"
}

# ---------- Quick quality-of-life helpers ----------
mkcd() {
  [[ -n "$1" ]] || { _dp_warn "usage: mkcd <directory>"; return 2; }
  mkdir -p "$1" && cd "$1" || return
}

dp-tools() {
  # Lucy-styled CLI stack reference
  printf "\n\033[38;5;212m\033[1m  ✦  netrunner CLI stack\033[0m\n"
  printf "\033[38;5;239m     ──────────────────────────────────\033[0m\n"
  printf "\033[38;5;51m     core    \033[0m starship bat eza fzf fd ripgrep zoxide\n"
  printf "\033[38;5;183m     zsh     \033[0m zsh-autosuggestions zsh-syntax-highlighting\n"
  printf "\033[38;5;158m     git     \033[0m lazygit git-delta\n"
  printf "\033[38;5;221m     history \033[0m atuin\n"
  printf "\033[38;5;239m     install \033[0m sudo pacman -S --needed <packages>\033[0m\n"
  printf "\033[38;5;239m     ──────────────────────────────────\033[0m\n\n"
}
alias netrunner-tools='dp-tools'

# ---------- Syntax highlighting ----------
# Must be sourced LAST — after all other zsh config.
_dp_source_first_found \
  "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ---------- Lucy Kushinada layer ----------
# Greeting, themed helpers, syntax highlight colors, Lucy functions.
[[ -f "${CYBERPUNK_DOTFILES_DIR}/shell/zsh/lucy.zsh" ]] && \
  source "${CYBERPUNK_DOTFILES_DIR}/shell/zsh/lucy.zsh"
