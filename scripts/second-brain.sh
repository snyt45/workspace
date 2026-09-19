#!/usr/bin/env bash
# obsidian-second-brain（外部 vendor: eugeniughelbur/obsidian-second-brain）の導入・更新
#
# 管理方針:
# - 実体は ~/.claude/skills/obsidian-second-brain に git clone（上流から取り込み、更新は git pull）
# - install.sh は冪等（既存コマンドは skip、load_vault_context hook は重複登録しない）
# - settings.json の hooks / env（OBSIDIAN_VAULT_PATH 等）は dotfiles の claude パッケージで管理。
#   install.sh が settings.json を編集するのは初回のみで、その後は既存エントリを検出して変更しない
set -eu

SKILL_DIR="$HOME/.claude/skills/obsidian-second-brain"
REPO="https://github.com/eugeniughelbur/obsidian-second-brain.git"

if [ -d "$SKILL_DIR/.git" ]; then
  echo "second-brain: 上流を更新（git pull --ff-only）"
  git -C "$SKILL_DIR" pull --ff-only
else
  echo "second-brain: clone → $SKILL_DIR"
  git clone "$REPO" "$SKILL_DIR"
fi

echo "second-brain: install.sh 実行（commands 47個のリンク・skill・hooks 登録。冪等）"
bash "$SKILL_DIR/install.sh"

echo
echo "完了。次: vault を /obsidian-init で初期化（Claude Code セッション内）。"
echo "OBSIDIAN_VAULT_PATH は claude/.claude/settings.json で管理（dotfiles）"