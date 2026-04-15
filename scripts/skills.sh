#!/usr/bin/env zsh

SKILLS_DIR="$HOME/.claude/skills"

echo "Claude Code スキルをインストール中..."

# vercel-labs/agent-skills (react-best-practices, web-design-guidelines, composition-patterns, react-native)
npx -y skills add vercel-labs/agent-skills -a claude-code -g -y --copy

# ramziddin/solid-skills (SOLID原則, TDD, クリーンアーキテクチャ)
npx -y skills add ramziddin/solid-skills -a claude-code -g -y --copy

# thoughtbot/rails-audit-thoughtbot (Rails コード監査)
if [[ ! -d "$SKILLS_DIR/rails-audit-thoughtbot" ]]; then
  git clone --quiet https://github.com/thoughtbot/rails-audit-thoughtbot.git "$SKILLS_DIR/rails-audit-thoughtbot"
fi

# browser-use/browser-use (ブラウザ自動化CLI)
npx -y skills add https://github.com/browser-use/browser-use --skill browser-use -a claude-code -g -y --copy

# forrestchang/andrej-karpathy-skills (Karpathy流コーディング原則)
npx -y skills add forrestchang/andrej-karpathy-skills -a claude-code -g -y --copy

# 既存スキルを最新に更新
npx -y skills update -a claude-code -g -y

echo "Claude Code スキルインストール完了"
