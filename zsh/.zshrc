eval "$(/opt/homebrew/bin/brew shellenv)"

# 補完システムの初期化 (fpath設定後、compdefを使う設定の読み込みより前に必要)
fpath+=("/opt/homebrew/share/zsh/site-functions")
autoload -Uz compinit && compinit

for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done
