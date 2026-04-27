return {
	"rachartier/tiny-cmdline.nvim",
	lazy = false,
	priority = 1000,
	init = function()
		vim.o.cmdheight = 0
		pcall(function()
			require("vim._core.ui2").enable({})
		end)
	end,
	opts = {
		native_types = {},
	},
}
