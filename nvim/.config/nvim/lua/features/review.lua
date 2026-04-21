-- ==========================================================================
-- レビューモード
-- vim.g.review_base を中心に、gitsigns/CodeDiff/snacks.picker が同じbaseを参照する
-- ==========================================================================

local M = {}

local function apply_base(base)
	vim.g.review_base = base
	local gs = package.loaded.gitsigns
	if gs then
		gs.change_base(base, true)
	end
end

local function start_with(base)
	apply_base(base)
	vim.notify("Review: " .. base)
	vim.cmd("CodeDiff " .. base .. "...HEAD")
end

-- "origin/foo" のような remote ref を local branch 名に変換（detached HEAD 回避のため）
local function to_local_branch(branch)
	local remotes = vim.fn.systemlist("git remote")
	for _, remote in ipairs(remotes) do
		local prefix = remote .. "/"
		if branch:sub(1, #prefix) == prefix then
			return branch:sub(#prefix + 1)
		end
	end
	return branch
end

vim.api.nvim_create_user_command("ReviewStart", function(opts)
	if opts.args and opts.args ~= "" then
		start_with(opts.args)
		return
	end
	local builtin = require("telescope.builtin")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	builtin.git_branches({
		attach_mappings = function(_, _)
			actions.select_default:replace(function(bufnr)
				local selection = action_state.get_selected_entry()
				actions.close(bufnr)
				if not selection or not selection.value then return end
				local local_name = to_local_branch(selection.value)
				local result = vim.system({ "git", "switch", local_name }):wait()
				if result.code ~= 0 then
					vim.notify("switch failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
					return
				end
				vim.notify("Switched to: " .. local_name)
				vim.ui.input({ prompt = "Compare base: ", default = "origin/main" }, function(base)
					if not base or base == "" then return end
					start_with(base)
				end)
			end)
			return true
		end,
	})
end, { nargs = "?", desc = "[Review] レビューモード開始" })

vim.api.nvim_create_user_command("ReviewEnd", function()
	apply_base(nil)
	vim.notify("Review off")
end, { desc = "[Review] レビューモード終了" })

-- <leader>gs: モード別の変更ファイル一覧 (git status)
function M.files_changed()
	local base = vim.g.review_base
	if not base then
		Snacks.picker.git_status({ layout = { preset = "ivy" } })
		return
	end
	local files = vim.fn.systemlist({ "git", "diff", "--name-only", base .. "...HEAD" })
	local items = {}
	for _, file in ipairs(files) do
		table.insert(items, { text = file, file = file })
	end
	Snacks.picker.pick({
		source = "review_changed_files",
		title = "Changed (Review: " .. base .. ")",
		layout = { preset = "ivy" },
		items = items,
		format = "file",
		preview = function(ctx)
			local lines = vim.fn.systemlist({ "git", "diff", base .. "...HEAD", "--", ctx.item.file })
			ctx.preview:set_lines(lines)
			ctx.preview:highlight({ ft = "diff" })
		end,
		confirm = function(picker, item)
			picker:close()
			if item and item.file then
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))
			end
		end,
	})
end

-- <leader>gg: CodeDiff (モード時はbase適用)
function M.code_diff()
	local base = vim.g.review_base
	if base then
		vim.cmd("CodeDiff " .. base .. "...HEAD")
	else
		vim.cmd("CodeDiff")
	end
end

-- lualine用
function M.status()
	local base = vim.g.review_base
	if base then
		return "  Review: " .. base
	end
	return ""
end

return M
