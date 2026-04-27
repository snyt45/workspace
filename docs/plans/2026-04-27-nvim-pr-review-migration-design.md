# Neovim PR レビューを diffview.nvim へ移行

日付: 2026-04-27

## 背景

現状の PR レビューは自作 `lua/features/review.lua` + `codediff.nvim` + `snacks.picker` を組み合わせたカスタムワークフロー。`vim.g.review_base` でモードを持ち、base ブランチ vs HEAD の差分閲覧を実現している。

問題:

- `codediff.nvim` の character-level 差分描画 (C 実装) が flash.nvim 等と並ぶと体感で重いことがある
- 自作スクリプトの維持コストがかかる (snacks.picker のカスタム preview, files_changed, base モード分岐)
- diff バッファに LSP がアタッチしないため、「差分から `gd` できない」を回避するために `<leader>gs` で本物のファイルを別途開く動線になっている

## 目標

- ローカルかつ高速に PR レビューを完結できる
- 既存のレビューモード概念 (任意の base ブランチを選んで `base...HEAD` を見る) は維持する
- 通常の `<leader>gs` (snacks git_status) の用途を壊さない
- 自作コードを最小化する

## 採用する解

`diffview.nvim` 単独 + `gitsigns.nvim` (据置) の最小構成へ移行する。

理由:

- `:DiffviewOpen base...HEAD --imply-local` が現状の `CodeDiff base...HEAD` の意味論 (merge-base 比較) と完全に一致する
- `--imply-local` で右ペインがワーキングツリーの実バッファになるため、diff 内から直接 `gd` 等の LSP 操作が効く
- 内蔵 file panel が「変更ファイル一覧 + ファイル間ナビ」を兼ねるため、レビュー中の `M.files_changed()` 相当が不要になる
- 2026 年も active maintenance、native vim diff ベースで CodeDiff より軽い

## 設計

### プラグイン構成

| プラグイン | 状態 |
|---|---|
| `sindrets/diffview.nvim` | **新規追加** (`lua/plugins/diffview.lua`) |
| `lewis6991/gitsigns.nvim` | 据置 (現状のまま) |
| `esmuellert/codediff.nvim` | **削除** (`lua/plugins/codediff.lua` 削除) |

### `features/review.lua` の縮退

既存ファイルを縮退させる方向で残す (削除はしない)。理由は `:ReviewStart` の Telescope ブランチピッカーと `vim.g.review_base` 管理は再利用するため。

| 関数 / コマンド | 移行後 |
|---|---|
| `:ReviewStart [base]` | 残す (Telescope ブランチ選択 → base 入力 → DiffviewOpen 起動まで一気通貫) |
| `:ReviewEnd` | 残す (`vim.g.review_base` クリア + `:DiffviewClose`) |
| `M.files_changed()` | **削除** (Diffview file panel に任せる) |
| `M.code_diff()` | `:DiffviewOpen` ラッパーに置換 (base 有: `<base>...HEAD --imply-local` / base 無: 引数なし) |
| `M.code_diff_file()` | `:DiffviewFileHistory %` ラッパーに置換 (要素数の少ない単一ファイル履歴) |

### キーマップ設計

通常時とレビューモード時で挙動が分岐する点は変えない (既存の mental model を維持)。

| キー | 通常時 | レビューモード時 (vim.g.review_base 設定済み) |
|---|---|---|
| `<leader>gg` | `:DiffviewOpen` (working tree vs HEAD) | `:DiffviewOpen <base>...HEAD --imply-local` |
| `<leader>gf` | `:DiffviewFileHistory %` | `:DiffviewFileHistory % --range=<base>...HEAD` |
| `<leader>gs` | `Snacks.picker.git_status()` (据置) | **同左** (Diffview file panel が変更ファイル一覧を兼ねるためレビュー時分岐を撤廃) |
| `<leader>gh` | `:DiffviewFileHistory` (CodeDiff history の代替) | 同左 |
| `<leader>gb` | gitsigns blame (据置) | 同左 |
| `]c` / `[c` | gitsigns hunk nav (据置) | 同左 |

すべての `desc` は dotfiles 命名規則に従い `[Diffview]` / `[Review]` プレフィックスを付ける。

### コマンド設計

| コマンド | 動作 |
|---|---|
| `:ReviewStart [base]` | 引数あり: `vim.g.review_base = base` セット + `:DiffviewOpen base...HEAD --imply-local` 起動。引数なし: Telescope ブランチピッカー → 選択ブランチに switch → base 入力 → 同上起動 |
| `:ReviewEnd` | `vim.g.review_base = nil` + `:DiffviewClose` |

### init.lua

`require("features.review")` は据置 (review.lua を残すため)。

## 影響範囲

- `lua/plugins/codediff.lua` 削除
- `lua/plugins/diffview.lua` 新規追加
- `lua/features/review.lua` 改変 (関数縮退、DiffviewOpen 呼び出しに置換)
- `docs/cheatsheet.md` 更新 (キーマップ変更を反映、CodeDiff → Diffview)
- `init.lua` は変更なし

## 非目標 (やらない)

- `octo.nvim` / `gh-review.nvim` の導入 (GitHub コメント返信は別タスク)
- snacks.picker のカスタム preview を維持する (Diffview file panel に置換)
- `<leader>gs` をレビューモード時に別動作させる (Diffview file panel と用途が重複するため一本化)

## トレードオフ

- VSCode 風 character-level 差分強調を失う (line-level のみになる)
- Diffview の file panel は縦長レイアウトで、snacks ivy より画面占有が大きい
- `:ReviewStart` での base 切替は `:DiffviewOpen` 再起動を伴う (現状と同等)
