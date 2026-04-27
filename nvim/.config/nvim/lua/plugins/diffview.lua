return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
	keys = {
		{ "<leader>gg", function() require("features.review").code_diff() end, desc = "[Diffview] 全差分 (レビューモード時はbase...HEAD)" },
		{ "<leader>gf", function() require("features.review").code_diff_file() end, desc = "[Diffview] 現バッファの単一ファイル差分 (レビューモード時はbase...HEAD)" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "[Diffview] 履歴" },
	},
	opts = {},
}
