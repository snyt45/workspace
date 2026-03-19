return {
	"pwntester/octo.nvim",
	cmd = "Octo",
	event = { { event = "BufReadCmd", pattern = "octo://*" } },
	keys = {
		{ "<leader>gp", "<cmd>Octo pr list<cr>", desc = "GitHub PR一覧" },
		{ "<leader>gi", "<cmd>Octo issue list<cr>", desc = "GitHub Issue一覧" },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		picker = "telescope",
		enable_builtin = true,
		default_merge_method = "squash",
		default_delete_branch = true,
		pull_requests = {
			order_by = { field = "UPDATED_AT", direction = "DESC" },
		},
	},
}
