#!/usr/bin/env zsh

echo "共有スキルをインストール中..."

# スキルの正規置き場は dotfiles の agents/.agents/skills (全部ファイルで自己管理、link.shで配布)。
# 外部由来のスキルも同じ場所に vendor する方針 (更新は上流から再コピー)。
# 例外は以下の2つだけ (Plannotator試験の結果次第で廃止予定。詳細: 断捨離計画 2026-08):

# lavish (HTMLアーティファクトレビュー、本体はmiseのnpm:lavish-axi)
[[ -d "$HOME/.agents/skills/lavish" ]] || npx -y skills add kunchenguid/lavish-axi --skill lavish -g -a universal -y

# crit (レビューループCLI、本体はBrewfile)
# codex向けintegrationが ~/.agents/skills に配置されるため、それを共有スキルとして使う
[[ -d "$HOME/.agents/skills/crit" ]] || (cd "$HOME" && crit install codex)

# スキルを各エージェントへ配布する (~/.agents/skills → ~/.claude/skills のミラー)
"$HOME/.dotfiles/scripts/link.sh" | tail -2

echo "共有スキルインストール完了"
