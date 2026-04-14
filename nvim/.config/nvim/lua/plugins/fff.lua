return {
	"dmtrKovalenko/fff.nvim",
	build = function()
		require("fff.download").download_or_build_binary()
	end,
	lazy = false,
	opts = {},
	keys = {
		{ "<leader><leader>", function() require("fff").find_files() end, desc = "[FFF] ファイル検索" },
		{ "<leader>r", function() require("fff").live_grep() end, desc = "[FFF] grep検索" },
		{ "<leader>rw", function() require("fff").live_grep({ query = vim.fn.expand("<cword>") }) end, desc = "[FFF] カーソル下の単語でgrep" },
	},
}
