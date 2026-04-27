return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = { "MunifTanjim/nui.nvim" },
	opts = {
		messages = {
			view = "mini",
			view_error = "mini",
			view_warn = "mini",
		},
		notify = {
			view = "mini",
		},
		lsp = {
			progress = {
				view = "mini",
			},
		},
		cmdline = { enabled = false },
		popupmenu = { enabled = false },
	},
}
