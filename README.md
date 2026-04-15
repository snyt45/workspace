# dotfiles

## 前提条件

- MacBookPro(M4)
- macOS Sequoia 15 系

## 構成

| レイヤー | ツール |
|----------|--------|
| ターミナル | Ghostty + tmux |
| エディタ(CLI) | Neovim |
| エディタ(GUI) | VSCode |
| Git UI | codediff + gitsigns |
| PRレビュー | snacks.nvim |
| AIコーディング | OpenCode (`c`) + Claude Code (`cx`) |
| シェル | zsh + starship |
| 検索 | fzf, ripgrep, fd |
| バージョン管理 | mise |
| シークレット管理 | 1Password CLI |
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

## dotfilesセットアップ

| コマンド | 説明 |
|----------|------|
| `mise run setup` | 全セットアップ実行 |
| `mise run packages` | Homebrewパッケージインストール |
| `mise run link` | シンボリックリンク作成 |
| `mise run skills` | Claude Codeスキルインストール |
| `mise run auth` | GitHub CLI認証 |
| `mise tasks` | タスク一覧表示 |

## mise (ランタイムバージョン管理)

| コマンド | 説明 |
|----------|------|
| `mise install` | .tool-versionsに従ってランタイムインストール |
| `mise use node@20` | Node.js 20を使用 |
| `mise ls` | インストール済みランタイム一覧 |
| `mise run <task>` | タスク実行 |
