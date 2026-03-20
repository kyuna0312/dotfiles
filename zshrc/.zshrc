# Cyberpunk dotfiles (Lucy-inspired) - OS-split zsh entrypoint
#
# This file intentionally short-circuits after sourcing the modular configs.
__dp_entry="${${(%):-%N}:A}"
__dp_repo="${__dp_entry:h:h}"

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
  source "${__dp_repo}/shell/zsh/macos.zsh"
else
  source "${__dp_repo}/shell/zsh/linux.zsh"
fi

source "${__dp_repo}/shell/zsh/common.zsh"
return 0
