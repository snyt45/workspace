#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"
# リンク対象外の直下ディレクトリ。それ以外の直下ディレクトリはすべて $HOME へリンクされる
# (隠しディレクトリ .git .claude 等は glob で除外される)
EXCLUDE=(_archive docs scripts vendor)

ok=0
ng=0
pruned=0
skipped=0

# src_root配下の全ファイルを dest_root へ同じ相対パスでファイル単位リンクする
link_tree() {
  local src_root="$1" dest_root="$2"
  while read -r src; do
    local rel="${src#$src_root/}"
    local dest="$dest_root/$rel"
    mkdir -p "${dest:h}"
    # 親ディレクトリの実パスが src_root 配下になる場合はスキップ。
    # 例: ~/.agents/skills/as-if-planned -> dotfiles直リンク。宛先が symlink を辿って
    # src_root（dotfiles実ファイル）自身に着地し、-f が実ファイルを自己参照リンクで破壊する。
    local dest_real="${dest:h}:A"
    if [[ "$dest_real" == "${src_root:A}"/* ]]; then
      echo "  SKIP(自己参照回避): ${dest/#$HOME/~}"
      ((skipped++))
      continue
    fi
    ln -sf "$src" "$dest"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
      echo "  OK: ${dest/#$HOME/~}"
      ((ok++))
    else
      echo "  NG: ${dest/#$HOME/~}"
      ((ng++))
    fi
  done < <(find -L "$src_root" -type f -not -name '.DS_Store' -not -name '*.swp')
}

# dest配下(dest自体も含む)で src_root を指す切れたリンクを削除し、空になった親ディレクトリを畳む
# リンクは src_root の構造をミラーした深さにしか存在しないため、destの走査はその深さで打ち切る
# (無制限に再帰すると ~/work のような巨大ツリーの全スキャンになり数分かかる)
prune_links() {
  local src_root="$1" dest="$2"
  [[ -e "$dest" || -L "$dest" ]] || return 0
  local depth=1 f rel
  for f in "$src_root"/**/*(D-.N); do
    rel="${f#$src_root/}"
    local -a parts=(${(s:/:)rel})
    (( $#parts > depth )) && depth=$#parts
  done
  while read -r link; do
    local resolved="$(readlink "$link")"
    if [[ "$resolved" == "$src_root"/* && ! -e "$resolved" ]]; then
      echo "  PRUNE: ${link/#$HOME/~} -> $resolved"
      rm "$link"
      rmdir "${link:h}" 2>/dev/null
      ((pruned++))
    fi
  done < <(find "$dest" -maxdepth $depth -type l 2>/dev/null)
}

echo "dotfilesのシンボリックリンクを作成中..."

mkdir -p "$HOME/work"

for pkg in "$DOTFILES_DIR"/*(N/); do
  (( ${EXCLUDE[(Ie)${pkg:t}]} )) && continue
  for entry in "$pkg"/*(DN); do
    prune_links "$pkg" "$HOME/${entry:t}"
  done
  link_tree "$pkg" "$HOME"
done

# スキル/エージェントのミラー: 正規置き場 → 各ツールが読む場所へ
# Claude Code / OpenCode は ~/.agents/ を読まないためミラーが必要
for src dest in \
  "$HOME/.agents/skills" "$HOME/.claude/skills" \
  "$HOME/.agents/agents" "$HOME/.claude/agents" \
  "$HOME/.agents/agents" "$HOME/.config/opencode/agents"; do
  prune_links "$src" "$dest"
  link_tree "$src" "$dest"
done

echo
echo "合計: OK=${ok} NG=${ng} PRUNED=${pruned} SKIPPED=${skipped}"
if (( ng > 0 )); then
  echo "一部リンクに失敗しています。確認してください。"
else
  echo "すべてのリンクが正常に作成されました。"
fi
