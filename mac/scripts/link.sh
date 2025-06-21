#!/usr/bin/env zsh

echo "dotfilesのシンボリックリンクを作成中..."

DOTFILES_DIR="$HOME/.dotfiles/mac"

# 作業データ共有用のディレクトリ
mkdir -p "$HOME/work/"
# 作業用コンテナで作業時のキャッシュを残すためのディレクトリ
mkdir -p "$HOME/.shared_cache/"

# Gitの設定
if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
    ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi

# Vimの設定
if [ -f "$DOTFILES_DIR/vim/.vimrc" ]; then
    ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
fi
mkdir -p "$HOME/.vim/autoload/"
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
mkdir -p "$HOME/.vim/config/"
if [ -f "$DOTFILES_DIR/vim/config/.ctrlp-launcher" ]; then
    ln -sf "$DOTFILES_DIR/vim/config/.ctrlp-launcher" "$HOME/.vim/config/.ctrlp-launcher"
fi

# efm-langserverの設定
mkdir -p "$HOME/.config/efm-langserver"
ln -sf "$DOTFILES_DIR/efm-langserver/config.yaml" "$HOME/.config/efm-langserver/config.yaml"

# Tmuxの設定
if [ -f "$DOTFILES_DIR/tmux/.tmux.conf" ]; then
    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# Karabiner-Elements設定
mkdir -p "$HOME/.config/karabiner"
if [ -f "$DOTFILES_DIR/karabiner/karabiner.json" ]; then
    ln -sf "$DOTFILES_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
fi

# Zshの設定
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

# bin
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/ide" "$HOME/bin/"

echo "✅ dotfilesのシンボリックリンク作成が完了しました"
