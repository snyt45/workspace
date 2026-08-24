return {
	-- 自作ローカルプラグイン。公開API・スキーマ・設定は walkthrough.nvim/README.md 参照
	dir = vim.fn.stdpath("config") .. "/walkthrough.nvim",
	name = "walkthrough.nvim",
	main = "walkthrough",
	event = "VeryLazy",
	opts = {},
}
