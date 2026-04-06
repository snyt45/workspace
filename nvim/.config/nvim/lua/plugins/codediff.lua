return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gg", "<cmd>CodeDiff<cr>", desc = "CodeDiff" },
		{ "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "CodeDiff履歴" },
	},
	opts = {
		explorer = {
			view_mode = "tree",
		},
		keymaps = {
			view = {
				close_on_open_in_prev_tab = true,
			},
		},
	},
}
