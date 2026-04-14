-- ==========================================================================
-- Bootstrap: lazy.nvim (プラグインマネージャ)
-- 初回起動時に自動でダウンロードされる
-- ==========================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 基本設定
-- ==========================================================================

-- リーダーキー
vim.g.mapleader = ","

-- 表示
vim.opt.cursorline = true    -- カーソル行をハイライト
vim.opt.termguicolors = true -- 24bitカラー

-- 検索
vim.opt.incsearch = true  -- インクリメンタル検索
vim.opt.hlsearch = true   -- 検索結果ハイライト
vim.opt.ignorecase = true -- 大文字小文字無視
vim.opt.smartcase = true  -- 大文字を含むときは区別

-- マウス
vim.opt.mouse = "a"

-- クリップボード (macOSのシステムクリップボードと共有)
vim.opt.clipboard = "unnamedplus"

-- ファイル管理
vim.opt.autoread = true -- 外部変更を自動読み込み

-- ペイン切り替え時にファイル変更を検知してリロード
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorMoved", "FocusGained" }, {
	command = "checktime",
})

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true -- undoを永続化

-- 折りたたみ
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99 -- デフォルトで全て展開

-- 行番号
vim.opt.number = true

-- ウィンドウ分割方向
vim.opt.splitright = true -- 縦分割は右に開く
vim.opt.splitbelow = true -- 横分割は下に開く

-- ==========================================================================
-- キーマップ (プラグイン非依存)
-- ==========================================================================

local map = vim.keymap.set

-- レコーディング無効化
map("n", "q", "<Nop>")

-- F1ヘルプ無効化
map({ "n", "i" }, "<F1>", "<Nop>")

-- 検索ハイライト解除
map("n", "<Esc><Esc>", ":nohlsearch<CR>")

-- インサートモード: Karabiner英数+a/eに対応
map("i", "<C-a>", "<Home>")
map("i", "<C-e>", "<End>")

-- C-h/j/k/l でウィンドウ間を直接移動（C-w 不要）
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- バッファを閉じる
map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "[Buffer] バッファを閉じる" })

-- quickfix操作
map("n", "]q", "<cmd>cnext<cr>", { desc = "[Quickfix] 次のquickfix" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "[Quickfix] 前のquickfix" })
map("n", "<leader>q", function()
	local wins = vim.fn.getqflist({ winid = 0 }).winid
	if wins ~= 0 then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end, { desc = "[Quickfix] quickfixトグル" })
map("n", "<leader>Q", "<cmd>cexpr []<cr>", { desc = "[Quickfix] quickfixクリア" })

-- ターミナルを下に分割して開く
map("n", "<leader>t", "<cmd>split | terminal<cr>", { desc = "[Terminal] ターミナル" })

-- ターミナルモードからノーマルモードに戻る
map("t", "jj", "<C-\\><C-n>")

-- Markdownプレビュー (mo) - ブラウザ自動起動
map("n", "<leader>m", function()
	local file = vim.fn.shellescape(vim.fn.expand("%"))
	local output = vim.fn.system("mo " .. file .. " 2>&1")
	local url = output:match("(http://[^%s]+)")
	if url then
		vim.fn.jobstart({ "open", url })
	end
end, { desc = "[General] Markdownプレビュー" })

-- ファイルパスコピー
map("n", "<leader>c", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "[General] ファイルパスコピー" })

-- ファイルパス + 選択コードをマークダウン形式でコピー
map("v", "<leader>cc", function()
	local path = vim.fn.expand("%:.")
	vim.cmd('normal! "vy')
	local selected_text = vim.fn.getreg("v")
	local formatted = "@" .. path .. "\n\n```\n" .. selected_text .. "\n```"
	vim.fn.setreg("+", formatted)
	vim.notify("Copied: @" .. path .. " with selected text", vim.log.levels.INFO)
end, { desc = "[General] ファイルパス+コードコピー" })

-- ==========================================================================
-- プラグイン (lua/plugins/ 配下のファイルを自動読み込み)
-- ==========================================================================

require("lazy").setup("plugins")

-- ==========================================================================
-- LSP設定 (lua/lsp.lua)
-- ==========================================================================

require("lsp")
require("commands")
require("keymaps")
require("review")
