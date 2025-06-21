# mac 用の構築手順

## 前提条件

- MacBookPro(M4)
- macOS Sequoia 15 系

## 1. リストア手順

1. システム環境設定 > 一般 > 転送またはリセット > すべてのコンテンツと設定を消去
2. Mac をアクティブ化するために Wi-Fi を選択し、再起動をクリックします。
3. 再起動後、セットアップアシスタントに従って Mac をセットアップしてください。

## 2. 必須インストール

#### Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### Git

```sh
brew install git
```

## 3. リポジトリのクローン

```sh
git clone https://github.com/snyt45/workspace.git $HOME/.dotfiles
```

## 4. セットアップ

```sh
cd $HOME/.dotfiles/mac
make setup
```

## 5. 手動セットアップ

[手動セットアップガイド](/mac/MANUAL_SETUP.md)
