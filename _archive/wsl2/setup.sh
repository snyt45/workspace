#!/bin/bash

set -eu

# install
sudo apt-get update -yqq
sudo apt-get upgrade -yqq
sudo apt install -yqq \
  make \
  git \
  zoxide \
  fzf \
  socat

DOTFILES_DIR="$HOME/.dotfiles/wsl2"

# 作業データ共有用のディレクトリ
mkdir -p "$HOME/work/"
# 作業用コンテナで作業時のキャッシュを残すためのディレクトリ
mkdir -p "$HOME/.shared_cache/"

# Gitの設定
cp "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# SSHの設定
mkdir -p "$HOME/.ssh"
cp "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# WSLの設定
sudo ln -snfv "$DOTFILES_DIR/wsl/wsl.conf" /etc/
sudo ln -snfv "$DOTFILES_DIR/wsl/resolv.conf" /etc/

# bashの設定
sudo ln -snfv "$DOTFILES_DIR/bash/.bashrc" ~/
sudo ln -snfv "$DOTFILES_DIR/bash/.bashrc_local" ~/

echo "セットアップが完了しました。再起動してください。"
