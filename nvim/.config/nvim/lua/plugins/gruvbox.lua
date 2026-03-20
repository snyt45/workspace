return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		require("gruvbox").setup({
			transparent_mode = true,
			overrides = {
				NormalFloat = { bg = "#3c3836" },
				FloatBorder = { fg = "#a89984", bg = "#3c3836" },

				-- Diff: gruvboxパレットに合わせた背景色
				DiffAdd = { bg = "#3d4220" },
				DiffDelete = { bg = "#442828" },
				DiffChange = { bg = "#3b3420" },
				DiffText = { bg = "#514a2a" },

				-- Telescope git status: ファイル名の色を見やすく
				TelescopeResultsDiffAdd = { fg = "#b8bb26" },
				TelescopeResultsDiffChange = { fg = "#fabd2f" },
				TelescopeResultsDiffDelete = { fg = "#fb4934" },
				TelescopeResultsDiffUntracked = { fg = "#8ec07c" },
			},
		})
		vim.cmd.colorscheme("gruvbox")
	end,
}
