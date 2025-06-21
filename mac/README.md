# mac 用の構築手順

## 前提条件

- MacBookPro(M4)
- macOS Sequoia 15 系

## 1. リストア手順

1. システム環境設定 > 一般 > 転送またはリセット > すべてのコンテンツと設定を消去
2. Mac をアクティブ化するために Wi-Fi を選択し、再起動をクリックします。
3. 再起動後、セットアップアシスタントに従って Mac をセットアップしてください。

## 2. Mac の環境構築

homebrew をインストールする。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Mac ホスト用のセットアップを行うため、Git をインストールする。

```sh
brew install git
git config --global user.name "yuta.sano"
git config --global user.email "snyt45@gmail.com"
```

Mac ホスト用のセットアップを行うため、リポジトリをクローンする。

```sh
git clone https://github.com/snyt45/workspace.git $HOME/.dotfiles
```

Mac ホスト用の設定とツール群のインストールを行う。

```sh
cd $HOME/.dotfiles/mac
./setup.sh
```

GitHub の SSH key の設定を行う。

```sh
# `~/.ssh`にSSH keyをコピー
# 適切なパーミッションに設定
chmod 600 <SSH key>

# 接続確認
ssh -T git@<user name>
```

## 3. 手動セットアップ

[手動セットアップガイド](/mac/MANUAL_SETUP.md)
