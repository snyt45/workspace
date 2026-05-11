return {
	"folke/snacks.nvim",
	event = "VeryLazy",
	opts = {
		gh = {},
		gitbrowse = {},
		picker = {
			sources = {
				gh_issue = {},
				gh_pr = {},
				explorer = {
					hidden = true,
					ignored = true,
				},
			},
		},
	},
	keys = {
		{ "<leader>lz", function() Snacks.lazygit({ win = { keys = { term_normal = false } } }) end, desc = "[Snacks] Lazygit" },
		{ "<leader>o", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "[Snacks] 最近のファイル (cwd)" },
		{ "<leader>b", function() Snacks.picker.buffers() end, desc = "[Snacks] バッファ一覧" },
		{ "<leader>gs", function() Snacks.picker.git_status({ layout = { preset = "ivy" } }) end, desc = "[Snacks] git status" },
		{ "<leader>e", function() Snacks.explorer.open() end, desc = "[Snacks] ファイルエクスプローラー" },
		{ "<leader>go", function() Snacks.gitbrowse({ what = "permalink" }) end, mode = { "n", "v" }, desc = "[Snacks] GitHub で開く (permalink)" },
	},
}
