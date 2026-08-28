-- walkthrough.nvim / render
-- バッファ上のマーカー（サイン・行ハイライト・virtual text）と values の描画。

local session_mod = require("walkthrough.session")
local util = require("walkthrough.util")

local M = {}

local ns_marker = vim.api.nvim_create_namespace("walkthrough_marker")
local ns_values = vim.api.nvim_create_namespace("walkthrough_values")

local function place_marker(bufnr, line, idx, total, is_active, label)
	label = label or "step"
	if line < 1 or line > vim.api.nvim_buf_line_count(bufnr) then
		return false
	end
	local opts
	if is_active then
		opts = {
			sign_text = "▶ ",
			sign_hl_group = "DiagnosticHint",
			line_hl_group = "Visual",
			virt_text = { { string.format("  ● %s %d/%d", label, idx, total), "Comment" } },
			virt_text_pos = "eol",
		}
	else
		-- アクティブ以外のステップも常時サイン表示（ファイル単位で眺める用）
		opts = {
			sign_text = "▷ ",
			sign_hl_group = "Comment",
			virt_text = { { string.format("  ▷ %s %d", label, idx), "NonText" } },
			virt_text_pos = "eol",
		}
	end
	pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_marker, line - 1, 0, opts)
	return true
end

local function place_values(bufnr, step)
	if type(step.values) ~= "table" or #step.values == 0 then
		return
	end

	local count = vim.api.nvim_buf_line_count(bufnr)
	local groups = {}
	local skipped = {}

	for _, v in ipairs(step.values) do
		if type(v.line) ~= "number" or v.line < 1 then
			table.insert(skipped, string.format("%s (lineなし)", v.name or "?"))
		elseif v.line > count then
			table.insert(skipped, string.format("%s (行%d > %d)", v.name or "?", v.line, count))
		else
			groups[v.line] = groups[v.line] or {}
			table.insert(groups[v.line], v)
		end
	end

	for ln, vs in pairs(groups) do
		local parts = { { "  ┊ ", "Comment" } }
		for i, v in ipairs(vs) do
			if i > 1 then
				table.insert(parts, { "   ", "Comment" })
			end
			table.insert(parts, { tostring(v.name or ""), "Identifier" })
			table.insert(parts, { " = ", "Comment" })
			table.insert(parts, { tostring(v.value), "String" })
		end
		pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_values, ln - 1, 0, {
			virt_text = parts,
			virt_text_pos = "eol",
			hl_mode = "combine",
		})
	end

	if #skipped > 0 then
		util.notify("valuesをスキップ: " .. table.concat(skipped, ", "), vim.log.levels.WARN)
	end
end

--- バッファ内のステップを描画（アクティブセッションのアクティブステップ=▶+行ハイライト、それ以外=▷サインのみ）
function M.decorate_buffer(bufnr)
	if not (vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns_marker, 0, -1)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_values, 0, -1)

	for _, session in ipairs(session_mod.to_render()) do
		local is_session_active = session == session_mod.get_active()
		for _, entry in ipairs(session_mod.buffer_steps(session, bufnr)) do
			local is_active = is_session_active and entry.idx == session.index
			local line = entry.step.line or 1
			local placed = place_marker(bufnr, line, entry.idx, #session.steps, is_active, session.step_label)
			if not placed and is_active then
				-- 範囲外警告はセッション×ステップごとに1回だけ（BufWinEnterのたびに連発させない）
				session.warned = session.warned or {}
				if not session.warned[entry.idx] then
					session.warned[entry.idx] = true
					util.notify(
						string.format("ステップ%dの行%dが範囲外です（コード編集で行がずれた可能性）", entry.idx, line),
						vim.log.levels.WARN
					)
				end
			end
			if is_active then
				place_values(bufnr, entry.step)
			end
		end
	end
end

function M.refresh()
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(b) then
			M.decorate_buffer(b)
		end
	end
end

return M
