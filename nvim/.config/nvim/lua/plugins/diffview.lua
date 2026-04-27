return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
	keys = {
		{ "<leader>gg", function() require("features.review").code_diff() end, desc = "[Diffview] 全差分 (レビューモード時はbase...HEAD)" },
		{ "<leader>gf", function() require("features.review").code_diff_file() end, desc = "[Diffview] 現バッファの単一ファイル差分 (レビューモード時はbase...HEAD)" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "[Diffview] 履歴" },
	},
	opts = {
		keymaps = {
			view = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
		},
	},
}
