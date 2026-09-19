#!/usr/bin/env zsh

echo "Claude Code プラグインをインストール中..."

# settings.json の enabledPlugins 宣言だけでは自動インストールされないため、スクリプトで行う
installed=$(claude plugin list 2>/dev/null)

# Plannotator (マーケットプレイス: backnotprop/plannotator。本体CLIは mise run plannotator)
if ! echo "$installed" | grep -q "plannotator@plannotator"; then
  claude plugin marketplace add backnotprop/plannotator
  claude plugin install plannotator@plannotator
fi

# obsidian-second-brain (マーケットプレイス: eugeniughelbur/obsidian-second-brain。vault統合)
# 注意: claude plugin install は settings.json を書き換えるため、symlink が実体化することがある。
# 実行後に ~/.claude/settings.json が symlink でなければ mise run link で再リンクする（差分があれば先に dotfiles へ取り込む）
if ! echo "$installed" | grep -q "obsidian-second-brain@obsidian-second-brain"; then
  claude plugin marketplace add eugeniughelbur/obsidian-second-brain
  claude plugin install obsidian-second-brain@obsidian-second-brain
fi

echo "Claude Code プラグインインストール完了（plannotator / ruby-lsp / obsidian-second-brain）"
