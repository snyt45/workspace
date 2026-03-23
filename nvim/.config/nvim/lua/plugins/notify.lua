return {
	"rcarriga/nvim-notify",
	config = function()
		local notify = require("notify")
		notify.setup({
			timeout = 1500,
			top_down = true,
		})
		vim.notify = notify
	end,
}
