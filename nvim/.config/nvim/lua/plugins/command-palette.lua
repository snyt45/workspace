local commands = {
	{
		name = "[GitSigns] 現在のファイルをベースブランチと比較",
		cmd = "Gitsigns diffthis <branch>",
		execute = function()
			vim.ui.input({ prompt = "Base branch: ", default = "origin/main" }, function(branch)
				if branch then
					vim.cmd("Gitsigns diffthis " .. branch)
				end
			end)
		end,
	},
	{
		name = "[CodeDiff] 全変更ファイルをベースブランチと比較",
		cmd = "CodeDiff <branch>",
		execute = function()
			vim.ui.input({ prompt = "Base branch: ", default = "origin/main" }, function(branch)
				if branch then
					vim.cmd("CodeDiff " .. branch)
				end
			end)
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
		name = "[Octo] PRにコメント追加",
		cmd = "Octo comment add",
		execute = function()
			vim.cmd("Octo comment add")
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
		name = "[Octo] PRのdiff表示",
		cmd = "Octo pr diff",
		execute = function()
			vim.cmd("Octo pr diff")
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
		name = "[Octo] Issue一覧",
		cmd = "Octo issue list",
		execute = function()
			vim.cmd("Octo issue list")
		end,
	},
	{
		name = "[GrugFar] プロジェクト全体で検索・置換",
		cmd = "GrugFar",
		execute = function()
			vim.cmd("GrugFar")
		end,
	},
	{
		name = "[GrugFar] カーソル下の単語で検索",
		cmd = "GrugFar { search = <cword> }",
		execute = function()
			require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
		end,
	},
	{
		name = "[GrugFar] 現在のディレクトリ内で検索・置換",
		cmd = "GrugFar { paths = <dir> }",
		execute = function()
			require("grug-far").open({ prefills = { paths = vim.fn.expand("%:p:h") } })
		end,
	},
	{
		name = "[GrugFar] quickfixのファイル内で検索・置換",
		cmd = "GrugFar { search = <last_search>, paths = <qflist> }",
		execute = function()
			require("grug-far").open({
				prefills = {
					search = vim.g.last_lsp_search or "",
					paths = "<qflist>",
				},
			})
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
		name = "[Nav] quickfixをクリア",
		cmd = "cexpr []",
		execute = function()
			vim.cmd("cexpr []")
		end,
	},
}

local function open_keymaps()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local themes = require("telescope.themes")

	local results = {}
	local function collect(maps)
		for _, map in ipairs(maps) do
			if map.desc and map.desc:match("^%[") then
				table.insert(results, {
					lhs = map.lhs,
					desc = map.desc,
					display = map.lhs .. "  " .. map.desc,
					ordinal = map.desc .. " " .. map.lhs,
				})
			end
		end
	end

	collect(vim.api.nvim_get_keymap("n"))
	collect(vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "n"))

	table.sort(results, function(a, b)
		return a.ordinal < b.ordinal
	end)

	pickers
		.new(themes.get_dropdown({ previewer = false }), {
			prompt_title = "Keymaps",
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.ordinal,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local keys = vim.api.nvim_replace_termcodes(selection.value.lhs, true, false, true)
					vim.api.nvim_feedkeys(keys, "m", false)
				end)
				return true
			end,
		})
		:find()
end

return {
	"command-palette",
	virtual = true,
	config = function()
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

		vim.keymap.set("n", "<leader>?", open_keymaps, { desc = "[CommandPalette] キーマップ一覧" })
	end,
}
