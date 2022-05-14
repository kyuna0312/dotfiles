#!/bin/zsh

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install cocoapods pyenv

brew install fish 

curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

sudo sh -c 'echo /opt/homebrew/bin/fish >> /etc/shells'

sudo chsh -s /opt/homebrew/bin/fish

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install

fish install --path=~/.local/share/omf --config=~/.config/omf

omf install https://github.com/h-matsuo/fish-theme-productive
omf theme fish-theme-productive

omf install https://github.com/h-matsuo/fish-color-scheme-switcher
omf reload

scheme

scheme ls | xargs -n1 -I {} fish -c 'scheme preview {} ; echo'

echo 'scheme set dracula' >> "$HOME/.config/fish/config.fish"


open "Default.terminal"
