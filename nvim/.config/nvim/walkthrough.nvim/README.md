# walkthrough.nvim

コード上のポイント列（ステップ）をNeovim内で順に辿るUIプラグイン。
AIが生成したJSON、または他のプラグインが組み立てたLuaテーブルを流し込んで使う。

利用者・プロデューサーが知る必要があるのはこのREADMEの内容（設定・公開API・スキーマ）だけ。

## セットアップ

```lua
-- lazy.nvim
{
  dir = vim.fn.stdpath("config") .. "/walkthrough.nvim",
  name = "walkthrough.nvim",
  main = "walkthrough",
  event = "VeryLazy",
  opts = {
    dir = ".walkthroughs", -- JSON保存ディレクトリ名（<git root>相対）。スキル側の規約と対で変える
    keymaps = true,        -- false=無効 / テーブル=個別上書き（例: { next = "]s", close = false }）
  },
}
```

設定はこの2項目のみ。色は `WalkthroughLocator` / `WalkthroughSeparator` ハイライトグループを `vim.api.nvim_set_hl` で上書きする。

依存: なし。snacks.nvimがあればステップ一覧（`<leader>wg`）がnoteプレビュー付きpickerになる（なければ `vim.ui.select` にフォールバック）。

## キーマップ（デフォルト）

| キー | 動作 |
|---|---|
| `]w` / `[w` | 次 / 前のステップ |
| `<leader>wg` | ステップ一覧から選んでジャンプ（noteプレビュー付き） |
| `<leader>wo` | 保存ディレクトリからpickerで開く（mtime降順） |
| `<leader>ww` | セッション切り替え（位置保持・即ジャンプ） |
| `<leader>wt` | noteフロートの表示/非表示 |
| `<leader>w<CR>` | noteフロートにフォーカス（`q` で戻る） |
| `<leader>wq` | アクティブセッションを閉じる |
| `<leader>wR` | JSONを再読み込み（現在位置は維持） |

コマンド: `:Walkthrough [path]`（無指定はpicker）。

## 公開API

```lua
local wt = require("walkthrough")

wt.setup(opts)          -- 上記2項目
wt.start(spec)          -- コアAPI: Luaテーブルからセッション作成+アクティブ化。同名セッションは置き換え
wt.start_file(path)     -- JSONを読んで start() する薄いラッパー
wt.next() / wt.prev()   -- ステップ移動
wt.goto_step(n)         -- ステップNへ（プロデューサー・連携用）
wt.steps()              -- ステップ一覧picker（note+valuesのプレビュー付き。選択でジャンプ）
wt.open()               -- 保存ディレクトリのpicker
wt.switch()             -- セッション切り替えpicker
wt.close()              -- アクティブセッションを閉じる
wt.reload()             -- JSON再読み込み
wt.toggle_float() / wt.focus_float()
wt.status()             -- 現在位置を通知
wt.get_state()          -- 読み取り専用スナップショット（テスト・連携用）
```

`start(spec)` のspec:

```lua
{
  steps = { { file = "src/api.ts", line = 6, note = "...", values = {...} }, ... }, -- 必須
  name = "review-pr-123",  -- 省略時は自動命名。セッション一覧に表示される
  root = "/path/to/repo",  -- fileの解決基準。省略時はcwdのgit root
  description = "...",     -- 任意メタデータ
  commit = "<sha>",        -- 任意（JSON由来のstale検出用）
  index = 1,               -- 開始ステップ
}
```

## JSONスキーマ

```json
{
  "description": "メタデータ（UI非表示）",
  "commit": "40桁SHA（JSON運用では必須、コアではoptional）",
  "steps": [
    {
      "file": "src/api.ts",
      "line": 6,
      "note": "このステップの解説。\\nで複数段落",
      "values": [
        { "name": "id", "value": "\"user:42\"", "line": 5 }
      ]
    }
  ]
}
```

- `steps[].file`: リポジトリ相対パス（スラッシュ区切り）
- `steps[].line`: 1始まり
- `steps[].values`: 任意。その時点で期待される変数状態。`line` は観測する行（必須）
- fileの解決: JSONのあるディレクトリのgit rootを基準にする

## 動作モデル

- 複数セッションをロードでき、描画（行ハイライト・変数値のvirtual text・右上のnoteフロート）は常にアクティブな1本のみ
- 切り替え時は各セッションの現在位置を保持したまま該当ステップへ即ジャンプ
- 永続化なし。nvim再起動でセッションは消える（JSON由来はファイルから開き直す）
