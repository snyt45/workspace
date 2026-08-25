# pi-nvim-comment

実行中のpiセッションへ行コメントレビューを送るプラグイン（旧 features/pi_review.lua の後継）。
carderne/pi-nvim のソケット自動発見・送信を再利用する。**コメントのコード上の表示・移動・編集は walkthrough.nvim のUIに一本化**しており、walkthrough.nvim の公開API（`update` / `remove` / `activate` / `hooks` / `step_label`）のみに依存する。

利用者が知る必要があるのはこのREADMEの内容（設定・キーマップ・公開API）だけ。

## 設定 (opts)

| キー | デフォルト | 説明 |
|---|---|---|
| `keymaps` | `true` | `false`=無効 / テーブル=個別上書き（例: `{ submit = false }`） |
| `instructions` | `nil` | 提出プロンプトの**指示文を丸ごと差し替え**る。省略時は上流pi-nvim-review同等のデフォルト指示（質問には回答・変更依頼は実装・曖昧なら確認、等） |
| `prompt_suffix` | `nil` | 指示文の**後に付記する文**。環境固有の指示（例: 「回答をwalkthrough JSONとして `.walkthroughs/` に保存しパスを報告」）はここで注入する |

## セットアップ

```lua
-- lazy.nvim
{
  dir = vim.fn.stdpath("config") .. "/pi-nvim-comment",
  name = "pi-nvim-comment",
  main = "pi-nvim-comment",
  dependencies = { "carderne/pi-nvim" },
  event = "VeryLazy",
  opts = {
    keymaps = true, -- false=無効 / テーブル=個別上書き（例: { submit = false }）
    prompt_suffix = "回答後、walkthrough JSON を出力する", -- 任意
  },
}
```

## キーマップ（デフォルト）

| キー | モード | 動作 |
|---|---|---|
| `<leader>pa` | n/x | 行/選択範囲にレビューコメント追加（コード上に常時マーク表示される） |
| `<leader>px` | n | コメントをpiへ提出（`opts.prompt_suffix` に応じて回答後の指示を付記) |

コマンド: `:PiReviewAnnotate` / `:PiReviewSubmit` / `:PiReviewClear`

**メンタルモデル: `,p*` はコメントを作る・送るだけ。見る・切り替える・辿るはすべてwalkthroughのキー（`,wo` `]w` `,wg` `,wt`）。** コメントは `pi-comments` という名前のwalkthroughセッションになり、他のセッションと完全に同じ操作で扱える。

## 公開API

```lua
local pc = require("pi-nvim-comment")
pc.setup(opts)
pc.annotate(start_line, end_line) -- コメント追加モーダル
pc.submit()                      -- piへ提出
pc.clear()                       -- 未提出コメント破棄
```

## コメントの表示（walkthrough連携）

- コメントを追加/編集/削除すると、未提出コメントが walkthrough.nvim の **`pi-comments` セッションとして自動同期**される（`wt.update` / `wt.remove`）。カーソルは動かない
- セッションは **`pin = true`** で同期されるため、他のwalkthroughを表示中でも**コメントのマークは常に見える**。`,wq` で閉じても消えず、`,wo` でいつでも戻れる。巡回・編集したいときは `,wo` で `pi-comments` に切り替える
- コード上には walkthrough のUIで表示される: `▶`/`▷` マーカー・行ハイライト・移動は `]w`/`[w`・ファイル単位のnote縦積みは `<leader>wt`・一覧pickerは `<leader>wg`・セッション切替は `<leader>wo`
- 表示名は `step_label = "comment"` で設定し、マーカーは `● comment 1/5` のようにコメント単位で表記される（walkthrough のデフォルトは `step`）
- noteフロートにフォーカス（`<leader>w<CR>`、連打で次へ循環）したときのキーは hooks で登録: **`e`=編集モーダル**（入力UIは追加時と同じ）/ **`d`=コメント削除**
- 提出（`<leader>px`）後は `pi-comments` セッションを閉じる。回答後の後処理は **環境側の `opts.prompt_suffix`** で指示する（例: 回答を `.walkthroughs/` のJSONとして返すよう pi に依頼）

## 動作メモ

- 未提出コメントは state ファイルに永続化され、nvim再起動後も復元される（復元時に `pi-comments` セッションへ同期）
- 提出プロンプト = 指示文（`opts.instructions`、省略時はデフォルト指示）+ `opts.prompt_suffix` + コメント一覧。ファイル配置による指示注入は持たない（すべてoptsで完結）
- 提出はカスタム extmark ではなく walkthrough のセッション表示に一本化している（独自の行追跡は持たない。行はずれる場合は `,pa` し直し）
