#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"
PACKAGES=(git vim tmux zsh karabiner yazi claude)

stow_package() {
  local pkg="$DOTFILES_DIR/$1"
  find "$pkg" -type f -not -name '.DS_Store' -not -name '*.swp' | while read -r src; do
    local rel="${src#$pkg/}"
    local dest="$HOME/$rel"
    mkdir -p "${dest:h}"
    ln -sf "$src" "$dest"
  done
}

echo "dotfilesのシンボリックリンクを作成中..."

mkdir -p "$HOME/work" "$HOME/bin"

for pkg in $PACKAGES; do
  stow_package "$pkg"
done

# bin（パッケージ化しない）
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
