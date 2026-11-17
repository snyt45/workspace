return {
	"rachartier/tiny-cmdline.nvim",
	lazy = false,
	priority = 1000,
	init = function()
		vim.o.cmdheight = 0
		pcall(function()
			-- メッセージは右下の一時ウィンドウに出す（4秒で消える。g< で pager に開いて読める）
			require("vim._core.ui2").enable({ msg = { target = "msg" } })
		end)
	end,
	opts = {
		native_types = {},
	},
}
