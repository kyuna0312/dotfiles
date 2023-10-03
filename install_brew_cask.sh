#!/bin/sh
#############################################################
# Set development environment on Linux/macOS/Cygwin quickly.
# Author: Maririn312 <khatanzorigb@gmail.com>
# URL: https://github.com/maririn312/dotfiles
#############################################################


# Cask applications
apps=(
    alt-tab                    # hyperswitch
    monitorcontrol             # Controls external display brightness and volume
    raycast                    # Spotlight/Alfred replacement.
    karabiner-elements         # karabiner: Keboard remapping
    alfred
    utm
    docker
    netspot                    # Wifi signal analysis and scanner
    macfuse                    # File system
    warp
    docker                     # optional
    visual-studio-code
    motrix                     # Downloader: ariang
    macgesture
)

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if command -v tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

function check {
    # Check OS
    if [[ $OSTYPE != darwin* ]]; then
        echo "${RED}Error: only install software via brew_cask on macOS.${NORMAL}" >&2
        exit 1
    fi

    # Check brew
    if ! command -v brew >/dev/null 2>&1; then
        printf "${BLUE} ➜  Installing Homebrew and Cask...${NORMAL}\n"

        xcode-select --install
        /bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/Homebrew/install@HEAD/install.sh)"

        brew tap homebrew/cask
        brew tap homebrew/cask-versions
        brew tap homebrew/cask-fonts
        brew tap buo/cask-upgrade
    fi
}

function install () {
    for app in ${apps[@]}; do
        printf "${BLUE} ➜  Installing ${app}...${NORMAL}\n"
        brew install --cask ${app}
    done
}

function cleanup {
    brew cleanup
}

function main {
    check
    install
    cleanup
}

main
