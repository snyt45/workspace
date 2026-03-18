return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		telescope.setup({
			defaults = {
				layout_strategy = "vertical",
				layout_config = { height = 0.9, width = 0.9 },
				mappings = {
					i = { ["<Esc>"] = actions.close },
				},
			},
			pickers = {
				find_files = {
					hidden = true,
				},
			},
		})
		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "ファイル検索" })
		vim.keymap.set("n", "<leader>r", builtin.live_grep, { desc = "grep検索" })
		vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "バッファ一覧" })
		vim.keymap.set("n", "<leader>o", builtin.oldfiles, { desc = "最近のファイル" })
		vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "git status" })
	end,
}
