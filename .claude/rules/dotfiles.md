# dotfilesリポジトリ固有ルール

## コマンド

- `mise run setup` - 全セットアップ実行（初回セットアップ時）
- `mise run link` - シンボリックリンク作成
- `mise run packages` - Homebrewパッケージインストール
- `mise run skills` - Claude Codeスキルインストール
- `mise run plugins` - Claude Codeプラグインインストール

## ドキュメント自動更新

設定ファイルを変更したら、関連するドキュメントも更新する。指示がなくても行う。

- キーマップやエイリアスの追加・変更・削除 → `docs/cheatsheet.md` を更新
- ツール構成やセットアップ手順の変更 → `README.md` を更新
- Brewfileの変更 → `README.md` の構成表と整合性を確認

## ディレクトリ構成

stow方式。各パッケージは `$HOME` 相対パスで配置し、`scripts/link.sh` でシンボリックリンクを作成する。

- リンク対象パッケージ: `scripts/link.sh` の `PACKAGES` 配列で管理
- パッケージ追加時は `PACKAGES` への追加を忘れない
- 不要になった設定は `_archive/mac/` に移動する（削除ではなく退避）
- セットアップタスクは `mise.toml` の `[tasks]` で定義

## Neovimキーマップの命名規則

キーマップの `desc` にグループプレフィックスを付ける。コマンドパレット（`<leader>p`）で `desc` が `[` で始まるキーマップだけを表示・検索するため。

ルール:
- init.lua / lsp.lua のキーマップ: 機能グループ名を使う（`[LSP]`, `[Nav]`, `[General]`, `[Code]`等）
- プラグインのキーマップ: プラグイン名を使う（`[Telescope]`, `[GitSigns]`, `[Harpoon]`, `[Diffview]`等）
- `desc` が `[` で始まるキーマップだけがコマンドパレットのキーマップ一覧に表示される

例: `{ desc = "[LSP] 定義ジャンプ" }`, `{ desc = "[Telescope] ファイル検索" }`

## 変更時の整合性チェック

- エイリアスやPATHを追加したら、依存パッケージが `Brewfile` に含まれているか確認
- シェル設定（.zshrc, .zshrc.d/*.zsh）を変更したら、外部ファイルのsourceに存在チェックがあるか確認
- Neovimプラグインを追加したら、キーマップを `docs/cheatsheet.md` に追記
