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
