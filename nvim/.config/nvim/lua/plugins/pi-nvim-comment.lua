-- 環境固有: 提出プロンプトの指示文の後に付記する（walkthrough-commentsスキル連携）。
-- このプラグイン自体は walkthrough スキルの存在を知らない。ここが自分の環境における注入点。
local WALKTHROUGH_SUFFIX = [[After the review, record your answers as walkthrough threads per the walkthrough-comments skill: for comments marked "Reply to walkthrough thread", append to that step's thread in the referenced JSON; for new comments, generate a new walkthrough JSON under .walkthroughs/ in the project root. Report the saved path(s).]]

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
