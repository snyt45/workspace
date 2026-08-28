-- walkthrough.nvim / nav
-- ステップ間のジャンプとアクティブ化（バッファを開く・カーソル移動・再描画・フロート表示）。

local float = require("walkthrough.float")
local render = require("walkthrough.render")
local session_mod = require("walkthrough.session")
local util = require("walkthrough.util")

local M = {}

function M.jump_to(session, idx)
	if idx < 1 or idx > #session.steps then
		util.notify(string.format("範囲外です (1..%d)", #session.steps), vim.log.levels.WARN)
		return
	end

	local step = session.steps[idx]
	local path = util.resolve_path(session.root, step.file)
	if not path then
		util.notify(
			string.format("ステップ%dのファイルが見つかりません: %s (root: %s)", idx, tostring(step.file), session.root or "?"),
			vim.log.levels.ERROR
		)
		return
	end

	session.index = idx

	-- bufnr(path) はパスをfile-patternとして解釈するため（[id] 等が壊れる）bufaddで完全一致させる
	local ok, err = pcall(vim.api.nvim_set_current_buf, vim.fn.bufadd(path))
	if not ok then
		util.notify("バッファを開けません（続行します）: " .. tostring(err), vim.log.levels.WARN)
	end

	pcall(vim.api.nvim_win_set_cursor, 0, { math.max(1, step.line or 1), 0 })
	pcall(vim.cmd, "normal! zz")

	render.refresh()
	float.show_active(session)
end

function M.activate(session)
	session_mod.set_active(session)
	M.jump_to(session, session.index)
end

--- アクティブセッションに対する操作。ロードされていなければ警告して nil
local function require_active()
	local active = session_mod.get_active()
	if not active then
		util.notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return nil
	end
	return active
end

function M.next()
	local active = require_active()
	if active then
		M.jump_to(active, active.index + 1)
	end
end

function M.prev()
	local active = require_active()
	if active then
		M.jump_to(active, active.index - 1)
	end
end

function M.goto_step(idx)
	local active = require_active()
	if active then
		M.jump_to(active, idx)
	end
end

M.require_active = require_active

return M
