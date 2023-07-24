#!/bin/bash

set -eux

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
  echo "${COLOR_PURPLE}$1${COLOR_NONE}"
  echo "${COLOR_GRAY}==============================${COLOR_NONE}"
}

error() {
  echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
  exit 1
}

warning() {
  echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
  echo "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
  echo "${COLOR_GREEN}$1${COLOR_NONE}"
}

title "Tool Install"
sudo apt-get update -yqq
sudo apt-get upgrade -yqq
sudo apt install make \
                 git \
                 zoxide \
                 fzf
success "Tool Install Done."

title "WSL2 Setting"
ln -s ~/.dotfiles/wsl2/wsl/wsl.conf ~/
ln -s ~/.dotfiles/wsl2/wsl/resolv.conf ~/
success "WSL2 Setting Done."

title "Bash Setting"
ln -s ~/.dotfiles/wsl2/bash/.bashrc ~/
ln -s ~/.dotfiles/wsl2/bash/.bashrc_local ~/

success "Bash Setting Done."

title "Git Setting"
git config --global user.name "yuta.sano"
git config --global user.email "snyt45@gmail.com"
git config --global core.editor vim
success "Git Setting Done."

# 作業データ共有用のディレクトリ
mkdir -p ~/work/
# 作業用コンテナで作業時のキャッシュを残すためのディレクトリ
mkdir -p ~/.shared_cache/
# Git 認証用の SSH 鍵を置くディレクトリ
mkdir -p ~/.ssh/

# TODO: .ssh配下にSSH鍵とconfigファイルをコピーしてくる、SSH鍵は適切なパーミッションを設定する

title "Clipboard"
[ -p ~/clip ] && echo already exists the pipe for clip || mkfifo ~/clip
ln -s ~/dotfiles/wsl2/dotfiles/script/clip.sh ~/
chmod +x ~/clip.sh
success "Clipboard Done."

title "Crontab"
crontab ~/dotfiles/wsl2/dotfiles/cron/cron.conf
success "Crontab Done."

info "wsl --shutdownでWSL2を再起動してください。"
success "Setup Done."