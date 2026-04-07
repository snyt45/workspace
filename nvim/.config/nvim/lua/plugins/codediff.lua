return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gg", "<cmd>CodeDiff<cr>", desc = "[CodeDiff] 差分表示" },
		{ "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "[CodeDiff] 履歴" },
	},
	opts = {
		explorer = {
			view_mode = "tree",
		},
	},
}
