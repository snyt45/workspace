return {
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {},
	keys = {
		{ "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,   desc = "[Flash] ジャンプ" },
		{ "r",     mode = "o",               function() require("flash").remote() end, desc = "[Flash] リモートジャンプ (operator)" },
		{ "<c-s>", mode = "c",               function() require("flash").toggle() end, desc = "[Flash] /?検索時のトグル" },
	},
}
