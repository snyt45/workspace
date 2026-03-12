#!/usr/bin/env zsh

echo "Claude Code プラグインをインストール中..."

# プラグインの依存
# ruby-lsp gem (ruby-lspプラグインが必要とする)
mise exec ruby@3.2.8 -- gem list -i ruby-lsp -q >/dev/null 2>&1 \
  || mise exec ruby@3.2.8 -- gem install ruby-lsp

# プラグイン一覧 (マーケットプレイス: claude-plugins-official)
PLUGINS_OFFICIAL=(
  ruby-lsp              # Ruby LSP連携
  claude-md-management  # CLAUDE.md管理
)

# プラグイン一覧 (マーケットプレイス: claude-code-plugins)
PLUGINS_CLAUDE_CODE=(
  frontend-design       # フロントエンドデザイン生成
)

installed=$(claude plugin list 2>/dev/null)

for plugin in "${PLUGINS_OFFICIAL[@]}"; do
  if ! echo "$installed" | grep -q "$plugin@claude-plugins-official"; then
    claude plugin install "$plugin@claude-plugins-official"
  fi
done

for plugin in "${PLUGINS_CLAUDE_CODE[@]}"; do
  if ! echo "$installed" | grep -q "$plugin@claude-code-plugins"; then
    claude plugin install "$plugin@claude-code-plugins"
  fi
done

echo "Claude Code プラグインインストール完了"
