# Cyberpunk (Lucy-inspired) zsh layer - common utilities

setopt NO_BEEP
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

__dp_is_interactive=0
[[ $- == *i* ]] && __dp_is_interactive=1

# ---------- Prompt ----------
# Use Starship as the primary prompt renderer.
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship/starship.toml}"
if [[ "$__dp_is_interactive" == "1" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ---------- Locale ----------
export LANG="${LANG:-en_US.UTF-8}"

# ---------- Paths ----------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

_dp_add_path() {
  local p="${1:-}"
  [[ -n "$p" && -d "$p" && ":$PATH:" != *":$p:"* ]] && PATH="$p:$PATH"
}

# Common language/toolchain paths (safe if dirs don't exist).
_dp_add_path "$HOME/.local/bin"
_dp_add_path "$HOME/.cargo/bin"
_dp_add_path "$HOME/go/bin"

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
  autoload -Uz compinit && compinit
fi

if [[ "$__dp_is_interactive" == "1" ]] && command -v kubectl >/dev/null 2>&1 && [[ "${CYBERPUNK_KUBECTL_COMPLETION:-1}" == "1" ]]; then
  _dp_init_kubectl_completion
fi

# AWS completer: prefer PATH binary if present.
if command -v aws_completer >/dev/null 2>&1; then
  complete -C "$(command -v aws_completer)" aws 2>/dev/null || true
fi

# ---------- Autosuggestions (optional) ----------
autosug_candidates=(
  "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  "$HOME/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
)

if command -v brew >/dev/null 2>&1; then
  autosug_candidates+=("$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh")
fi

for autosug_path in "${autosug_candidates[@]}"; do
  if [[ -f "$autosug_path" ]]; then
    source "$autosug_path"
    break
  fi
done

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

if command -v eza >/dev/null 2>&1; then
  alias ls='eza -al --icons --git -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias ltree='eza --tree --level=2 --icons --git'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  export BAT_THEME="${BAT_THEME:-TwoDark}"
fi

alias la='tree'

# ---------- Git (developer-focused) ----------
alias gst='git status -sb'
alias glog='git log --graph --topo-order --decorate --pretty="%C(auto)%h %d %s"'
alias gdiff='git diff'
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

# ---------- Docker ----------
if command -v docker >/dev/null 2>&1; then
  alias dco='docker compose'
  alias dps='docker ps'
  alias dpa='docker ps -a'
  alias dl='docker ps -l -q'
  alias dx='docker exec -it'
fi

# ---------- Node (lazy nvm) ----------
__dp_nvm_loaded=0
__dp_load_nvm() {
  [[ "$__dp_nvm_loaded" == "1" ]] && return 0
  local nvm_dir="$HOME/.nvm"
  [[ -s "$nvm_dir/nvm.sh" ]] && . "$nvm_dir/nvm.sh"
  __dp_nvm_loaded=1
}

if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  nvm() {
    __dp_load_nvm
    unfunction nvm 2>/dev/null || true
    nvm "$@"
  }
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

# ---------- SSH quick picker ----------
sshquick() {
  # Pick a host from ~/.ssh/config (or fallback to 'ssh <host>').
  local cfg="${SSH_CONFIG_FILE:-$HOME/.ssh/config}"
  if command -v fzf >/dev/null 2>&1 && [[ -f "$cfg" ]]; then
    local hosts
    hosts="$(awk 'BEGIN{IGNORECASE=1} $1=="Host"{for(i=2;i<=NF;i++) if($i !~ /[*?]/) print $i}' "$cfg" | sort -u)"
    [[ -n "$hosts" ]] || return 0
    local choice
    choice="$(printf "%s\n" "$hosts" | fzf --prompt="SSH> ")"
    [[ -n "$choice" ]] && command ssh "$choice"
  else
    echo "fzf or $cfg not found; run: ssh <host>"
  fi
}

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
fcd() {
  # fd is usually much faster than find; keep hidden paths off by default.
  command -v fd >/dev/null 2>&1 || { echo "fd not installed"; return 127; }
  command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 127; }
  cd "$(fd -t d --exclude '*/.*' . . | fzf)" || return
}

f() {
  command -v fd >/dev/null 2>&1 || { echo "fd not installed"; return 127; }
  command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 127; }
  local picked
  picked="$(fd -t f --exclude '*/.*' . . | fzf)" || return
  printf "%s" "$picked" | _dp_copy_to_clipboard
}

fv() {
  command -v fd >/dev/null 2>&1 || { echo "fd not installed"; return 127; }
  command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 127; }
  local picked
  picked="$(fd -t f --exclude '*/.*' . . | fzf)" || return
  ${EDITOR:-vi} "$picked"
}

