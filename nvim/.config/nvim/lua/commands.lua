local commands = {
	{
		name = "[GrugFar] カーソル下の単語で検索・置換",
		cmd = "GrugFar (cword)",
		execute = function()
			require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
		end,
	},
	{
		name = "[GrugFar] 現在のディレクトリ内で検索・置換",
		cmd = "GrugFar (dir)",
		execute = function()
			require("grug-far").open({ prefills = { paths = vim.fn.expand("%:p:h") } })
		end,
	},
	{
		name = "[Conform] 自動フォーマットを無効化",
		cmd = "ConformDisable",
		execute = function()
			vim.cmd("ConformDisable")
		end,
	},
	{
		name = "[Conform] 自動フォーマットを有効化",
		cmd = "ConformEnable",
		execute = function()
			vim.cmd("ConformEnable")
		end,
	},
	{
		name = "[Octo] Issue一覧",
		cmd = "Octo issue list",
		execute = function()
			vim.cmd("Octo issue list")
		end,
	},
	{
		name = "[Octo] PRにコメント追加",
		cmd = "Octo comment add",
		execute = function()
			vim.cmd("Octo comment add")
		end,
	},
	{
		name = "[Octo] PRのdiff表示",
		cmd = "Octo pr diff",
		execute = function()
			vim.cmd("Octo pr diff")
		end,
	},
	{
		name = "[Octo] PR一覧",
		cmd = "Octo pr list",
		execute = function()
			vim.cmd("Octo pr list")
		end,
	},
	{
		name = "[Octo] PRをマージ",
		cmd = "Octo pr merge squash",
		execute = function()
			vim.cmd("Octo pr merge squash")
		end,
	},
	{
		name = "[Octo] PRレビュー再開",
		cmd = "Octo review resume",
		execute = function()
			vim.cmd("Octo review resume")
		end,
	},
	{
		name = "[Octo] PRレビュー開始",
		cmd = "Octo review start",
		execute = function()
			vim.cmd("Octo review start")
		end,
	},
	{
		name = "[Review] レビューモード開始",
		cmd = "ReviewStart [base]",
		execute = function()
			vim.cmd("ReviewStart")
		end,
	},
	{
		name = "[Review] レビューモード終了",
		cmd = "ReviewEnd",
		execute = function()
			vim.cmd("ReviewEnd")
		end,
	},
}

table.sort(commands, function(a, b) return a.name < b.name end)

vim.keymap.set("n", "<leader>p", function()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	pickers
	    .new({
		    layout_strategy = "horizontal",
		    layout_config = { width = 0.6, height = 0.4, preview_width = 0.4 },
	    }, {
		    prompt_title = "Command Palette",
		    finder = finders.new_table({
			    results = commands,
			    entry_maker = function(entry)
				    return {
					    value = entry,
					    display = entry.name,
					    ordinal = entry.name,
				    }
			    end,
		    }),
		    sorter = conf.generic_sorter({}),
		    previewer = previewers.new_buffer_previewer({
			    title = "Command",
			    define_preview = function(self, entry)
				    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
					    ":" .. entry.value.cmd,
				    })
			    end,
		    }),
		    attach_mappings = function(prompt_bufnr)
			    actions.select_default:replace(function()
				    local selection = action_state.get_selected_entry()
				    actions.close(prompt_bufnr)
				    selection.value.execute()
			    end)
			    return true
		    end,
	    })
	    :find()
end, { desc = "[CommandPalette] コマンドパレット" })
