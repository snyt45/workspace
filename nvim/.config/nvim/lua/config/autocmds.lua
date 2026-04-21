local autocmd = vim.api.nvim_create_autocmd

-- ペイン切り替え時にファイル変更を検知してリロード
autocmd({ "BufEnter", "CursorHold", "CursorMoved", "FocusGained" }, {
	command = "checktime",
})

