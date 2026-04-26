#!/usr/bin/env zsh

set -e

echo "Claude Code スキルをインストール中..."

# gh v2.90.0 以降が必要（gh skill サブコマンド）
if ! gh skill --help >/dev/null 2>&1; then
  echo "エラー: gh v2.90.0 以降が必要。brew upgrade gh を実行してください" >&2
  exit 1
fi

# vercel-labs/agent-skills
for skill in \
  react-best-practices \
  composition-patterns \
  deploy-to-vercel \
  vercel-cli-with-tokens \
  web-design-guidelines \
  react-native-skills \
  react-view-transitions; do
  gh skill install vercel-labs/agent-skills "skills/$skill" --agent claude-code --scope user --force
done

# ramziddin/solid-skills (SOLID原則, TDD, クリーンアーキテクチャ)
gh skill install ramziddin/solid-skills skills/solid --agent claude-code --scope user --force

# browser-use/browser-use (ブラウザ自動化CLI)
gh skill install browser-use/browser-use skills/browser-use --agent claude-code --scope user --force

# forrestchang/andrej-karpathy-skills (Karpathy流コーディング原則)
gh skill install forrestchang/andrej-karpathy-skills skills/karpathy-guidelines --agent claude-code --scope user --force

# Y0lan/laws-of-software-engineering (ソフトウェア工学の56法則)
gh skill install Y0lan/laws-of-software-engineering skills/laws-of-software-engineering --agent claude-code --scope user --force

echo "Claude Code スキルインストール完了"
