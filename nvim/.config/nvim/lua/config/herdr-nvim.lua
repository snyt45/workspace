-- herdr-nvim（herdr-app のサイドバー nvim）に合わせる設定。herdr-nvim をやめたら、このファイルと init.lua の require を消す
-- herdr-nvim が起動した nvim だけに効く
if vim.env.HERDR_NVIM_HOST ~= "app" then
	return
end

-- 起動時に herdr-nvim が :Lexplore を開くのを止める（エクスプローラーは Snacks）
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- headless で起動して後から UI がつながるので、つながった時に ui2 を有効にし直さないと cmdline（: や ,ac の入力欄）が出ない
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		pcall(function()
			require("vim._core.ui2").enable({})
		end)
	end,
})

-- herdr-nvim のキーは説明が "herdr-nvim: …" でキーマップの一覧（g?）に出ないので、[Herdr] を付けて割り当て直す
-- herdr-nvim は VimEnter で読み込まれる（lazy.nvim が runtimepath を入れ直すため）ので、その後に行う
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = vim.schedule_wrap(function()
		local ok, herdr = pcall(require, "herdr-nvim")
		if not ok then
			return
		end
		-- 後で setup() が呼び直されても、herdr-nvim の割り当てに戻さない
		herdr.config.keymaps = false
		local map = vim.keymap.set
		map("n", "<leader>ac", herdr.comment_line, { desc = "[Herdr] 行にコメント" })
		map("x", "<leader>ac", herdr.comment_selection, { desc = "[Herdr] 選択範囲にコメント" })
		map("n", "<leader>al", herdr.list_comments, { desc = "[Herdr] コメント一覧" })
		map("n", "<leader>as", function() herdr.send_all({ submit = false }) end, { desc = "[Herdr] コメントを入力欄に貼る" })
		map("n", "<leader>aS", function() herdr.send_all({ submit = true }) end, { desc = "[Herdr] コメントを送る" })
		map("n", "<leader>ai", herdr.ref_line, { desc = "[Herdr] 行の参照を入力欄に入れる" })
		map("x", "<leader>ai", herdr.ref_selection, { desc = "[Herdr] 選択範囲の参照を入力欄に入れる" })
	end),
})
