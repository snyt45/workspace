#!/usr/bin/env zsh

echo "共有スキルをインストール中..."

# 外部スキル (skills CLI経由)
# -a universal で実体が ~/.agents/skills に入る (opencode/piはネイティブに読む)
# 再実行は冪等 (既存はスキップ)。更新は: npx skills update -g
[[ -d "$HOME/.agents/skills/herdr" ]]       || npx -y skills add ogulcancelik/herdr --skill herdr -g -a universal -y
[[ -d "$HOME/.agents/skills/hunk-review" ]] || npx -y skills add modem-dev/hunk --skill hunk-review -g -a universal -y
[[ -d "$HOME/.agents/skills/wayfinder" ]]   || npx -y skills add mattpocock/skills -s '*' -g -a universal -y
[[ -d "$HOME/.agents/skills/i-have-adhd" ]] || npx -y skills add ayghri/i-have-adhd --skill i-have-adhd -g -a universal -y
[[ -d "$HOME/.agents/skills/lavish" ]]      || npx -y skills add kunchenguid/lavish-axi --skill lavish -g -a universal -y

# crit (レビューループCLI、本体はBrewfile) のスキル
# codex向けintegrationが ~/.agents/skills に配置されるため、それを共有スキルとして使う
# (claude-code/opencode/pi向けintegrationは各ツール固有の場所に入るので使わない)
[[ -d "$HOME/.agents/skills/crit" ]] || (cd "$HOME" && crit install codex)

# 取得した外部スキルを各エージェントへ配布する (~/.agents/skills → ~/.claude/skills のミラー)
# 上のインストールで実ディレクトリが増えた後でないとミラーされないため、必ずここで呼ぶ
"$HOME/.dotfiles/scripts/link.sh" | tail -2

echo "共有スキルインストール完了"
