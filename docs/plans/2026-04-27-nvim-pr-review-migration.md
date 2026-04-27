# Neovim PR レビューを diffview.nvim へ移行 — 実装プラン

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** CodeDiff + 自作 review.lua から diffview.nvim 単独 + gitsigns 据置の最小構成へ寄せる。

**Architecture:** `vim.g.review_base` を中心としたレビューモード概念は維持。`features/review.lua` はラッパーとして残し、内部の `CodeDiff` 呼び出しを `:DiffviewOpen base...HEAD --imply-local` に置換。`<leader>gs` は snacks.picker.git_status を直接呼ぶシンプルな束ね方に変える。

**Tech Stack:** Neovim, lazy.nvim, sindrets/diffview.nvim, lewis6991/gitsigns.nvim (据置), folke/snacks.nvim (据置)

**設計書:** `docs/plans/2026-04-27-nvim-pr-review-migration-design.md`

---

## 確認事項 (前提)

- 既存の `features/review.lua` は `:ReviewStart` / `:ReviewEnd` / `M.code_diff` / `M.code_diff_file` / `M.files_changed` を提供
- `<leader>gg` / `<leader>gf` / `<leader>gh` は `lua/plugins/codediff.lua` の lazy keys として定義
- `<leader>gs` は `lua/plugins/snacks.lua` の lazy keys で `require("features.review").files_changed()` を呼ぶ
- zsh エイリアス `vd` / `vdh` が CodeDiff を起動 (`zsh/.zshrc:11-12`)
- cheatsheet.md の Git/レビュー記述箇所: line 17-18, 295-329

各タスクは「ファイル編集 → Neovim を再起動して手動確認 → 問題なければコミット」のサイクル。

---

### Task 1: diffview.nvim プラグイン spec を追加

**Files:**
- Create: `nvim/.config/nvim/lua/plugins/diffview.lua`

**Step 1: diffview.lua を作成**

ファイル内容:

```lua
return {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
    keys = {
        { "<leader>gg", function() require("features.review").code_diff() end,      desc = "[Diffview] 全差分 (レビューモード時はbase...HEAD)" },
        { "<leader>gf", function() require("features.review").code_diff_file() end, desc = "[Diffview] 現バッファの単一ファイル差分 (レビューモード時はbase...HEAD)" },
        { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",                              desc = "[Diffview] 履歴" },
    },
    opts = {},
}
```

注意: keys が `features.review` を参照するが、Task 2 で review.lua 側を Diffview 呼び出しに置換するまでは中途半端な状態 (review.lua は CodeDiff を呼ぶが diffview のキーは review.code_diff を呼ぶので結果的に CodeDiff が呼ばれる)。Task 2 完了で整合する。

**Step 2: Neovim を起動して :Lazy sync で diffview をインストール**

Run: `nvim` を開いて `:Lazy sync` 実行
Expected: `sindrets/diffview.nvim` がインストール済みになる

**Step 3: :DiffviewOpen を試して動作確認**

Run: nvim 内で `:DiffviewOpen origin/main...HEAD --imply-local`
Expected: 左に file panel、右にワーキングツリー (`--imply-local`) のタブが開く。`:DiffviewClose` で閉じる。

**Step 4: コミット**

```bash
git add nvim/.config/nvim/lua/plugins/diffview.lua
git commit -m "$(cat <<'EOF'
diffview.nvim プラグインを追加

CodeDiff + 自作 review.lua の置き換え準備。キーマップは features.review
経由で呼ぶため、レビューモード分岐は次タスクで review.lua 側に集約する。

Created by snyt45 with Claude Code
EOF
)"
```

---

### Task 2: features/review.lua を Diffview 呼び出しに置換

**Files:**
- Modify: `nvim/.config/nvim/lua/features/review.lua`

**Step 1: review.lua を全面書き換え**

`M.files_changed` を削除し、`M.code_diff` / `M.code_diff_file` を Diffview 呼び出しに置換。`:ReviewStart` 内の `M.files_changed()` 起動も `M.code_diff()` (DiffviewOpen) に置換。`:ReviewEnd` で `:DiffviewClose` も呼ぶ。

新しい review.lua の内容:

```lua
-- ==========================================================================
-- レビューモード
-- vim.g.review_base を中心に、Diffview が同じbaseを参照する
-- ==========================================================================

local M = {}

local function apply_base(base)
    vim.g.review_base = base
end

local function start_with(base)
    apply_base(base)
    vim.notify("Review: " .. base)
    M.code_diff()
end

-- "origin/foo" のような remote ref を local branch 名に変換 (detached HEAD 回避のため)
local function to_local_branch(branch)
    local remotes = vim.fn.systemlist("git remote")
    for _, remote in ipairs(remotes) do
        local prefix = remote .. "/"
        if branch:sub(1, #prefix) == prefix then
            return branch:sub(#prefix + 1)
        end
    end
    return branch
end

vim.api.nvim_create_user_command("ReviewStart", function(opts)
    if opts.args and opts.args ~= "" then
        start_with(opts.args)
        return
    end
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    builtin.git_branches({
        attach_mappings = function(_, _)
            actions.select_default:replace(function(bufnr)
                local selection = action_state.get_selected_entry()
                actions.close(bufnr)
                if not selection or not selection.value then return end
                local local_name = to_local_branch(selection.value)
                local result = vim.system({ "git", "switch", local_name }):wait()
                if result.code ~= 0 then
                    vim.notify("switch failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
                    return
                end
                vim.notify("Switched to: " .. local_name)
                vim.ui.input({ prompt = "Compare base: ", default = "origin/main" }, function(base)
                    if not base or base == "" then return end
                    start_with(base)
                end)
            end)
            return true
        end,
    })
end, { nargs = "?", desc = "[Review] レビューモード開始" })

vim.api.nvim_create_user_command("ReviewEnd", function()
    apply_base(nil)
    pcall(vim.cmd, "DiffviewClose")
    vim.notify("Review off")
end, { desc = "[Review] レビューモード終了" })

-- <leader>gg: 全差分 (モード時はbase適用)
function M.code_diff()
    local base = vim.g.review_base
    if base then
        vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local")
    else
        vim.cmd("DiffviewOpen")
    end
end

-- <leader>gf: 現在バッファの単一ファイル差分 (モード時はbase適用)
function M.code_diff_file()
    local base = vim.g.review_base
    local file = vim.fn.fnameescape(vim.fn.expand("%"))
    if base then
        vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local -- " .. file)
    else
        vim.cmd("DiffviewOpen -- " .. file)
    end
end

return M
```

変更点:
- `M.files_changed` 関数を削除 (Diffview の file panel が代替)
- `M.code_diff` / `M.code_diff_file` の `vim.cmd("CodeDiff ...")` を `vim.cmd("DiffviewOpen ...")` に置換
- `M.code_diff_file` は `:DiffviewOpen [rev] -- <file>` でファイルフィルタする方式へ
- `start_with` の起動処理を `M.files_changed()` → `M.code_diff()` に変更 (Diffview の file panel に直接遷移)
- `:ReviewEnd` で `pcall(vim.cmd, "DiffviewClose")` を追加 (Diffview が開いていなくてもエラーにしない)

**Step 2: Neovim を再起動して動作確認 (通常モード)**

Run: `nvim` を開いて `<leader>gg`
Expected: `:DiffviewOpen` 相当でワーキングツリー vs HEAD の差分タブが開く

Run: 何かファイルを編集した状態で `<leader>gf`
Expected: 現在ファイルだけにフィルタされた差分が開く

**Step 3: 動作確認 (レビューモード)**

Run: `:ReviewStart origin/main` (もしくは引数なしで Telescope ピッカー → 選択 → base 入力)
Expected:
- `Review: origin/main` の通知
- `:DiffviewOpen origin/main...HEAD --imply-local` 相当の file panel が開く
- 右ペインがワーキングツリーの実バッファになっており、`gd` 等の LSP 操作が効く

Run: `<leader>gg` (レビューモード中)
Expected: 同じく base...HEAD の Diffview が開き直す

Run: `:ReviewEnd`
Expected: `Review off` 通知 + Diffview タブが閉じる

**Step 4: コミット**

```bash
git add nvim/.config/nvim/lua/features/review.lua
git commit -m "$(cat <<'EOF'
review.lua の内部実装を CodeDiff から Diffview へ置換

vim.g.review_base を軸とするレビューモード概念は維持しつつ、差分描画と
ファイル一覧を diffview.nvim に集約。--imply-local で右ペインが実バッファ
となり、差分内から直接 LSP 操作が効くようになる。

snacks.picker のカスタム changed-files preview (M.files_changed) は
Diffview の file panel が代替するため削除。

Created by snyt45 with Claude Code
EOF
)"
```

---

### Task 3: snacks.lua の `<leader>gs` を直接 git_status へ

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/snacks.lua:42`

**Step 1: 該当行を編集**

変更前:
```lua
{ "<leader>gs", function() require("features.review").files_changed() end,     desc = "[Snacks] git status (レビューモード時はbase差分)" },
```

変更後:
```lua
{ "<leader>gs", function() Snacks.picker.git_status({ layout = { preset = "ivy" } }) end, desc = "[Snacks] git status" },
```

理由: レビューモード時は Diffview の file panel が変更ファイル一覧を兼ねるため、`<leader>gs` のレビュー分岐を撤廃し、常に snacks の git_status を返すシンプルな束ね方に。

**Step 2: Neovim を再起動して動作確認**

Run: `nvim` を開いて `<leader>gs` (通常時)
Expected: snacks の git_status ピッカー (ivy レイアウト) が開く

Run: `:ReviewStart origin/main` 後に `<leader>gs`
Expected: **同じく** snacks git_status が開く (レビュー時専用挙動は撤廃)

**Step 3: コミット**

```bash
git add nvim/.config/nvim/lua/plugins/snacks.lua
git commit -m "$(cat <<'EOF'
<leader>gs のレビューモード分岐を撤廃

Diffview の file panel が変更ファイル一覧を兼ねるため、<leader>gs は
常に snacks.picker.git_status を返すシンプルな束ね方に統一する。

Created by snyt45 with Claude Code
EOF
)"
```

---

### Task 4: codediff.nvim プラグインを削除

**Files:**
- Delete: `nvim/.config/nvim/lua/plugins/codediff.lua`

**Step 1: ファイルを削除**

Run: `rm /Users/snyt45/.dotfiles/nvim/.config/nvim/lua/plugins/codediff.lua`

**Step 2: Neovim を再起動して :Lazy clean で codediff をアンインストール**

Run: `nvim` 起動 → `:Lazy clean` → 確認プロンプトに y で応答
Expected: `esmuellert/codediff.nvim` がアンインストールされる

**Step 3: :CodeDiff が未定義であることを確認**

Run: nvim 内で `:CodeDiff`
Expected: `E492: Not an editor command: CodeDiff` 等のエラー

**Step 4: コミット**

```bash
git add -A nvim/.config/nvim/lua/plugins/codediff.lua
git commit -m "$(cat <<'EOF'
codediff.nvim プラグインを削除

差分閲覧は diffview.nvim に集約済み。VSCode 風 character-level の
強調を失う代わりに、native vim diff ベースで軽量化される。

Created by snyt45 with Claude Code
EOF
)"
```

---

### Task 5: zsh エイリアス vd/vdh を Diffview 化

**Files:**
- Modify: `zsh/.zshrc:11-12`

**Step 1: 該当行を編集**

変更前:
```bash
alias vd='nvim +CodeDiff'
alias vdh='nvim +"CodeDiff history"'
```

変更後:
```bash
alias vd='nvim +DiffviewOpen'
alias vdh='nvim +DiffviewFileHistory'
```

**Step 2: 新しいシェルで動作確認**

Run: 新しいターミナルを開いて `vd`
Expected: nvim が起動し、起動直後に `:DiffviewOpen` が走る (ワーキングツリー差分)

Run: `vdh`
Expected: nvim が起動し、起動直後に `:DiffviewFileHistory` が走る (履歴ビュー)

**Step 3: コミット**

```bash
git add zsh/.zshrc
git commit -m "$(cat <<'EOF'
zsh エイリアス vd/vdh を Diffview コマンドに置換

CodeDiff の依存を完全に切る。

Created by snyt45 with Claude Code
EOF
)"
```

---

### Task 6: cheatsheet.md を更新

**Files:**
- Modify: `docs/cheatsheet.md` (lines 17-18, 295-329 周辺)

**Step 1: zsh エイリアス記述を更新 (line 17-18)**

変更前:
```markdown
| `vd` | nvim +CodeDiff (diffビュー付きで起動) |
| `vdh` | nvim +"CodeDiff history" (コミット履歴付きで起動) |
```

変更後:
```markdown
| `vd` | nvim +DiffviewOpen (diffビュー付きで起動) |
| `vdh` | nvim +DiffviewFileHistory (コミット履歴付きで起動) |
```

**Step 2: Neovim 内のレビューセクションを更新 (line 290-330 周辺)**

`### CodeDiff` 等のセクション見出しと内容を Diffview 仕様に更新。具体的な編集内容:

- セクション見出し `### CodeDiff` → `### Diffview / レビュー`
- コマンドパレットエントリ `[CodeDiff] ブランチとの差分` → `[Diffview] 全差分 (レビューモード時はbase...HEAD)` (および対応する keymap descriptions に合わせて更新)
- 「baseブランチを宣言すると、CodeDiff / `,gs` が同じbaseを参照するようになる」 → 「baseブランチを宣言すると、Diffview が `base...HEAD` を参照するようになる。`,gs` は通常の git status のまま」
- 「エクスプローラ内」表 (line 322-329): CodeDiff explorer のキー (`i`, `t`, `g?`, `gT`) は **削除** (Diffview の file panel は別キーバインド体系)。代わりに Diffview のよく使うキーを 1-2 個書く: `<leader>e` (file panel toggle) や `]f` / `[f` (次の/前のファイル) など — 必要なら `:h diffview-default-keybindings` 参照と書く

**Step 3: 変更を確認**

Run: `grep -ni "codediff" docs/cheatsheet.md`
Expected: 該当なし (空出力)

**Step 4: コミット**

```bash
git add docs/cheatsheet.md
git commit -m "$(cat <<'EOF'
cheatsheet を Diffview ベースに更新

CodeDiff / explorer 固有キーを削除し、Diffview / レビューワークフロー
の記述に置換。

Created by snyt45 with Claude Code
EOF
)"
```

---

### Task 7: 動作確認 + 総まとめ

**Step 1: クリーンな起動確認**

Run: `nvim` を起動してエラー通知が出ないことを確認
Expected: `:messages` で空、`:Lazy` で `loaded` 表示が並び、`codediff` が plugin list に存在しない

**Step 2: 主要キーマップの最終チェック**

| キー | 期待動作 |
|---|---|
| `<leader>gg` | DiffviewOpen (working tree) |
| `<leader>gf` | DiffviewOpen `-- <file>` |
| `<leader>gh` | DiffviewFileHistory |
| `<leader>gs` | snacks git_status |
| `<leader>gb` | gitsigns blame |
| `]c` / `[c` | gitsigns hunk nav |
| `:ReviewStart origin/main` | Diffview が `origin/main...HEAD --imply-local` で開く |
| `:ReviewEnd` | Diffview 閉じる + 通知 |

**Step 3: 設計書を再読して取りこぼし確認**

Run: `cat docs/plans/2026-04-27-nvim-pr-review-migration-design.md`
Expected: 「採用する解」「設計」項目すべて完了している

**Step 4: 最終コミット (もしドキュメント以外の修正が残っていれば)**

特になければスキップ。

---

## 完了基準

- `<leader>gg` / `<leader>gf` / `<leader>gh` が Diffview 経由で動作する
- `:ReviewStart` / `:ReviewEnd` が Diffview の起動/終了を伴う
- `<leader>gs` が常に snacks git_status を返す
- `:CodeDiff` 系コマンドが完全に未定義
- `vd` / `vdh` zsh エイリアスが Diffview を起動する
- cheatsheet に CodeDiff の記述が残っていない
- Neovim 起動時にエラー通知が出ない
