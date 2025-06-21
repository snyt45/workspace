#!/usr/bin/env zsh

echo "asdfでプログラミング言語をインストール中..."

# node
asdf plugin add nodejs
asdf install nodejs 14.21.0
asdf install nodejs 16.20.2
# yarn を使えるようにする
corepack enable
asdf reshim nodejs
# ruby
asdf plugin add ruby
asdf install ruby 2.7.2
# python
asdf plugin add python
asdf install python 2.7.18
# golang
asdf plugin add golang
asdf install golang 1.24.2

echo "✅ プログラミング言語のインストールが完了しました"