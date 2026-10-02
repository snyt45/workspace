#!/bin/sh
# Claude Code の PreToolUse hook（Bash）。本番と「反映」の操作を止める。判断はしない。
# 止めるもの:
#   本番クラスタ・本番アカウントを含むコマンド（toypo-production / 614159438634）
#   kubectl config（コンテキストの一覧・切り替え）
#   --apply、kubectl apply、terraform apply（反映は私が実行する）
# 止めたら exit 2 で、理由を stderr に出す（Claude に見える）
cmd=$(jq -r '.tool_input.command // ""')

case "$cmd" in
  *toypo-production*|*614159438634*)
    echo "guard-bash: 本番（toypo-production）には触らない。本番の値は私が確かめる" >&2
    exit 2 ;;
esac

if printf '%s' "$cmd" | grep -Eq -- '(^|[[:space:]])--apply([[:space:]]|$)|(^|[[:space:]&;|])kubectl[[:space:]]+(config|apply)([[:space:]]|$)|(^|[[:space:]&;|])terraform[[:space:]]+apply([[:space:]]|$)'; then
  echo "guard-bash: --apply / kubectl config / kubectl apply / terraform apply は私が実行する。dry run か sandbox の読み取りまで" >&2
  exit 2
fi

exit 0
