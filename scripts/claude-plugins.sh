#!/usr/bin/env zsh

echo "Claude Code プラグインをインストール中..."

# settings.json の enabledPlugins 宣言だけでは自動インストールされないため、スクリプトで行う
installed=$(claude plugin list 2>/dev/null)

# Plannotator (マーケットプレイス: backnotprop/plannotator。本体CLIは mise run plannotator)
if ! echo "$installed" | grep -q "plannotator@plannotator"; then
  claude plugin marketplace add backnotprop/plannotator
  claude plugin install plannotator@plannotator
fi

echo "Claude Code プラグインインストール完了"
