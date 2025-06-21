#!/usr/bin/env zsh

echo "dotfilesのシンボリックリンクを作成中..."

DOTFILES_DIR="$HOME/.dotfiles/mac"

# 作業データ共有用のディレクトリ
mkdir -p "$HOME/work/"
# 作業用コンテナで作業時のキャッシュを残すためのディレクトリ
mkdir -p "$HOME/.shared_cache/"

# Gitの設定
cp "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
git config --global user.name "yuta.sano"
git config --global user.email "snyt45@gmail.com"

# SSHの設定
mkdir -p "$HOME/.ssh"
cp "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# Vimの設定
mkdir -p "$HOME/.vim"
mkdir -p "$HOME/.vim/autoload/"
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p "$HOME/.vim/config/"
ln -sf "$DOTFILES_DIR/.vim/vimrc" "$HOME/.vim/"
ln -sf "$DOTFILES_DIR/.vim/config/.ctrlp-launcher" "$HOME/.vim/config/"

# efm-langserverの設定
mkdir -p "$HOME/.config/efm-langserver"
ln -sf "$DOTFILES_DIR/efm-langserver/config.yaml" "$HOME/.config/efm-langserver/config.yaml"

# Tmuxの設定
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Karabiner-Elements設定
mkdir -p "$HOME/.config/karabiner"
ln -sf "$DOTFILES_DIR/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

# Zshの設定
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# bin
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/ide" "$HOME/bin/"

echo "✅ dotfilesのシンボリックリンク作成が完了しました"