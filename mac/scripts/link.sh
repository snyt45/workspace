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

# yazi
mkdir -p "$HOME/.config/yazi"
if [ -f "$DOTFILES_DIR/yazi/init.lua" ]; then
    ln -sf "$DOTFILES_DIR/yazi/init.lua" "$HOME/.config/yazi/init.lua"
fi
if [ -f "$DOTFILES_DIR/yazi/yazi.toml" ]; then
    ln -sf "$DOTFILES_DIR/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"
fi
if [ -f "$DOTFILES_DIR/yazi/keymap.toml" ]; then
    ln -sf "$DOTFILES_DIR/yazi/keymap.toml" "$HOME/.config/yazi/keymap.toml"
fi

# claude
mkdir -p "$HOME/.claude"
if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
    ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
fi

if [ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]; then
    ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
fi

for skill_dir in backend-patterns frontend-patterns pr-review security-review toypo-api-search; do
    mkdir -p "$HOME/.claude/skills/$skill_dir"
    if [ -f "$DOTFILES_DIR/claude/skills/$skill_dir/SKILL.md" ]; then
        ln -sf "$DOTFILES_DIR/claude/skills/$skill_dir/SKILL.md" "$HOME/.claude/skills/$skill_dir/SKILL.md"
    fi
done

echo "✅ dotfilesのシンボリックリンク作成が完了しました"
