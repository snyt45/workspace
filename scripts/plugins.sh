#!/usr/bin/env zsh

echo "Claude Code プラグインをインストール中..."

# プラグインの依存
# ruby-lsp gem (ruby-lspプラグインが必要とする)
mise exec ruby@3.2.8 -- gem list -i ruby-lsp -q >/dev/null 2>&1 \
  || mise exec ruby@3.2.8 -- gem install ruby-lsp

# プラグイン一覧 (マーケットプレイス: claude-plugins-official)
PLUGINS=(
  ruby-lsp              # Ruby LSP連携
  claude-md-management  # CLAUDE.md管理
)

installed=$(claude plugin list 2>/dev/null)
for plugin in "${PLUGINS[@]}"; do
  if ! echo "$installed" | grep -q "$plugin@claude-plugins-official"; then
    claude plugin install "$plugin@claude-plugins-official"
  fi
done

echo "Claude Code プラグインインストール完了"
