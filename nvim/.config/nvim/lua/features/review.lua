-- ==========================================================================
-- レビューモード
-- vim.g.review_base を中心に、Diffview が同じbaseを参照する
-- ==========================================================================

local M = {}

local function apply_base(base)
	vim.g.review_base = base
end

local function start_with(base)
	apply_base(base)
	vim.notify("Review: " .. base)
	M.code_diff()
end

-- "origin/foo" のような remote ref を local branch 名に変換 (detached HEAD 回避のため)
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
	pcall(vim.cmd, "DiffviewClose")
	vim.notify("Review off")
end, { desc = "[Review] レビューモード終了" })

-- <leader>gg: 全差分 (モード時はbase適用)
function M.code_diff()
	local base = vim.g.review_base
	if base then
		vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local")
	else
		vim.cmd("DiffviewOpen")
	end
end

-- <leader>gf: 現在バッファの単一ファイル差分 (モード時はbase適用)
function M.code_diff_file()
	local base = vim.g.review_base
	local file = vim.fn.fnameescape(vim.fn.expand("%"))
	if base then
		vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local -- " .. file)
	else
		vim.cmd("DiffviewOpen -- " .. file)
	end
end

return M
