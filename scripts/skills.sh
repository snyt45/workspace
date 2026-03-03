#!/usr/bin/env zsh

SKILLS_DIR="$HOME/.claude/skills"

echo "Claude Code スキルをインストール中..."

# vercel-labs/agent-skills (react-best-practices, web-design-guidelines, composition-patterns, react-native)
npx -y skills add vercel-labs/agent-skills -a claude-code -g -y --copy

# thoughtbot/rails-audit-thoughtbot (Rails コード監査)
if [[ ! -d "$SKILLS_DIR/rails-audit-thoughtbot" ]]; then
  git clone --quiet https://github.com/thoughtbot/rails-audit-thoughtbot.git "$SKILLS_DIR/rails-audit-thoughtbot"
fi

echo "Claude Code スキルインストール完了"
