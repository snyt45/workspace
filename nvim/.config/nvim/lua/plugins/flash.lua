return {
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {},
	keys = {
		{ "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "[Flash] ジャンプ" },
		{ "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "[Flash] Treesitterノード選択" },
		{ "r",     mode = "o",               function() require("flash").remote() end,            desc = "[Flash] リモートジャンプ (operator)" },
		{ "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "[Flash] Treesitter検索" },
		{ "<c-s>", mode = "c",               function() require("flash").toggle() end,            desc = "[Flash] /?検索時のトグル" },
	},
}
