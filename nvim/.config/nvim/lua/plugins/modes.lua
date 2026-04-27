return {
	"mvllow/modes.nvim",
	event = "VeryLazy",
	opts = {
		line_opacity = 0.5,
		set_cursorline = true,
		ignore = {
			"NvimTree",
			"lspinfo",
			"packer",
			"checkhealth",
			"help",
			"man",
			"TelescopePrompt",
			"TelescopeResults",
			"!minifiles",
			"!neo-tree",
		},
	},
}
