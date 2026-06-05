return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = "Obsidian",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	init = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function()
				vim.opt_local.conceallevel = 2
			end,
		})
	end,
	opts = {
		legacy_commands = false,

		workspaces = {
			{ name = "claude-obsidian", path = "~/work/claude-obsidian" },
		},

		picker = {
			name = "snacks.pick",
		},

		daily_notes = {
			folder = "daily",
			date_format = "%Y-%m-%d",
			template = "daily.md",
		},

		templates = {
			folder = "_templates",
		},

		-- wikilink で新規ノートを作るときのファイル名をリンクのタイトルそのものにする
		note_id_func = function(title)
			if title ~= nil then
				return title:gsub('[\\/:%*%?"<>|]', "")
			else
				return tostring(os.time())
			end
		end,
	},
	keys = {
		{ "<leader>ot", "<cmd>Obsidian today<cr>", desc = "[Obsidian] 今日のdaily note" },
		{ "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "[Obsidian] 昨日のdaily note" },
		{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "[Obsidian] 新規ノート" },
		{ "<leader>or", "<cmd>Obsidian search<cr>", desc = "[Obsidian] 全文検索" },
		{ "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "[Obsidian] ノート切替" },
		{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "[Obsidian] バックリンク" },
	},
}
