return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = true,
			custom_highlights = function(colors)
				return {
					LineNr = { fg = colors.overlay0 },
					CursorLineNr = { fg = colors.lavender },
				}
			end,
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
