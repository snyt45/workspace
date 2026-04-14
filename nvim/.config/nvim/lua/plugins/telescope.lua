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
					vertical = {
						preview_height = 0.5,
					},
				},
				sorting_strategy = "ascending",
				borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				prompt_prefix = "  ",
				selection_caret = "  ",
				entry_prefix = "  ",
				results_title = false,
				mappings = {
					i = { ["<Esc>"] = actions.close },
				},
			},
			pickers = {
				oldfiles = {
					layout_strategy = "horizontal",
					cwd_only = true,
				},
				buffers = {
					theme = "dropdown",
					previewer = false,
					sort_lastused = true,
					sort_mru = true,
					mappings = {
						i = {
							["<C-d>"] = actions.delete_buffer,
						},
					},
				},
				git_status = {
					layout_strategy = "horizontal",
				},
			},
		})
		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>o", builtin.oldfiles, { desc = "[Telescope] 最近のファイル" })
		vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "[Telescope] バッファ一覧" })
		vim.keymap.set("n", "<leader>gf", function() require("review").files_changed() end,
			{ desc = "[Telescope] 変更ファイル一覧 (レビューモード時はbase差分)" })
	end,
}
