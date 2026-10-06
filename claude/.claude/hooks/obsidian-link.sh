#!/bin/sh
# Claude Code の PostToolUse hook（Write）。vault に .md を新しく作ったら Obsidian で開き、開き直すコマンドを応答に載せさせる。
# 既存ファイルの上書き（tool_response.type = update）では何もしない
# 開くのは bin の obs。ターミナルが obsidian:// のリンクを開けないため、開き直しは `!` で実行できる1行にする
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/my-vault/"
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
type=$(printf '%s' "$input" | jq -r '.tool_response.type // ""')

case "$file" in
  "$VAULT"*.md) ;;
  *) exit 0 ;;
esac
[ "$type" = create ] || exit 0

"$HOME/bin/obs" "$file" >/dev/null 2>&1
jq -n --arg cmd "! obs \"$file\"" '{hookSpecificOutput: {hookEventName: "PostToolUse",
  additionalContext: ("Obsidian のノートを作り、Obsidian で開いた。応答の最後に、開き直すためのこの1行をコードとしてそのまま載せる: `" + $cmd + "`")}}'
