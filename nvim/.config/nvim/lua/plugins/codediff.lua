return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gg", function() require("features.review").code_diff() end, desc = "[CodeDiff] 差分表示 (レビューモード時はbase差分)" },
		{ "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "[CodeDiff] 履歴" },
	},
	opts = {
		explorer = {
			view_mode = "tree",
		},
	},
}
