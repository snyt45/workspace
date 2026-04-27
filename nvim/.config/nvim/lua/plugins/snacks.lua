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
				backdrop = false,
				on_win = function(self)
					vim.wo[self.win].winblend = 30
				end,
			},
		},
	},
	keys = {
		{ "<leader>n",  function() Snacks.scratch() end,                               desc = "[Snacks] スクラッチメモ (cwd+branch単位)" },
		{ "<leader>N",  function() Snacks.scratch.select() end,                        desc = "[Snacks] スクラッチ一覧" },
		{ "<leader>lz", function() Snacks.lazygit({ win = { keys = { term_normal = false } } }) end, desc = "[Snacks] Lazygit" },
		{ "<leader>o",  function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "[Snacks] 最近のファイル (cwd)" },
		{ "<leader>b",  function() Snacks.picker.buffers() end,                        desc = "[Snacks] バッファ一覧" },
		{ "<leader>gs", function() Snacks.picker.git_status({ layout = { preset = "ivy" } }) end, desc = "[Snacks] git status" },
	},
}
