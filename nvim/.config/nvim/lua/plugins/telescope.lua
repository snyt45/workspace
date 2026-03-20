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
					layout_strategy = "horizontal",
					additional_args = { "--hidden", "--glob", "!.git/", "--trim" },
				},
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

		-- gitリポジトリ内ではgit_files、外ではfind_filesにフォールバック
		vim.keymap.set("n", "<leader><leader>", function()
			local ok = pcall(builtin.git_files, { show_untracked = true })
			if not ok then
				builtin.find_files()
			end
		end, { desc = "ファイル検索" })
		vim.keymap.set("n", "<leader>r", builtin.live_grep, { desc = "grep検索" })
		vim.keymap.set("n", "<leader>o", builtin.oldfiles, { desc = "最近のファイル" })
		vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "バッファ一覧" })
		vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
	end,
}
