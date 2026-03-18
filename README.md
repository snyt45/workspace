# dotfiles

## 前提条件

- MacBookPro(M4)
- macOS Sequoia 15 系

## 構成

| レイヤー | ツール |
|----------|--------|
| ターミナル | Warp |
| エディタ(CLI) | Neovim |
| エディタ(GUI) | VSCode |
| Git UI | codediff + gitsigns |
| シェル | zsh + starship |
| 検索 | fzf, ripgrep, fd |
| バージョン管理 | mise |
| キーリマッパー | karabiner |

## セットアップ

### 1. リストア手順

1. システム環境設定 > 一般 > 転送またはリセット > すべてのコンテンツと設定を消去
2. Mac をアクティブ化するために Wi-Fi を選択し、再起動をクリックします。
3. 再起動後、セットアップアシスタントに従って Mac をセットアップしてください。

### 2. 必須インストール

#### Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### Git + mise

```sh
brew install git mise
```

### 3. リポジトリのクローン

```sh
git clone https://github.com/snyt45/workspace.git $HOME/.dotfiles
```

### 4. セットアップ

```sh
cd $HOME/.dotfiles
mise trust
mise run setup
```

### 5. 手動セットアップ

- [手動セットアップガイド](docs/manual-setup.md)
- [チートシート](docs/cheatsheet.md)

## メンテナンス

### パッケージの一括アップデート

```sh
brew upgrade
```
