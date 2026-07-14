#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"
# リンク対象外の直下ディレクトリ。それ以外の直下ディレクトリはすべて $HOME へリンクされる
# (隠しディレクトリ .git .claude 等は glob で除外される)
EXCLUDE=(_archive docs scripts vendor)

ok=0
ng=0
pruned=0

# src_root配下の全ファイルを dest_root へ同じ相対パスでファイル単位リンクする
link_tree() {
  local src_root="$1" dest_root="$2"
  while read -r src; do
    local rel="${src#$src_root/}"
    local dest="$dest_root/$rel"
    mkdir -p "${dest:h}"
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
prune_links() {
  local src_root="$1" dest="$2"
  [[ -e "$dest" || -L "$dest" ]] || return 0
  while read -r link; do
    local resolved="$(readlink "$link")"
    if [[ "$resolved" == "$src_root"/* && ! -e "$resolved" ]]; then
      echo "  PRUNE: ${link/#$HOME/~} -> $resolved"
      rm "$link"
      rmdir "${link:h}" 2>/dev/null
      ((pruned++))
    fi
  done < <(find "$dest" -type l 2>/dev/null)
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

# Homebrew contrib tools
for tool in git-jump diff-highlight; do
  src="/opt/homebrew/share/git-core/contrib/$tool/$tool"
  [[ -f "$src" ]] && ln -sfn "$src" "/opt/homebrew/bin/$tool"
done

# スキルの正規置き場は ~/.agents/skills (opencode/piはネイティブに読む)
#   自作スキル: 上のループ(agentsパッケージ)でリンク済み
#   外部スキル: scripts/plugins.sh (skills CLI) が実ディレクトリとして配置
# Claude Codeは ~/.agents/skills を読まないため、同じ処理で ~/.claude/skills へミラーする
prune_links "$HOME/.agents/skills" "$HOME/.claude/skills"
link_tree "$HOME/.agents/skills" "$HOME/.claude/skills"

# エージェント定義の正規置き場は ~/.agents/agents (agentsパッケージでリンク済み)
# 1ファイルにClaude Code / opencode両対応のfrontmatterを書き、各ツールの置き場へミラーする
# (どちらも ~/.agents/agents は読まないため。未知のfrontmatterキーは互いに無視される)
prune_links "$HOME/.agents/agents" "$HOME/.claude/agents"
link_tree "$HOME/.agents/agents" "$HOME/.claude/agents"
prune_links "$HOME/.agents/agents" "$HOME/.config/opencode/agents"
link_tree "$HOME/.agents/agents" "$HOME/.config/opencode/agents"

echo
echo "合計: OK=${ok} NG=${ng} PRUNED=${pruned}"
if (( ng > 0 )); then
  echo "一部リンクに失敗しています。確認してください。"
else
  echo "すべてのリンクが正常に作成されました。"
fi
