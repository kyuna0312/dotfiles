# Cyberpunk bash layer - common utilities

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship/starship.toml}"
if [[ $- == *i* ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

export LANG="${LANG:-en_US.UTF-8}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

if command -v eza >/dev/null 2>&1; then
  alias ls='eza -al --icons --git -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias ltree='eza --tree --level=2 --icons --git'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

alias cls='clear'

# -------- Git --------
alias gst='git status -sb'
alias glog='git log --graph --topo-order --decorate --pretty="%C(auto)%h %d %s"'
alias gdiff='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'

alias gc='git commit -m'
alias gca='git commit -a -m'
alias gp='git push origin HEAD'
alias gpu='git pull --ff-only'

# -------- Docker --------
if command -v docker >/dev/null 2>&1; then
  alias dco='docker compose'
  alias dps='docker ps'
  alias dpa='docker ps -a'
  alias dl='docker ps -l -q'
  alias dx='docker exec -it'
fi

# -------- C++ helpers --------
export CXX="${CXX:-g++}"
cpp_build() {
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

# -------- SSH quick picker --------
sshquick() {
  local cfg="${SSH_CONFIG_FILE:-$HOME/.ssh/config}"
  if command -v fzf >/dev/null 2>&1 && [[ -f "$cfg" ]]; then
    local hosts
    hosts="$(awk 'BEGIN{IGNORECASE=1} $1=="Host"{for(i=2;i<=NF;i++) if($i !~ /[*?]/) print $i}' "$cfg" | sort -u)"
    [[ -n "$hosts" ]] || return 0
    local choice
    choice="$(printf "%s\n" "$hosts" | fzf --prompt="SSH> ")"
    [[ -n "$choice" ]] && command ssh "$choice"
  else
    echo "fzf not found or $cfg missing; run: ssh <host>"
  fi
}

# -------- nvm lazy load (Node.js) --------
__dp_nvm_loaded=0
__dp_load_nvm() {
  [[ "$__dp_nvm_loaded" == "1" ]] && return 0
  local nvm_dir="$HOME/.nvm"
  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    . "$nvm_dir/nvm.sh"
  fi
  __dp_nvm_loaded=1
}

if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  node() { __dp_load_nvm; command node "$@"; }
  npm() { __dp_load_nvm; command npm "$@"; }
  npx() { __dp_load_nvm; command npx "$@"; }
  nvm() { __dp_load_nvm; command nvm "$@"; }
fi

