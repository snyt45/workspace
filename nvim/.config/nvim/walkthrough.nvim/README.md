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

設定はこの2項目のみ。色は `WalkthroughLocator` / `WalkthroughSeparator` / `WalkthroughAuthor` ハイライトグループを `vim.api.nvim_set_hl` で上書きする。

依存: なし。snacks.nvimがあればステップ一覧（`<leader>wl`）がnoteプレビュー付きpickerになる（なければ `vim.ui.select` にフォールバック）。

## キーマップ（デフォルト）

| キー | 動作 |
|---|---|
| `]w` / `[w` | 次 / 前のステップ |
| `<leader>wl` | ステップ一覧から選んでジャンプ（noteプレビュー付き） |
| `<leader>wo` | 統合picker: ロード済みセッション（位置保持で切替）+ 未ロードJSON（mtime降順・新規ロード）。snacks時は `<c-d>`（一覧では `d`）で選択項目を**JSONごと削除**（削除前に確認あり）。`protect_json` の連携セッション（pi-comments等）は `hooks.actions.purge` に実データの削除を委ねる（なければ削除不可） |
| `<leader>wt` | noteフロートをトグル。開くのはカーソル下のステップ（なければアクティブステップ）。**開くと同時にフォーカスされる**（フロート内の e/d/r/q がそのまま使える）。表示中でも別ステップの上で押すとそのステップへ切り替え、それ以外は閉じる |
| `<leader>w<CR>` | noteフロートにフォーカス（閉じていれば開いてフォーカス・`q` で戻る）。`,wt` で開いた場合はフォーカス済みのため不要 |
| `<leader>we` | カーソル下のステップの編集アクションを直接呼ぶ（`hooks.actions.edit`。フロートを開かず1キーで編集モーダルへ） |
| `<leader>wq` | アクティブセッションを閉じる（pinセッションは非アクティブ化のみ・`,wo`で戻れる） |
| `<leader>wR` | JSONを再読み込み（現在位置は維持） |

コマンド: `:Walkthrough [path]`（無指定はpicker）。

## 公開API

```lua
local wt = require("walkthrough")

wt.setup(opts)          -- 上記2項目
wt.start(spec)          -- コアAPI: Luaテーブルからセッション作成+アクティブ化。同名セッションは置き換え
wt.update(spec)         -- 連携API: nameでセッション置換（index省略時は維持）。表示中のフロートはその場で再描画（表示は奪わない）
wt.remove(name)         -- 連携API: セッションを名前で削除（アクティブなら表示もクリア）
wt.activate(name)       -- 連携API: セッションを名前でアクティブ化（現在位置へジャンプ）
wt.start_file(path)     -- JSONを読んで start() する薄いラッパー
wt.next() / wt.prev()   -- ステップ移動
wt.goto_step(n)         -- ステップNへ（プロデューサー・連携用）
wt.steps()              -- ステップ一覧picker（note+valuesのプレビュー付き。選択でジャンプ）
wt.open()               -- 統合picker（セッション切替 + JSONロード。snacks時は<c-d>/dで削除）
wt.close()              -- アクティブセッションを閉じる（pinは非アクティブ化のみ）
wt.edit_at_cursor()     -- カーソル下のステップを直接編集（hooks.actions.edit。キーマップ,we）
wt.reload()             -- JSON再読み込み
wt.toggle_float() / wt.focus_float()
wt.set_reply_handler(fn) -- 連携API: thread付きステップのフロートで r を押したときの返信ハンドラ fn(session, idx) を登録（nilで解除）
wt.show(name, idx, opts) -- 連携API: 指定ステップのnoteフロートを開く（カーソル移動・フォーカスなし）
                         --   opts.if_free = true なら、既に何か表示中のときは開かない
wt.get_state()          -- 読み取り専用スナップショット（テスト・連携用）
```

- `remove(name)` はセッションをレジストリから外し、**JSON由来ならファイル自体も削除**する（`protect_json` 指定時はファイルを残す。実データごとの削除は連携プラグインの `hooks.actions.purge` が行う）
- **表示中ステップの更新に `show()` は不要**。`update()` がフロートをその場で描き直す（フォーカスも移動しない）。`show()` は「まだ開いていないステップを開きたい」ときだけ使う
- `start(spec)` / `update(spec)` の spec は `hooks` と `step_label`（表示名。デフォルト `step`）を持てる

```lua
hooks = {
  -- フロート内キーマップ。1〜2文字のキーだけを入れる（例: pi-nvim-comment は e=編集・d=削除）
  keys = { e = function(session, idx) end, d = function(session, idx) end },
  -- 意味的アクション。キーマップにはならない。walkthrough側の操作から呼ばれる
  actions = {
    edit = function(session, idx) end,   -- <leader>we
    delete = function(session, idx) end, -- 連携プラグイン用
    purge = function(session, idx) end,  -- <leader>wo の削除（protect_jsonセッションの実データ削除）
  },
}
```

`start(spec)` のspec:

```lua
{
  steps = { { file = "src/api.ts", line = 6, note = "...", values = {...} }, ... }, -- 必須
  name = "review-pr-123",  -- 省略時は自動命名。セッション一覧に表示される
  root = "/path/to/repo",  -- fileの解決基準。省略時はcwdのgit root
  description = "...",     -- 任意メタデータ
  commit = "<sha>",        -- 任意（JSON由来のstale検出用。HEADと違えば警告）
  index = 1,               -- 開始ステップ
  pin = false,             -- trueで非アクティブでもマーク常時表示 + close()で消えない（例: pi-comments）
  protect_json = false,    -- trueでremove()してもjson_pathのファイルを削除しない（連携セッションのスレッドJSON用）
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
      "thread": [
        { "author": "you", "text": "この分岐いらなくない？" },
        { "author": "pi", "text": "初回アクセス時に必要です。…" }
      ],
      "values": [
        { "name": "id", "value": "\"user:42\"", "line": 5 }
      ]
    }
  ]
}
```

- `steps[].file`: リポジトリ相対パス（スラッシュ区切り）
- `steps[].line`: 1始まり
- `steps[].note` / `steps[].thread`: どちらか一方。`thread` は同じ位置に積み上がる会話（`{author, text}` の時系列フラット配列。ネストなし）。`thread` があれば `note` は表示されない
- `steps[].values`: 任意。その時点で期待される変数状態。`line` は観測する行（必須）
- fileの解決: JSONのあるディレクトリのgit rootを基準にする

## 動作モデル

- 複数セッションをロードでき、フロート・巡回はアクティブな1本のみ。**pinされたセッションはマーク（サイン+要約）だけ常時表示**される
- アクティブなステップは `▶` + 行ハイライト + 変数値virtual text + 右上noteフロート。**同一セッションの他ステップも `▷` サインで常時表示**される
- noteフロートは**常に1枚**。`<leader>wt` はカーソル下のステップ（なければアクティブステップ）のnoteをトグルし、**開いたらフォーカスも移る**（フロート内 e/d/r/q が直接使える。`q` で戻る）。表示中に別ステップの上で押すと閉じずにそのステップへ切り替わる。pinセッションのステップ（例: pi-comments）はアクティブでなくてもカーソルを乗せて `<leader>wt` で読める
- `thread` 付きステップのフロートは発言ごとに `▌ author` ラベル + 区切り線で描画され、**最新の発言（末尾）が見える状態で開く**。`set_reply_handler` が登録されていればフロート内 `r` で返信できる（pi-nvim-comment が登録する）。ステップ一覧（`<leader>wl`）の要約には `💬N` + 最新発言が出る
- 編集は `<leader>we`（カーソル下のステップ。フロートを開かず `hooks.actions.edit` を直接呼ぶ）。pi-commentsの場合は編集モーダルが開き、確定でコメント・walkthrough双方に反映される
- 切り替え時は各セッションの現在位置を保持したまま該当ステップへ即ジャンプ
- `update()` は表示中のフロートが更新対象セッションを指していれば**同じステップのまま中身だけ差し替える**（ウィンドウを開き直さないのでフォーカスとスクロールが飛ばない）。別セッションを表示中なら触らない
- 永続化なし。nvim再起動でセッションは消える（JSON由来はファイルから開き直す）

## 内部構成

1ファイルに詰めず、責務ごとに分割している（`lua/walkthrough/`）。

| ファイル | 責務 |
|---|---|
| `init.lua` | 公開API・キーマップ・`:Walkthrough` |
| `session.lua` | セッションレジストリ（データ層）・spec検証・JSON読み込み |
| `render.lua` | バッファ上のマーカー・values描画 |
| `float.lua` | noteフロート（レイアウト・表示・トグル・返信ハンドラ） |
| `nav.lua` | ステップ間ジャンプ・アクティブ化 |
| `picker.lua` | ステップ一覧・統合picker |
| `ops.lua` | セッションの破棄（JSON削除・purge・確認） |
| `util.lua` | 通知・パス解決・折り返し |
