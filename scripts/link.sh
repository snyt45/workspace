#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"
PACKAGES=(bin git nvim zsh karabiner claude mise tmux starship)

ok=0
ng=0

stow_package() {
  local pkg="$DOTFILES_DIR/$1"
  while read -r src; do
    local rel="${src#$pkg/}"
    local dest="$HOME/$rel"
    mkdir -p "${dest:h}"
    ln -sf "$src" "$dest"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
      echo "  OK: ~/$rel"
      ((ok++))
    else
      echo "  NG: ~/$rel"
      ((ng++))
    fi
  done < <(find "$pkg" -type f -not -name '.DS_Store' -not -name '*.swp')
}

echo "dotfilesのシンボリックリンクを作成中..."

mkdir -p "$HOME/work" "$HOME/bin"

for pkg in $PACKAGES; do
  stow_package "$pkg"
done

# Homebrew contrib tools
for tool in git-jump diff-highlight; do
  src="/opt/homebrew/share/git-core/contrib/$tool/$tool"
  [[ -f "$src" ]] && ln -sf "$src" "/opt/homebrew/bin/$tool"
done

echo
echo "合計: OK=${ok} NG=${ng}"
if (( ng > 0 )); then
  echo "一部リンクに失敗しています。確認してください。"
else
  echo "すべてのリンクが正常に作成されました。"
fi
