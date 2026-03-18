return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		local wk = require("which-key")
		wk.setup({
			preset = "modern",
			plugins = {
				marks = false,
				registers = false,
				presets = {
					operators = false,
					motions = false,
					text_objects = false,
					windows = false,
					nav = false,
					z = false,
					g = false,
				},
			},
		})
		wk.add({
			{ "<leader>g", group = "Git" },
			{ "gh", group = "Hunk" },
		})
	end,
}
