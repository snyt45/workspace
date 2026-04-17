return {
	"folke/snacks.nvim",
	event = "VeryLazy",
	opts = {
		gh = {},
		picker = {
			sources = {
				gh_issue = {},
				gh_pr = {},
				scratch = {
					actions = {
						scratch_delete = function(picker, item)
							local current = item.file
							local bufnr = vim.fn.bufnr(current)
							if bufnr ~= -1 then
								pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
							end
							os.remove(current)
							os.remove(current .. ".meta")
							picker:refresh()
						end,
					},
				},
			},
		},
		scratch = {
			ft = "markdown",
			win = {
				position = "right",
				width = 0.4,
				border = "none",
			},
		},
	},
	keys = {
		{
			"<leader>n",
			function()
				local layout = vim.fn.winrestcmd()
				Snacks.scratch()
				local scratch_win = vim.api.nvim_get_current_win()
				vim.api.nvim_create_autocmd("WinClosed", {
					pattern = tostring(scratch_win),
					once = true,
					callback = function()
						vim.schedule(function()
							pcall(vim.cmd, layout)
						end)
					end,
				})
			end,
			desc = "[Snacks] スクラッチメモ (cwd+branch単位)"
		},
		{ "<leader>N", function() Snacks.scratch.select() end, desc = "[Snacks] スクラッチ一覧" },
	},
}
