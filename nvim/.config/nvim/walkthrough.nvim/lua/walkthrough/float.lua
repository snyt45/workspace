-- walkthrough.nvim / float
-- noteフロート（常に1枚）。ウィンドウは再利用し、中身のバッファだけ差し替える。
-- そのため回答の自動反映で内容が更新されてもフォーカスは飛ばない。

local session_mod = require("walkthrough.session")
local util = require("walkthrough.util")

local M = {}

local ns_float = vim.api.nvim_create_namespace("walkthrough_float")

vim.api.nvim_set_hl(0, "WalkthroughLocator", { link = "Title", default = true })
vim.api.nvim_set_hl(0, "WalkthroughSeparator", { link = "FloatBorder", default = true })
vim.api.nvim_set_hl(0, "WalkthroughAuthor", { link = "Identifier", default = true })

-- 表示中のフロート。session/idx はトグル判定と再描画に使う
local float = { win = nil, session = nil, idx = nil }

-- thread付きステップのフロートで r を押したときの返信ハンドラ（連携プラグインが登録）
local reply_handler = nil

function M.set_reply_handler(fn)
	reply_handler = fn
end

function M.is_open()
	return float.win ~= nil and vim.api.nvim_win_is_valid(float.win)
end

function M.showing()
	return float.session, float.idx
end

function M.close()
	if M.is_open() then
		vim.api.nvim_win_close(float.win, true)
	end
	float.win, float.session, float.idx = nil, nil, nil
end

-- --------------------------------------------------------------------------
-- レイアウト
-- --------------------------------------------------------------------------
--- ステップ1枚分の描画行を組み立てる（ウィンドウは開かない）
--- 戻り値: lines, marks（{row, group}）, width（実際の内容幅）
local function layout(session, idx, max_width)
	local step = session.steps[idx]
	local marker = idx == session.index and "●" or "▎"
	local locator =
		string.format("  %s %s · %d/%d   %s:%d", marker, session.name, idx, #session.steps, step.file, step.line)
	if util.has_thread(step) then
		locator = locator .. string.format("   💬 %d", #step.thread)
	end

	local lines = {}
	local marks = {}
	local seps = {} -- 区切り行の位置と文字。内容幅が確定してからまとめて引き直す

	for _, sub in ipairs(util.wrap_line(locator, max_width)) do
		lines[#lines + 1] = sub
		marks[#marks + 1] = { row = #lines, group = "WalkthroughLocator" }
	end
	lines[#lines + 1] = ""
	seps[#seps + 1] = { row = #lines, char = "━" }
	marks[#marks + 1] = { row = #lines, group = "WalkthroughSeparator" }

	local function push_text(text)
		local raw = {}
		for line in (text or ""):gmatch("([^\n]*)\n?") do
			if line ~= "" or #raw > 0 then
				raw[#raw + 1] = line
			end
		end
		if #raw > 0 and raw[#raw] == "" then
			table.remove(raw)
		end
		for _, l in ipairs(raw) do
			for _, sub in ipairs(util.wrap_line(l, max_width)) do
				lines[#lines + 1] = sub
			end
		end
	end

	if util.has_thread(step) then
		-- スレッド: 発言ごとに authorラベル + 本文、発言間は区切り線
		for ei, entry in ipairs(step.thread) do
			if ei > 1 then
				lines[#lines + 1] = ""
				seps[#seps + 1] = { row = #lines, char = "─" }
				marks[#marks + 1] = { row = #lines, group = "WalkthroughSeparator" }
			end
			lines[#lines + 1] = "▌ " .. tostring(entry.author or "?")
			marks[#marks + 1] = { row = #lines, group = "WalkthroughAuthor" }
			push_text(entry.text)
		end
	else
		push_text(step.note)
	end

	local width = 0
	for _, l in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(l))
	end
	width = math.min(math.max(width, 1), max_width)
	for _, sep in ipairs(seps) do
		lines[sep.row] = string.rep(sep.char, width)
	end

	return lines, marks, width
end

--- プレビュー用テキスト: note全文（threadは発言ごとにauthor付き）+ values
function M.preview_text(step)
	local parts = { string.format("`%s:%d`", step.file, step.line), "" }
	if util.has_thread(step) then
		for ei, entry in ipairs(step.thread) do
			if ei > 1 then
				parts[#parts + 1] = ""
				parts[#parts + 1] = "---"
				parts[#parts + 1] = ""
			end
			parts[#parts + 1] = "**" .. tostring(entry.author or "?") .. "**"
			parts[#parts + 1] = ""
			parts[#parts + 1] = entry.text or ""
		end
	else
		parts[#parts + 1] = step.note or ""
	end
	if type(step.values) == "table" and #step.values > 0 then
		parts[#parts + 1] = ""
		parts[#parts + 1] = "**values**"
		for _, v in ipairs(step.values) do
			parts[#parts + 1] = string.format("- `%s = %s` (L%s)", v.name or "?", tostring(v.value), v.line or "?")
		end
	end
	return table.concat(parts, "\n")
end

-- --------------------------------------------------------------------------
-- 表示
-- --------------------------------------------------------------------------
local function make_buf(session, idx, lines, marks)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"

	for _, m in ipairs(marks) do
		pcall(vim.api.nvim_buf_set_extmark, buf, ns_float, m.row - 1, 0, { line_hl_group = m.group })
	end

	local map = { buffer = buf, nowait = true, silent = true }
	vim.keymap.set("n", "q", function()
		pcall(vim.cmd, "wincmd p")
	end, vim.tbl_extend("force", map, { desc = "[Walkthrough] フロートを離れる" }))

	-- セッションのフロート内キー（例: pi-comment の e=編集 / d=削除）。
	-- 意味的アクション（hooks.actions）はキーマップにしない（`purge` 等が誤爆するため）
	for key, fn in pairs(session.hooks and session.hooks.keys or {}) do
		vim.keymap.set("n", key, function()
			fn(session, idx)
		end, vim.tbl_extend("force", map, { desc = "[Walkthrough] ステップアクション: " .. key }))
	end

	if util.has_thread(session.steps[idx]) and type(reply_handler) == "function" then
		vim.keymap.set("n", "r", function()
			reply_handler(session, idx)
		end, vim.tbl_extend("force", map, { desc = "[Walkthrough] スレッドに返信" }))
	end

	return buf
end

--- 指定ステップのnoteフロートを右上に表示する。
--- 既に開いていればウィンドウを再利用して中身だけ差し替える（フォーカスを奪わない）
function M.show(session, idx)
	if not session.steps[idx] then
		return false
	end
	local max_width = math.max(20, math.floor(vim.o.columns * 0.7) - 2)
	local lines, marks, content_width = layout(session, idx, max_width)
	local buf = make_buf(session, idx, lines, marks)

	local geometry = {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = vim.o.columns - 1,
		width = math.min(content_width + 2, math.floor(vim.o.columns * 0.7)),
		height = math.min(#lines, math.max(5, math.floor(vim.o.lines * 0.7))),
	}

	if M.is_open() then
		vim.api.nvim_win_set_buf(float.win, buf)
		pcall(vim.api.nvim_win_set_config, float.win, geometry)
	else
		geometry.style = "minimal"
		geometry.border = "rounded"
		geometry.focusable = true
		geometry.noautocmd = true
		float.win = vim.api.nvim_open_win(buf, false, geometry)
		vim.wo[float.win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
	end

	float.session, float.idx = session, idx

	-- スレッドは最新の発言から読みたいので末尾を表示した状態にする
	if util.has_thread(session.steps[idx]) then
		pcall(vim.api.nvim_win_set_cursor, float.win, { #lines, 0 })
	end
	return true
end

--- アクティブステップのnoteを表示
function M.show_active(session)
	return M.show(session, session.index)
end

--- セッションが置き換わったとき、そのセッションを表示中なら同じステップで再描画する。
--- 別セッションを表示中／閉じているときは何もしない（フロートは常に1枚・勝手に奪わない）
function M.refresh_for(prev, next_session)
	if not (M.is_open() and prev and float.session == prev) then
		return false
	end
	return M.show(next_session, math.min(float.idx or 1, #next_session.steps))
end

function M.focus()
	if M.is_open() then
		pcall(vim.api.nvim_set_current_win, float.win)
		return true
	end
	return false
end

--- noteフロートをトグルする。開くのはカーソル下のステップ（なければアクティブステップ）。
--- 表示中に別ステップの上で押した場合は閉じずにそのステップへ切り替える。
--- 開いた場合はフォーカスも移す（フロート内の e/d/r/q をそのまま使えるように）
function M.toggle()
	local s, idx = session_mod.step_at_cursor()
	if M.is_open() then
		if s and (float.session ~= s or float.idx ~= idx) then
			M.show(s, idx)
			M.focus()
		else
			M.close()
		end
		return
	end

	local active = session_mod.get_active()
	if s then
		M.show(s, idx)
	elseif active then
		M.show_active(active)
	else
		util.notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end
	M.focus()
end

return M
