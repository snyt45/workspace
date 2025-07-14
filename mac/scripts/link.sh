#!/usr/bin/env zsh

echo "dotfilesのシンボリックリンクを作成中..."

DOTFILES_DIR="$HOME/.dotfiles/mac"

# 作業データ共有用のディレクトリ
mkdir -p "$HOME/work/"

# Gitの設定
if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
    ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi

# Vimの設定
mkdir -p "$HOME/.vim"
if [ -f "$DOTFILES_DIR/vim/.vimrc" ]; then
    ln -sf "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vim/vimrc"
fi
mkdir -p "$HOME/.vim/autoload/"
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

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

# git-jumpのシンボリックリンクを作成
if [ -f "/opt/homebrew/share/git-core/contrib/git-jump/git-jump" ]; then
    ln -sf /opt/homebrew/share/git-core/contrib/git-jump/git-jump /opt/homebrew/bin/git-jump
fi

# diff-highlightのシンボリックリンクを作成
if [ -f "/opt/homebrew/share/git-core/contrib/diff-highlight/diff-highlight" ]; then
    ln -sf /opt/homebrew/share/git-core/contrib/diff-highlight/diff-highlight /opt/homebrew/bin/diff-highlight
fi

# claudeの設定
mkdir -p "$HOME/.claude"
if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
    ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
fi

mkdir -p "$HOME/.claude/commands"
if [ -f "$DOTFILES_DIR/claude/commands/pr-review.md" ]; then
    ln -sf "$DOTFILES_DIR/claude/commands/pr-review.md" "$HOME/.claude/commands/pr-review.md"
fi

if [ -f "$DOTFILES_DIR/claude/commands/toypo-api-search.md" ]; then
    ln -sf "$DOTFILES_DIR/claude/commands/toypo-api-search.md" "$HOME/.claude/commands/toypo-api-search.md"
fi

echo "✅ dotfilesのシンボリックリンク作成が完了しました"
