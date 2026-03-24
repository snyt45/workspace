return {
	"rcarriga/nvim-notify",
	config = function()
		local notify = require("notify")
		notify.setup({
			timeout = 1500,
			top_down = true,
			background_colour = "#000000",
		})
		vim.notify = notify
	end,
}
