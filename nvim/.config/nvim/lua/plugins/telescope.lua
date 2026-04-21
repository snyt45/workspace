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
				git_status = {
					layout_strategy = "horizontal",
				},
			},
		})
		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")
	end,
}
