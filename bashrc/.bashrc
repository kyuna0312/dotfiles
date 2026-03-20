# Cyberpunk dotfiles (Lucy-inspired) - OS-split bash entrypoint

__dp_real_entry="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
__dp_repo="$(cd "$(dirname "$__dp_real_entry")/.." && pwd)"

__dp_os="${CYBERPUNK_SHELL_OS:-}"
if [[ -z "$__dp_os" ]]; then
  _uname="$(uname -s 2>/dev/null || echo unknown)"
  if [[ "$_uname" == Darwin* ]]; then
    __dp_os="macos"
  else
    __dp_os="linux"
  fi
fi

if [[ "$__dp_os" == "macos" ]]; then
  # shellcheck source=/dev/null
  source "${__dp_repo}/shell/bash/macos.sh"
else
  # shellcheck source=/dev/null
  source "${__dp_repo}/shell/bash/linux.sh"
fi

# shellcheck source=/dev/null
source "${__dp_repo}/shell/bash/common.sh"

