#!/usr/bin/env zsh

echo "Homebrew外のツールをインストール中..."

# smux (tmuxペイン間通信CLI)
if [[ ! -x "$HOME/.smux/bin/smux" ]]; then
  echo "smux をインストール中..."
  curl -fsSL https://shawnpana.com/smux/install.sh | bash
fi

echo "ツールインストール完了"
