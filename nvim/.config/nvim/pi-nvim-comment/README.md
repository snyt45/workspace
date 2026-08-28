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
| `<leader>px` | n | 未提出コメント**全部**をpiへ提出（`opts.prompt_suffix` に応じて回答後の指示を付記) |
| `<leader>py` | n | 提出内容（指示文+コメント一覧）をクリップボードにコピー（piへは送らない。提出と同じ内容を外部に貼り付けたいとき用） |

コメント入力モーダルの確定キーは2つ: **`<C-s>`=保存**（未提出リストに貯めて `,px` で一括提出）/ **`<C-x>`=即送信**（そのコメント1件だけをpiへ提出。他の未提出には触らない。1件だけ早く深掘りしたいとき用）。送信失敗時は未提出コメントとして残る。

コマンド: `:PiReviewAnnotate` / `:PiReviewSubmit` / `:PiReviewCopy` / `:PiReviewClear`

**メンタルモデル: `,p*` はコメントを作る・送るだけ。見る・切り替える・辿るはすべてwalkthroughのキー（`,wo` `]w` `,wl` `,wt`）。** コメントは `pi-comments` という名前のwalkthroughセッションになり、他のセッションと完全に同じ操作で扱える。

## 公開API

```lua
local pc = require("pi-nvim-comment")
pc.setup(opts)
pc.annotate(start_line, end_line) -- コメント追加モーダル
pc.submit()                      -- 未提出コメント全部をpiへ提出
pc.reply(session, idx)           -- walkthroughのthread付きステップへの返信モーダル（walkthroughのset_reply_handler経由で呼ばれる）
pc.copy()                        -- 提出内容をクリップボードにコピー（通知はvim.notify経由でnoice等が表示）
pc.clear()                       -- 未提出コメント破棄
```

## コメントの表示（walkthrough連携）

- コメントを追加/編集/削除すると、未提出コメントが walkthrough.nvim の **`pi-comments` セッションとして自動同期**される（`wt.update` / `wt.remove`）。カーソルは動かない
- セッションは **`pin = true`** で同期されるため、他のwalkthroughを表示中でも**コメントのマークは常に見える**。`,wq` で閉じても消えず、`,wo` でいつでも戻れる。巡回・編集したいときは `,wo` で `pi-comments` に切り替える
- コード上には walkthrough のUIで表示される: `▶`/`▷` マーカー・行ハイライト・移動は `]w`/`[w`・noteフロートのトグルは `<leader>wt`・一覧pickerは `<leader>wl`・セッション切替は `<leader>wo`
- 表示名は `step_label = "comment"` で設定し、マーカーは `● comment 1/5` のようにコメント単位で表記される（walkthrough のデフォルトは `step`）
- noteフロートにフォーカス（`<leader>wt` で開くと同時にフォーカスされる）したときのキーは hooks で登録: **`e`=編集モーダル**（入力UIは追加時と同じ）/ **`d`=コメント削除**。`d` は未提出の下書きだけでなく **piの回答スレッドも削除**できる（`.walkthroughs/comments.json` から該当ステップを除外）
- コメントを保存（`<leader>pa`）すると、そのコメントのフロートが**自動で開く**（カーソルは動かない。閉じたい場合は`,wt`）
- 提出（`<leader>px`）後も `pi-comments` セッションは残り、**回答済みスレッド（`.walkthroughs/comments.json`）が同じセッションに統合表示**される。回答の記録先は **環境側の `opts.prompt_suffix`** で指示する（例: 新規コメントの回答を `.walkthroughs/comments.json` に記録するよう pi に依頼）

## 回答の自動反映（pi-comments統合ビュー）

- 新規コメントへの回答は `.walkthroughs/comments.json`（1リポジトリ1ファイル）に記録される。pi-nvim-comment はこのファイルを3秒間隔で監視し、変更を検出すると pi-comments セッションに**自動で統合**する（開き直し・`,wo` は不要）。`,wo` には pi-comments の1つだけが並ぶ（comments.json が別枠で重複表示されない・セッション削除でファイルも消えない）
- 回答が来ると、**追加・更新されたスレッドのフロートが自動で開く**（開いていればその場に追記される。`r`=返信 `q`=閉じる）。C-x即送信したコメントの回答も同じく自動表示される
- 回答ステップは提出時のコメント位置にマーク表示され、マーカーにカーソルを置いて `,wt` でスレッド（コメント↔回答）が見え、フロート内 `r` で返信できる（返信も同じJSONに追記され自動反映）
- nvimを再起動しても `.walkthroughs/comments.json` が残っていれば起動時に pi-comments へ統合される
- **実データの削除**: `,wo` のC-d/d（または削除picker）で pi-comments を選ぶと、未提出コメント（state）・返信・スレッド（comments.json）を**まとめて削除**する（purge）。1件だけ消す場合はマーカー上で `,wt` → `d`（stateにも反映され再起動後も残らない）

## スレッドへの返信（walkthrough連携）

回答walkthrough（`thread` 付きステップ）のnoteフロートで **`r`** を押すと返信モーダルが開く（setup時に walkthrough の `set_reply_handler` へ登録している）。

- 返信は「そのステップと同じ行に付いた未提出コメント」として `pi-comments` に入る（noteに `↩ <walkthrough名> · step N への返信` が付く）。提出は通常どおり `,px`（一括）またはモーダルの `<C-x>`（この1件だけ即送信）
- pi-comments のステップ（回答スレッド）への返信は `.walkthroughs/comments.json` へ、他のwalkthroughのステップへの返信はそのセッションのJSONへ追記される
- 提出プロンプトの該当コメントには `Reply to walkthrough thread: <json path> (step N)` とスレッド履歴（`Thread so far:`）が付く。回答を**同じJSONの該当ステップの `thread` に追記**させるかは環境側の規約（walkthrough-comments スキル）に委ねる
- pi-comments への返信回答は監視により自動反映される。他のJSONでの返信は `,wR`（再読み込み）で反映される

## 動作メモ

- 未提出コメントは state ファイルに永続化され、nvim再起動後も復元される（復元時に `pi-comments` セッションへ同期・extmarkを再配置）
- 提出プロンプト = 指示文（`opts.instructions`、省略時はデフォルト指示）+ `opts.prompt_suffix` + コメント一覧。ファイル配置による指示注入は持たない（すべてoptsで完結）
- 提出はカスタム extmark ではなく walkthrough のセッション表示に一本化している。コメントの**行位置は extmark で追跡**し、注釈〜提出の間にコードを編集しても現在行へ追従する（提出時点より後の編集は従来同様 `,pa` し直し）
- 統合・自動反映の動作検証: `nvim --headless -u NONE -i NONE -c "luafile test/smoke.lua"`（`PI_TEST_DIR` に `init.lua` と `.walkthroughs/comments.json` 付きの一時プロジェクトを用意して実行）。`,wt` がマーカー位置でスレッドを直接開くことの検証は `test/float_thread.lua`
