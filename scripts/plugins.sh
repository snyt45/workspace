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

# プラグイン一覧 (マーケットプレイス: claude-obsidian-marketplace)
PLUGINS_OBSIDIAN=(
  claude-obsidian       # Obsidian Wiki vault管理
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

# claude-obsidian-marketplace (要: marketplace add が先)
marketplaces=$(claude plugin marketplace list 2>/dev/null)
if ! echo "$marketplaces" | grep -q "claude-obsidian-marketplace"; then
  claude plugin marketplace add AgriciDaniel/claude-obsidian
fi
for plugin in "${PLUGINS_OBSIDIAN[@]}"; do
  if ! echo "$installed" | grep -q "$plugin@claude-obsidian-marketplace"; then
    claude plugin install "$plugin@claude-obsidian-marketplace"
  fi
done

echo "Claude Code プラグインインストール完了"
