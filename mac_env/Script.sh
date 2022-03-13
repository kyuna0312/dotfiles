#!/bin/zsh

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install cocoapods pyenv

git clone "https://github.com/zsh-users/zsh-syntax-highlighting" ~/.zsh-syntax-highlighting

sudo chsh -s /bin/zsh

mv ./.zshrc ~/.zshrc
mv ./.gitconfig ~/.gitconfig

source ~/.zshrc

open "Default.terminal"
