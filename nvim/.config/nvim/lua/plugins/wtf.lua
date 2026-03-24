return {
	"piersolenski/wtf.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = {
		provider = "anthropic",
		language = "japanese",
		providers = {
			anthropic = {
				api_key = function()
					if not _G._wtf_anthropic_key then
						_G._wtf_anthropic_key = vim.fn.system("op read 'op://Development/anthropic/credential'"):gsub("%s+$", "")
					end
					return _G._wtf_anthropic_key
				end,
			},
		},
	},
	keys = {
		{
			"<leader>wd",
			function()
				require("wtf").diagnose()
			end,
			desc = "diagnosticをAIで解説",
		},
		{
			"<leader>wf",
			mode = { "n", "x" },
			function()
				require("wtf").fix()
			end,
			desc = "diagnosticをAIで修正提案",
		},
		{
			"<leader>ws",
			function()
				require("wtf").search()
			end,
			desc = "diagnosticをWeb検索",
		},
		{
			"<leader>wh",
			function()
				require("wtf").history()
			end,
			desc = "AIチャット履歴をquickfixに表示",
		},
	},
}
