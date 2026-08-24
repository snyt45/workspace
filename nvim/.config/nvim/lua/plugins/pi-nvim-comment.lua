-- 環境固有: 提出プロンプトの指示文の後に付記する（walkthrough-commentsスキル連携）。
-- このプラグイン自体は walkthrough スキルの存在を知らない。ここが自分の環境における注入点。
local WALKTHROUGH_SUFFIX = [[After the review, generate a walkthrough JSON of your answers per the walkthrough-comments skill (save it under .walkthroughs/ in the project root) and report the saved path.]]

return {
	-- 自作ローカルプラグイン。公開API・キーマップ・設定は pi-nvim-comment/README.md 参照
	dir = vim.fn.stdpath("config") .. "/pi-nvim-comment",
	name = "pi-nvim-comment",
	main = "pi-nvim-comment",
	dependencies = { "carderne/pi-nvim", "walkthrough.nvim" },
	event = "VeryLazy",
	opts = {
		prompt_suffix = WALKTHROUGH_SUFFIX,
	},
}
