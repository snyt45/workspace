return {
	"mvllow/modes.nvim",
	event = "VeryLazy",
	opts = {
		line_opacity = 0.5,
		set_cursorline = true,
		ignore = {
			"lspinfo",
			"checkhealth",
			"help",
			"man",
			"!snacks_picker_list",
			"!snacks_picker_input",
		},
	},
}
