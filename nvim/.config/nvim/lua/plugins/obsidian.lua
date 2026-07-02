return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = "Obsidian",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	init = function()
		local vault = vim.fn.expand("~/work/claude-obsidian")

		local function map_checkbox_toggle(bufnr)
			vim.keymap.set("n", "<CR>", function()
				local line = vim.api.nvim_get_current_line()
				local is_checkbox = line:match("^%s*[-*+]%s+%[.?%]") or
				    line:match("^%s*%d+[.)]%s+%[.?%]")
				if is_checkbox then
					vim.cmd("Obsidian toggle_checkbox")
				else
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true),
						"n", false)
				end
			end, { buffer = bufnr, desc = "[Obsidian] チェックボックス切替 / 通常Enter" })
			vim.keymap.set("v", "<CR>", "<cmd>Obsidian toggle_checkbox<cr>", {
				buffer = bufnr,
				desc = "[Obsidian] チェックボックス切替（選択行）",
			})
		end

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(ev)
				if not vim.startswith(vim.api.nvim_buf_get_name(ev.buf), vault) then
					return
				end
				map_checkbox_toggle(ev.buf)
			end,
		})
	end,
	opts = {
		legacy_commands = false,

		-- 描画は render-markdown.nvim に一本化（二重描画を防ぐ）
		ui = { enable = false },

		frontmatter = { enabled = false },

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
		{ "<leader>nt", "<cmd>Obsidian today<cr>", desc = "[Obsidian] 今日のdaily note" },
		{ "<leader>ny", "<cmd>Obsidian yesterday<cr>", desc = "[Obsidian] 昨日のdaily note" },
		{ "<leader>nn", "<cmd>Obsidian new<cr>", desc = "[Obsidian] 新規ノート" },
		{ "<leader>nr", "<cmd>Obsidian search<cr>", desc = "[Obsidian] 全文検索" },
		{ "<leader>nq", "<cmd>Obsidian quick_switch<cr>", desc = "[Obsidian] ノート切替" },
		{ "<leader>nb", "<cmd>Obsidian backlinks<cr>", desc = "[Obsidian] バックリンク" },
		{ "<leader>nT", "<cmd>Obsidian tags<cr>", desc = "[Obsidian] タグで探す" },
		{ "<leader>no", "<cmd>Obsidian open<cr>", desc = "[Obsidian] アプリで開く" },
	},
}
