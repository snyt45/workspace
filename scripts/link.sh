#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"
PACKAGES=(bin git nvim zsh karabiner claude mise tmux ghostty herdr opencode pi worktrunk lazygit npmrc agents)

ok=0
ng=0
pruned=0

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

prune_package() {
  local pkg="$DOTFILES_DIR/$1"
  for entry in "$pkg"/*(DN); do
    local name="${entry:t}"
    local target="$HOME/$name"
    [[ -e "$target" || -L "$target" ]] || continue
    if [[ -L "$target" ]]; then
      local resolved="$(readlink "$target")"
      if [[ "$resolved" == "$pkg"/* && ! -e "$resolved" ]]; then
        echo "  PRUNE: ~/$name -> $resolved"
        rm "$target"
        ((pruned++))
      fi
    elif [[ -d "$target" ]]; then
      while read -r link; do
        local resolved="$(readlink "$link")"
        if [[ "$resolved" == "$pkg"/* && ! -e "$resolved" ]]; then
          local rel="${link#$HOME/}"
          echo "  PRUNE: ~/$rel -> $resolved"
          rm "$link"
          ((pruned++))
        fi
      done < <(find "$target" -type l 2>/dev/null)
    fi
  done
}

echo "dotfilesのシンボリックリンクを作成中..."

mkdir -p "$HOME/work" "$HOME/bin"

for pkg in $PACKAGES; do
  prune_package "$pkg"
  stow_package "$pkg"
done

# Homebrew contrib tools
for tool in git-jump diff-highlight; do
  src="/opt/homebrew/share/git-core/contrib/$tool/$tool"
  [[ -f "$src" ]] && ln -sf "$src" "/opt/homebrew/bin/$tool"
done

# スキルの正規置き場は ~/.agents/skills (opencode/piはネイティブに読む)
# 自作スキルは agents パッケージ、外部スキルは scripts/plugins.sh (skills CLI) で入る
# 更新: npx skills update -g (ロックは ~/.agents/.skill-lock.json)

# Claude Codeは ~/.agents/skills を読まないため、スキルごとにリンクを張る
mkdir -p "$HOME/.claude/skills"
for skill in "$HOME/.agents/skills"/*(N); do
  dest="$HOME/.claude/skills/${skill:t}"
  if [[ -d "$dest" && ! -L "$dest" ]]; then
    echo "  SKIP(実ディレクトリのため手動確認): $dest"
    continue
  fi
  ln -sfn "$skill" "$dest"
done
# .agents側から消えたスキルのdanglingリンクを掃除
for link in "$HOME/.claude/skills"/*(N@); do
  if [[ ! -e "$link" ]]; then
    echo "  PRUNE: ~/.claude/skills/${link:t}"
    rm "$link"
  fi
done

echo
echo "合計: OK=${ok} NG=${ng} PRUNED=${pruned}"
if (( ng > 0 )); then
  echo "一部リンクに失敗しています。確認してください。"
else
  echo "すべてのリンクが正常に作成されました。"
fi
