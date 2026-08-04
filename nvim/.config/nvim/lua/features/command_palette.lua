local commands = {
	{
		name = "[Snacks] Issue一覧 (open)",
		cmd = "Snacks.picker.gh_issue()",
		execute = function()
			Snacks.picker.gh_issue()
		end,
	},
	{
		name = "[Snacks] Issue一覧 (all)",
		cmd = "Snacks.picker.gh_issue({state='all'})",
		execute = function()
			Snacks.picker.gh_issue({ state = "all" })
		end,
	},
	{
		name = "[Snacks] PR一覧 (open)",
		cmd = "Snacks.picker.gh_pr()",
		execute = function()
			Snacks.picker.gh_pr()
		end,
	},
	{
		name = "[Snacks] PR一覧 (all)",
		cmd = "Snacks.picker.gh_pr({state='all'})",
		execute = function()
			Snacks.picker.gh_pr({ state = "all" })
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
	{
		name = "[GitSigns] 比較ベース変更",
		cmd = "gitsigns.change_base(base)",
		execute = function()
			vim.ui.input({ prompt = "Compare base: ", default = "origin/main" }, function(base)
				if not base or base == "" then return end
				local gs = package.loaded.gitsigns
				if gs then
					gs.change_base(base, true)
					vim.notify("GitSigns base: " .. base)
				end
			end)
		end,
	},
	{
		name = "[GitSigns] 比較ベースをリセット",
		cmd = "gitsigns.change_base(nil)",
		execute = function()
			local gs = package.loaded.gitsigns
			if gs then
				gs.change_base(nil, true)
				vim.notify("GitSigns base: reset")
			end
		end,
	},
	{
		name = "[Diffview] ブランチとの差分",
		cmd = "DiffviewOpen base...HEAD --imply-local",
		execute = function()
			vim.ui.input({ prompt = "Compare base: ", default = "origin/main" }, function(base)
				if not base or base == "" then return end
				vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local")
			end)
		end,
	},
}

table.sort(commands, function(a, b) return a.name < b.name end)

local M = {}

function M.open()
	local items = {}
	for _, c in ipairs(commands) do
		table.insert(items, {
			text = c.name,
			execute = c.execute,
			preview = { text = ":" .. c.cmd, ft = "vim" },
		})
	end

	Snacks.picker.pick({
		title = "Command Palette",
		items = items,
		preview = "preview",
		format = "text",
		confirm = function(picker, item)
			picker:close()
			item.execute()
		end,
	})
end

return M
