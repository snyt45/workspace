# dotfiles

## 前提条件

- MacBookPro(M4)
- macOS Sequoia 15 系

## 構成

| レイヤー | ツール |
|----------|--------|
| ターミナル | Ghostty + tmux |
| エージェントマルチプレクサ | herdr（tmuxからの移行を試行中） |
| エディタ(CLI) | Neovim |
| エディタ(GUI) | VSCode |
| Git UI | gitsigns |
| PRレビュー | diffview.nvim |
| 差分ビューア(TUI) | hunk |
| AIコーディング | OpenCode (`c`) + Claude Code (`cx`) + Pi (`pi`) |
| シェル | zsh + pure |
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
| `mise run link` | シンボリックリンク作成（dotfiles 由来の切れたリンクも掃除） |
| `mise run npm-latest` | npm を最新化（サプライチェーン対策の min-release-age v11.10+ 用） |
| `mise run auth` | GitHub CLI認証 |
| `mise tasks` | タスク一覧表示 |

## シンボリックリンクの仕組み

`scripts/link.sh` は「src配下の全ファイルを同じ相対パスでファイル単位リンクし、srcから消えたものはdest側の切れたリンクを掃除する」処理（`link_tree` / `prune_links`）だけで構成される。

- dotfiles直下のディレクトリは `EXCLUDE`（`_archive` `docs` `scripts` `vendor`）以外すべて `$HOME` へリンクされる（stow規約: 各パッケージは `$HOME` 相対パスで配置）
- スキル共有: 正規置き場は `~/.agents/skills`（OpenCode / Pi はここをネイティブに読む）
  - 自作スキル: `agents/.agents/skills/` から上記の仕組みでリンク
  - 外部スキル: skills CLI（`scripts/plugins.sh`）が実ディレクトリとして配置。更新は `npx skills update -g`
  - Claude Code は `~/.agents/skills` を読まないため、同じ処理で `~/.agents/skills` → `~/.claude/skills` にミラーする

## mise (ランタイムバージョン管理)

| コマンド | 説明 |
|----------|------|
| `mise install` | .tool-versionsに従ってランタイムインストール |
| `mise use node@24` | Node.js 24を使用 |
| `mise ls` | インストール済みランタイム一覧 |
| `mise run <task>` | タスク実行 |
