#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"

link() {
  local src="$DOTFILES_DIR/$1" dest="$2"
  mkdir -p "${dest:h}"
  if [[ -d "$src" ]]; then
    ln -sfn "$src" "$dest"
  elif [[ -f "$src" ]]; then
    ln -sf "$src" "$dest"
  fi
}

echo "dotfilesのシンボリックリンクを作成中..."

mkdir -p "$HOME/work" "$HOME/bin"

# 設定ファイル
link git/.gitconfig          "$HOME/.gitconfig"
link vim/.vimrc              "$HOME/.vim/vimrc"
link tmux/.tmux.conf         "$HOME/.tmux.conf"
link zsh/.zshrc              "$HOME/.zshrc"
link claude/settings.json    "$HOME/.claude/settings.json"
link claude/CLAUDE.md        "$HOME/.claude/CLAUDE.md"

# ディレクトリごとリンク
link karabiner      "$HOME/.config/karabiner"
link yazi           "$HOME/.config/yazi"
link claude/skills  "$HOME/.claude/skills"
link claude/rules   "$HOME/.claude/rules"

# bin
ln -sf "$DOTFILES_DIR/bin/ide" "$HOME/bin/"

# vim-plug
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Homebrew contrib tools
for tool in git-jump diff-highlight; do
  src="/opt/homebrew/share/git-core/contrib/$tool/$tool"
  [[ -f "$src" ]] && ln -sf "$src" "/opt/homebrew/bin/$tool"
done

echo "シンボリックリンク作成完了"
