local autocmd = vim.api.nvim_create_autocmd

-- ペイン切り替え時にファイル変更を検知してリロード
autocmd({ "BufEnter", "CursorHold", "CursorMoved", "FocusGained" }, {
	command = "checktime",
})

-- ターミナルを開いたら自動でターミナルモードに入る
autocmd("TermOpen", {
	command = "startinsert",
})

-- markdown の fold は見出し（section）単位だけにする。
-- 同梱の folds.scm は list_item / code_block も畳むため、section のみに上書きする。
vim.treesitter.query.set("markdown", "folds", "(section) @fold")

-- markdown は見出し単位で折りたたむ（同梱 treesitter パーサ利用、nvim-treesitter 不要）
autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.treesitter.start() -- 同梱 markdown パーサを起動
		vim.opt_local.foldmethod = "expr"
		vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.opt_local.foldlevel = 99 -- 開いた時は畳まない
	end,
})

