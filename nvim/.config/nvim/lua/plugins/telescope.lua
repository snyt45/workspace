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
				layout_config = {
					height = 0.9,
					width = 0.9,
					prompt_position = "top",
					preview_height = 0.5,
				},
				sorting_strategy = "ascending",
				borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				prompt_prefix = "  ",
				selection_caret = " ",
				entry_prefix = "  ",
				results_title = false,
				mappings = {
					i = { ["<Esc>"] = actions.close },
				},
			},
			pickers = {
				find_files = {
					hidden = true,
				},
				live_grep = {
					additional_args = { "--hidden", "--glob", "!.git/", "--trim" },
				},
			},
		})
		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")

		local builtin = require("telescope.builtin")

		-- gitリポジトリ内ではgit_files、外ではfind_filesにフォールバック
		vim.keymap.set("n", "<leader><leader>", function()
			local ok = pcall(builtin.git_files, { show_untracked = true })
			if not ok then
				builtin.find_files()
			end
		end, { desc = "ファイル検索" })
		vim.keymap.set("n", "<leader>r", builtin.live_grep, { desc = "grep検索" })
		vim.keymap.set("n", "<leader>o", builtin.oldfiles, { desc = "最近のファイル" })
	end,
}
