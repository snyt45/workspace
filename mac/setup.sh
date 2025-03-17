#!/usr/bin/env zsh

# install
brew install iterm2
brew install google-chrome
brew install google-japanese-ime
brew install visual-studio-code
brew install slack
brew install zoom
brew install --cask scroll-reverser
brew install --cask karabiner-elements
brew install --cask alt-tab
brew install --cask tableplus
brew install --cask dropbox
brew install --cask kap
brew install --cask docker

# settings
DOTFILES_DIR="$HOME/.dotfiles/mac"
mkdir -p "$HOME/.config/karabiner"
ln -sf "$DOTFILES_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
