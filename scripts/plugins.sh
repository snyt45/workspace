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

# 外部スキル (skills CLI経由)
# -a universal で実体が ~/.agents/skills に入る (opencode/piはネイティブに読む)
# 再実行は冪等 (既存はスキップ)。更新は: npx skills update -g
[[ -d "$HOME/.agents/skills/herdr" ]]       || npx -y skills add ogulcancelik/herdr --skill herdr -g -a universal -y
[[ -d "$HOME/.agents/skills/hunk-review" ]] || npx -y skills add modem-dev/hunk --skill hunk-review -g -a universal -y
[[ -d "$HOME/.agents/skills/wayfinder" ]]   || npx -y skills add mattpocock/skills -s '*' -g -a universal -y

# crit (レビューループCLI、本体はBrewfile) のスキル
# codex向けintegrationが ~/.agents/skills に配置されるため、それを共有スキルとして使う
# (claude-code/opencode/pi向けintegrationは各ツール固有の場所に入るので使わない)
[[ -d "$HOME/.agents/skills/crit" ]] || (cd "$HOME" && crit install codex)

# herdrのpi状態検知統合 (~/.pi/agent/extensions/herdr-agent-state.ts を生成)
if command -v pi >/dev/null && command -v herdr >/dev/null; then
  mkdir -p "$HOME/.pi/agent/extensions"
  [[ -f "$HOME/.pi/agent/extensions/herdr-agent-state.ts" ]] || herdr integration install pi
fi

# インストールしたスキルを各エージェントへ配布 (claudeへのsymlink)
"$HOME/.dotfiles/scripts/link.sh" | tail -2

echo "Claude Code プラグインインストール完了"
