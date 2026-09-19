# dotfilesリポジトリ固有ルール

## コマンド

- `mise run setup` - 全セットアップ実行（初回セットアップ時）
- `mise run link` - シンボリックリンク作成
- `mise run packages` - Homebrewパッケージインストール
- `mise run claude-plugins` - Claude Codeプラグインインストール
- `mise run plannotator` - Plannotator（レビューUI）インストール
- `mise run herdr` - herdrプラグイン・外部ツール統合のインストール

## ドキュメント自動更新

設定ファイルを変更したら、関連するドキュメントも更新する。指示がなくても行う。

- キーマップやエイリアスの追加・変更・削除 → `docs/cheatsheet.md` を更新
- ツール構成やセットアップ手順の変更 → `README.md` を更新
- Brewfileの変更 → `README.md` の構成表と整合性を確認

## ディレクトリ構成

stow方式。各パッケージは `$HOME` 相対パスで配置し、`scripts/link.sh` でシンボリックリンクを作成する。

- dotfiles直下のディレクトリは `scripts/link.sh` の `EXCLUDE` 配列に載せない限り自動でリンク対象になる（パッケージ追加時の登録作業は不要）
- リンク対象外にしたいディレクトリだけ `EXCLUDE` へ追加する
- 不要になった設定は `_archive/mac/` に移動する（削除ではなく退避）
- セットアップタスクは `mise.toml` の `[tasks]` で定義

## Neovimキーマップの命名規則

キーマップの `desc` にグループプレフィックスを付ける。コマンドパレット（`<leader>?`）で `desc` が `[` で始まるキーマップだけを表示・検索するため。

ルール:
- init.lua / lsp.lua のキーマップ: 機能グループ名を使う（`[LSP]`, `[Nav]`, `[General]`, `[Code]`等）
- プラグインのキーマップ: プラグイン名を使う（`[Telescope]`, `[GitSigns]`, `[Harpoon]`, `[Diffview]`等）
- `desc` が `[` で始まるキーマップだけがコマンドパレットのキーマップ一覧に表示される

例: `{ desc = "[LSP] 定義ジャンプ" }`, `{ desc = "[Telescope] ファイル検索" }`

## 変更時の整合性チェック

- エイリアスやPATHを追加したら、依存パッケージが `Brewfile` に含まれているか確認
- シェル設定（.zshrc, .zshrc.d/*.zsh）を変更したら、外部ファイルのsourceに存在チェックがあるか確認
- Neovimプラグインを追加したら、キーマップを `docs/cheatsheet.md` に追記

## obsidian-second-brain の管理

- 導入は Claude Code プラグイン（`mise run claude-plugins` が marketplace 登録 + install を冪等に実行）。実体は `~/.claude/plugins/marketplaces/obsidian-second-brain`、更新は `claude plugin update obsidian-second-brain`
- 設定は claude/.claude/settings.json で宣言: `enabledPlugins`・`extraKnownMarketplaces`・env の `OBSIDIAN_VAULT_PATH`
- プラグインが提供するのは commands（47個, `/obsidian-second-brain:*`）+ MCP（vault）。hooks は提供しない（vault の `.claude/CLAUDE.md` の `@../_CLAUDE.md` import がマニュアル読込を担う）
- **settings.json が実体化していたら**: Claude Code が設定保存時に symlink を実体化することがある。実体に dotfiles に無い差分があれば取り込んでから `mise run link` で再リンクする
