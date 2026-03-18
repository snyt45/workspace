return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		require("gruvbox").setup({
			transparent_mode = true,
			overrides = {
				NormalFloat = { bg = "#3c3836" },
				FloatBorder = { fg = "#a89984", bg = "#3c3836" },
			},
		})
		vim.cmd.colorscheme("gruvbox")
	end,
}
