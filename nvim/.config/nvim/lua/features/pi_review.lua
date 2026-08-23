-- ==========================================================================
-- Pi 行コメントレビュー（旧 pi-nvim-review の後継）
-- pi 側 /nvim も nvim 側 :PiReview のセッション選択も不要。
-- carderne/pi-nvim の自動発見(get_socket_path)と送信(send_raw)を再利用する:
--   pi を起動すると拡張が自動でソケットを開き、nvim は cwd 一致セッションを掴む。
-- ,pa=コメント追加（通常/選択範囲）/ ,pl=コメント一覧 / ,px=提出 / :PiReviewClear=未提出コメント破棄
-- 注意: ,ps は overlook が使用済みのため提出は ,px に割り当てている
-- ==========================================================================

local M = {}

local ns = vim.api.nvim_create_namespace("pi_review")
local list_ns = vim.api.nvim_create_namespace("pi_review_list")
local records = {}
local next_id = 1
local submitting = false
local active_modal
local save_state -- 前方宣言（clear_records 等が先に定義されているため）

local MAX_SOURCE_LINES = 1000
local MAX_SOURCE_CHARS = 64 * 1024
local MAX_COMMENT_BYTES = 16 * 1024

-- 上流 pi-nvim-review の default review instructions と同じテキスト
local DEFAULT_INSTRUCTIONS = table.concat({
	"Process each review comment independently according to its requested outcome.",
	"",
	'- If a comment asks for an explanation or information, answer it directly. Do not modify files for that comment.',
	'- If a comment requests a code change, implement it.',
	'- If a comment contains both a question and a change request, answer the question and implement only the explicit change.',
	'- If the intent is ambiguous, explain the ambiguity and ask for clarification instead of making a speculative change.',
	'- Classify by meaning, not grammar or punctuation. For example, "Can you rename this?" is a change request, while "Can you explain this?" is a question.',
	"",
	"Inspect the current files before answering or editing. Source excerpts can contain unsaved or outdated buffer text.",
	"",
	"In the final response, use separate sections for changes made, questions answered, and comments that need clarification.",
}, "\n")

vim.api.nvim_set_hl(0, "PiReviewComment", { default = true, link = "DiagnosticInfo" })
-- 一覧（スレッドビュー）用
vim.api.nvim_set_hl(0, "PiReviewListHeader", { default = true, link = "Title" }) -- ファイル見出し
vim.api.nvim_set_hl(0, "PiReviewListLoc", { default = true, link = "Number" }) -- L行チップ
vim.api.nvim_set_hl(0, "PiReviewListComment", { default = true, link = "DiagnosticInfo" }) -- コメント本文
vim.api.nvim_set_hl(0, "PiReviewListSource", { default = true, link = "Comment" }) -- ソース文脈
vim.api.nvim_set_hl(0, "PiReviewListDivider", { default = true, link = "Comment" }) -- コメント間区切り

local function notify(message, level)
	vim.notify("pi-review: " .. message, level or vim.log.levels.INFO)
end

local function pi_nvim()
	return require("pi-nvim")
end

-- pi セッションのソケットパス（pi-nvim の自動発見ロジックをそのまま使う: cwd一致→最新→latest symlink）
local function socket_path()
	return pi_nvim().get_socket_path()
end

-- pi セッションの project root: <socket>.info の cwd（読めなければ nvim cwd）
local function project_root()
	local socket = socket_path()
	if socket then
		local ok, lines = pcall(vim.fn.readfile, socket .. ".info")
		if ok and lines and lines[1] then
			local decoded_ok, info = pcall(vim.json.decode, lines[1])
			if decoded_ok and type(info) == "table" and type(info.cwd) == "string" then
				return vim.uv.fs_realpath(info.cwd) or vim.fs.normalize(info.cwd)
			end
		end
	end
	return vim.uv.fs_realpath(vim.uv.cwd()) or vim.fs.normalize(vim.uv.cwd())
end

local function relative_path(root, absolute)
	local rel = vim.fs.relpath(root, absolute)
	if not rel or rel == "" or rel:sub(1, 2) == ".." then
		return nil
	end
	return rel:gsub("\\", "/")
end

local function comment_summary(comment)
	local single_line = comment:gsub("%s+", " ")
	local summary = vim.fn.strcharpart(single_line, 0, 80)
	if vim.fn.strchars(single_line) > 80 then
		summary = summary .. "…"
	end
	return summary
end

local function split_lines(text)
	local out = {}
	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		out[#out + 1] = line
	end
	while #out > 0 and out[#out] == "" do
		out[#out] = nil
	end
	return out
end

local function validate_comment(text)
	text = vim.trim(text)
	if text == "" then
		notify("空のコメントは追加されませんでした", vim.log.levels.WARN)
		return nil
	end
	if #text > MAX_COMMENT_BYTES then
		notify("コメントが16KiBを超えています", vim.log.levels.WARN)
		return nil
	end
	return text
end

-- extmark の作成/更新（mark_id が nil なら新規、指定すれば opts.id で更新: nvim 0.12 仕様）
local function set_comment_mark(bufnr, mark_id, start_line, end_line, comment)
	local ok, result = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, start_line - 1, 0, {
		id = mark_id,
		end_row = end_line - 1,
		end_col = -1,
		strict = false,
		right_gravity = false,
		end_right_gravity = true,
		sign_text = "Pi",
		sign_hl_group = "PiReviewComment",
		virt_text = { { " Pi: " .. comment_summary(comment), "PiReviewComment" } },
		virt_text_pos = "eol",
		priority = 150,
	})
	return ok, result
end

-- --------------------------------------------------------------------------
-- コメント入力モーダル（多行エディタ）
-- --------------------------------------------------------------------------
local function modal_finish(value)
	local current = active_modal
	if not current then
		return
	end
	active_modal = nil
	pcall(vim.cmd.stopinsert)
	if vim.api.nvim_win_is_valid(current.win) then
		pcall(vim.api.nvim_win_close, current.win, true)
	end
	if vim.api.nvim_buf_is_valid(current.buf) then
		pcall(vim.api.nvim_buf_delete, current.buf, { force = true })
	end
	vim.schedule(function()
		current.callback(value)
	end)
end

local function comment_modal(title, initial, callback)
	if active_modal then
		notify("別のコメントエディタが開いています", vim.log.levels.WARN)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"

	if type(initial) == "string" and initial ~= "" then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, split_lines(initial))
	end

	local width = math.max(1, math.min(72, vim.o.columns - 4))
	local height = math.max(1, math.min(8, vim.o.lines - vim.o.cmdheight - 4))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.max(0, math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2)),
		col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " " .. vim.fn.strcharpart(title, 0, math.max(1, width - 4)) .. " ",
		title_pos = "center",
		footer = " <C-s> 保存 · <Esc> キャンセル ",
		footer_pos = "center",
	})

	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.wo[win].cursorline = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"

	active_modal = { buf = buf, win = win, callback = callback }

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			if active_modal and active_modal.win == win then
				modal_finish(nil)
			end
		end,
	})

	local function submit()
		if not vim.api.nvim_buf_is_valid(buf) then
			modal_finish(nil)
			return
		end
		modal_finish(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
	end
	local function cancel()
		modal_finish(nil)
	end
	local map = { buffer = buf, silent = true, nowait = true }
	vim.keymap.set({ "n", "i" }, "<C-s>", submit, map)
	vim.keymap.set({ "n", "i" }, "<Esc>", cancel, map)
	vim.keymap.set("n", "q", cancel, map)
	vim.keymap.set({ "n", "i" }, "<C-c>", cancel, map)

	vim.schedule(function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_set_current_win(win)
			vim.cmd.startinsert()
		end
	end)
end

-- --------------------------------------------------------------------------
-- コメント追加
-- --------------------------------------------------------------------------
function M.annotate(start_line, end_line)
	local bufnr = vim.api.nvim_get_current_buf()
	if vim.bo[bufnr].buftype ~= "" then
		notify("コメントは通常のファイルバッファでのみ追加できます", vim.log.levels.WARN)
		return
	end

	local absolute = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(bufnr))
	if not absolute then
		notify("ファイルを保存してからコメントを追加してください", vim.log.levels.WARN)
		return
	end

	local path = relative_path(project_root(), absolute)
	if not path then
		notify("現在のファイルはPiプロジェクトの外にあります", vim.log.levels.WARN)
		return
	end

	local first_line = math.min(start_line, end_line)
	local last_line = math.max(start_line, end_line)
	if last_line - first_line + 1 > MAX_SOURCE_LINES then
		notify(("1コメントで %d 行を超える範囲にはコメントできません"):format(MAX_SOURCE_LINES), vim.log.levels.WARN)
		return
	end

	local location = first_line == last_line and tostring(first_line) or string.format("%d-%d", first_line, last_line)
	comment_modal(string.format("Piコメント · %s:%s", path, location), nil, function(comment)
		if comment == nil then
			return
		end
		comment = validate_comment(comment)
		if not comment then
			return
		end

		local ok, mark_id = set_comment_mark(bufnr, nil, first_line, last_line, comment)
		if not ok then
			notify("コメントの表示に失敗しました: " .. tostring(mark_id), vim.log.levels.ERROR)
			return
		end

		records[#records + 1] = {
			id = next_id,
			bufnr = bufnr,
			mark_id = mark_id,
			absolute_path = absolute,
			start_line = first_line,
			end_line = last_line,
			comment = comment,
		}
		next_id = next_id + 1
		save_state()
		notify(("コメントを追加: %s:%s"):format(path, location))
	end)
end

-- --------------------------------------------------------------------------
-- ペイロード・メッセージ構築
-- --------------------------------------------------------------------------
local function current_range(record)
	if vim.api.nvim_buf_is_valid(record.bufnr) and vim.api.nvim_buf_is_loaded(record.bufnr) then
		local ok, mark = pcall(
			vim.api.nvim_buf_get_extmark_by_id,
			record.bufnr,
			ns,
			record.mark_id,
			{ details = true }
		)
		if ok and type(mark) == "table" and #mark >= 2 then
			local details = mark[3] or {}
			local start_row = mark[1]
			local end_row = type(details.end_row) == "number" and details.end_row or start_row
			return start_row + 1, math.max(start_row, end_row) + 1
		end
	end
	return record.start_line, record.end_line
end

local function source_lines(record, start_line, end_line)
	local lines
	if vim.api.nvim_buf_is_valid(record.bufnr) and vim.api.nvim_buf_is_loaded(record.bufnr) then
		local line_count = vim.api.nvim_buf_line_count(record.bufnr)
		if start_line <= line_count then
			local ok, got = pcall(
				vim.api.nvim_buf_get_lines,
				record.bufnr,
				start_line - 1,
				math.min(end_line, line_count),
				false
			)
			if ok then
				lines = got
			end
		end
	end
	if not lines then
		local ok, file_lines = pcall(vim.fn.readfile, record.absolute_path, "", end_line)
		if not ok then
			return nil, "ファイルを読み込めません: " .. record.absolute_path
		end
		lines = {}
		for line = start_line, end_line do
			lines[#lines + 1] = file_lines[line] or ""
		end
	end

	local expected = end_line - start_line + 1
	while #lines < expected do
		lines[#lines + 1] = ""
	end

	local chars = 0
	for _, line in ipairs(lines) do
		chars = chars + #line + 1
	end
	if chars > MAX_SOURCE_CHARS then
		return nil, string.format("ソース抜粋が64KiBを超えています: %s:%d-%d", record.absolute_path, start_line, end_line)
	end
	return lines
end

local function build_payload(root)
	local resolved = {}
	for _, record in ipairs(records) do
		local path = relative_path(root, record.absolute_path)
		if not path then
			return nil, "Piプロジェクトの外にあるコメントを中断しました: " .. record.absolute_path
		end
		local start_line, end_line = current_range(record)
		if end_line - start_line + 1 > MAX_SOURCE_LINES then
			return nil, string.format("注釈が %d 行を超えました: %s:%d", MAX_SOURCE_LINES, path, start_line)
		end
		local source, source_error = source_lines(record, start_line, end_line)
		if not source then
			return nil, source_error
		end
		resolved[#resolved + 1] = {
			order = record.id,
			path = path,
			startLine = start_line,
			endLine = end_line,
			comment = record.comment,
			source = source,
		}
	end

	table.sort(resolved, function(left, right)
		if left.path ~= right.path then
			return left.path < right.path
		end
		if left.startLine ~= right.startLine then
			return left.startLine < right.startLine
		end
		if left.endLine ~= right.endLine then
			return left.endLine < right.endLine
		end
		return left.order < right.order
	end)
	return resolved
end

local function review_instructions(root)
	-- プロジェクトごとの指示書。なければ上流 pi-nvim-review と同じデフォルト
	local prompt_file = vim.fs.joinpath(root, ".pi", "nvim-review-prompt.md")
	if vim.fn.filereadable(prompt_file) == 1 then
		local ok, lines = pcall(vim.fn.readfile, prompt_file)
		if not ok then
			return nil, string.format("指示書を読み込めません: %s (%s)", prompt_file, tostring(lines))
		end
		return table.concat(lines, "\n"):match("^%s*(.-)%s*$"), nil
	end
	return DEFAULT_INSTRUCTIONS, nil
end

local function format_review_prompt(root, payload)
	local instructions, instructions_error = review_instructions(root)
	if not instructions then
		return nil, instructions_error
	end

	local parts = {}
	if instructions ~= "" then
		parts[#parts + 1] = instructions
		parts[#parts + 1] = ""
	end
	parts[#parts + 1] = "Project root: " .. vim.json.encode(root)
	parts[#parts + 1] = ""

	for index, annotation in ipairs(payload) do
		local width = #tostring(annotation.endLine)
		local location = annotation.startLine == annotation.endLine
			and tostring(annotation.startLine)
			or string.format("%d-%d", annotation.startLine, annotation.endLine)

		parts[#parts + 1] = "## Comment " .. index
		parts[#parts + 1] = "File: " .. vim.json.encode(annotation.path)
		parts[#parts + 1] = "Lines: " .. location
		parts[#parts + 1] = ""
		parts[#parts + 1] = "Review comment:"
		for _, line in ipairs(split_lines(annotation.comment)) do
			parts[#parts + 1] = "> " .. line
		end
		parts[#parts + 1] = ""
		parts[#parts + 1] = "Source excerpt:"
		for source_index, source_line in ipairs(annotation.source) do
			parts[#parts + 1] = string.format("    %" .. width .. "d | %s", annotation.startLine + source_index - 1, source_line)
		end
		parts[#parts + 1] = ""
	end

	return table.concat(parts, "\n"):gsub("%s+$", ""), nil
end

-- --------------------------------------------------------------------------
-- 提出・破棄
-- --------------------------------------------------------------------------
local function clear_records()
	for _, record in ipairs(records) do
		if vim.api.nvim_buf_is_valid(record.bufnr) then
			pcall(vim.api.nvim_buf_del_extmark, record.bufnr, ns, record.mark_id)
		end
	end
	records = {}
	save_state()
end

-- --------------------------------------------------------------------------
-- 永続化: 未提出コメントを vim 再起動後も復元する
-- （上流 pi-nvim-review はメモリ保持のみだったが、こちらは state ファイルに保存）
-- --------------------------------------------------------------------------
local function state_file()
	local dir = vim.fn.stdpath("state")
	vim.fn.mkdir(dir, "p")
	return vim.fs.joinpath(dir, "pi_review.json")
end

save_state = function()
	local data = {}
	for _, record in ipairs(records) do
		data[#data + 1] = {
			id = record.id,
			absolute_path = record.absolute_path,
			start_line = record.start_line,
			end_line = record.end_line,
			comment = record.comment,
		}
	end
	local ok, encoded = pcall(vim.json.encode, data)
	if not ok then
		return
	end
	local path = state_file()
	pcall(vim.fn.writefile, { encoded }, path)
end

local function load_state()
	local path = state_file()
	if vim.fn.filereadable(path) ~= 1 then
		return
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or not lines or not lines[1] then
		return
	end
	local decode_ok, data = pcall(vim.json.decode, lines[1])
	if not decode_ok or type(data) ~= "table" then
		return
	end
	for _, item in ipairs(data) do
		if type(item) == "table"
			and type(item.absolute_path) == "string"
			and type(item.comment) == "string"
			and type(item.start_line) == "number"
			then
			local record = {
				id = type(item.id) == "number" and item.id or next_id,
				bufnr = vim.fn.bufadd(item.absolute_path),
				mark_id = nil,
				absolute_path = item.absolute_path,
				start_line = item.start_line,
				end_line = type(item.end_line) == "number" and item.end_line or item.start_line,
				comment = item.comment,
			}
			-- すでに開いているバッファにはサインを復元（閉じている場合はジャンプ時に復元）
			if vim.api.nvim_buf_is_valid(record.bufnr) and vim.api.nvim_buf_is_loaded(record.bufnr) then
				local mark_ok, mark_id = set_comment_mark(record.bufnr, nil, record.start_line, record.end_line, record.comment)
				if mark_ok then
					record.mark_id = mark_id
				end
			end
			records[#records + 1] = record
			if record.id >= next_id then
				next_id = record.id + 1
			end
		end
	end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		save_state()
	end,
})

function M.submit()
	if submitting then
		notify("送信処理が進行中です", vim.log.levels.WARN)
		return
	end
	if #records == 0 then
		notify("提出するコメントがありません", vim.log.levels.WARN)
		return
	end
	if not socket_path() then
		notify("piセッションが見つかりません（piを起動してください）", vim.log.levels.WARN)
		return
	end

	local root = project_root()
	local payload, payload_error = build_payload(root)
	if not payload then
		notify(payload_error, vim.log.levels.ERROR)
		return
	end

	local message, format_error = format_review_prompt(root, payload)
	if not message then
		notify(format_error, vim.log.levels.ERROR)
		return
	end

	submitting = true
	pi_nvim().send_raw({ type = "prompt", message = message }, function(err, response)
		submitting = false
		if err or not response or not response.ok then
			notify((err or "piがレビューを受け付けませんでした") .. "; コメントは保持されました", vim.log.levels.ERROR)
			return
		end

		clear_records()
		notify(("%dコメントをpiに提出しました"):format(#payload))
	end)
end

function M.clear()
	if #records == 0 then
		notify("破棄するコメントはありません")
		return
	end
	local count = #records
	clear_records()
	notify(("%dコメントを破棄しました"):format(count))
end

-- --------------------------------------------------------------------------
-- 一覧・編集・削除・ジャンプ
-- --------------------------------------------------------------------------
--- コメントを編集中のモーダルを開く（初期値あり）
local function edit_comment(id)
	local record
	for _, candidate in ipairs(records) do
		if candidate.id == id then
			record = candidate
			break
		end
	end
	if not record then
		notify("コメントが見つかりません（既に削除された可能性）", vim.log.levels.WARN)
		return
	end

	local path = relative_path(project_root(), record.absolute_path) or record.absolute_path
	local start_line, end_line = current_range(record)
	local location = start_line == end_line and tostring(start_line) or string.format("%d-%d", start_line, end_line)

	comment_modal(string.format("Piコメント編集 · %s:%s", path, location), record.comment, function(text)
		if text == nil then
			return
		end
		text = validate_comment(text)
		if not text then
			return
		end

		record.comment = text
		if vim.api.nvim_buf_is_valid(record.bufnr) then
			local ok, new_mark = set_comment_mark(record.bufnr, record.mark_id, start_line, end_line, text)
			if ok then
				record.mark_id = new_mark
			end
		end
		save_state()
		notify(("コメントを編集: %s:%s"):format(path, location))
	end)
end

--- コメントを1件削除（extmark も取り除く）
local function remove_comment(id)
	for index, record in ipairs(records) do
		if record.id == id then
			if vim.api.nvim_buf_is_valid(record.bufnr) then
				pcall(vim.api.nvim_buf_del_extmark, record.bufnr, ns, record.mark_id)
			end
			table.remove(records, index)
			save_state()
			return true
		end
	end
	return false
end

--- 対象行へジャンプ（バッファを閉じていれば開き直し、extmark が無ければ再表示）
local function jump(record)
	local bufnr = record.bufnr
	if not (vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)) then
		bufnr = vim.fn.bufadd(record.absolute_path)
		vim.fn.bufload(bufnr)
	end

	local win = vim.fn.bufwinid(bufnr)
	if win ~= -1 then
		vim.api.nvim_set_current_win(win)
	else
		vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), bufnr)
	end
	record.bufnr = bufnr

	local start_line, end_line = current_range(record)
	local ok, mark = pcall(vim.api.nvim_buf_get_extmark_by_id, bufnr, ns, record.mark_id, {})
	if not (ok and #mark >= 2) then
		local re_ok, new_mark = set_comment_mark(bufnr, nil, start_line, end_line, record.comment)
		if re_ok then
			record.mark_id = new_mark
		end
	end

	vim.api.nvim_win_set_cursor(0, { start_line, 0 })
	vim.cmd("normal! zz")
end

--- コメント一覧（GitHub PR レビュー風のスレッドビュー）
-- ファイル見出し → 「L12」行チップ + コメント全文 → 該当ソース文脈
local list_state

local function list_close()
	if list_state and vim.api.nvim_win_is_valid(list_state.win) then
		pcall(vim.api.nvim_win_close, list_state.win, true)
	end
	list_state = nil
end

local function list_render()
	local state = list_state
	if not state or not (vim.api.nvim_buf_is_valid(state.buf) and vim.api.nvim_win_is_valid(state.win)) then
		return
	end

	local root = project_root()
	-- ファイルごとにグループ → 行順
	local by_file = {}
	local order = {}
	for _, record in ipairs(records) do
		local path = relative_path(root, record.absolute_path) or record.absolute_path
		if not by_file[path] then
			by_file[path] = {}
			order[#order + 1] = path
		end
		by_file[path][#by_file[path] + 1] = record
	end
	table.sort(order)

	local lines = {}
	local blocks = {}
	local headers = {}
	local divider_rows = {}
	local inner_width = math.max(20, state.width - 2)
	for _, path in ipairs(order) do
		local group = by_file[path]
		table.sort(group, function(a, b)
			local al = current_range(a)
			local bl = current_range(b)
			return al < bl
		end)
		-- ファイル見出しバー（件数付き・全幅）
		local label = ("─ %s (%d) "):format(path, #group)
		headers[#lines + 1] = true
		lines[#lines + 1] = label .. string.rep("─", math.max(1, inner_width - vim.fn.strdisplaywidth(label)))
		for index, record in ipairs(group) do
			local start_line, end_line = current_range(record)
			local location = start_line == end_line and ("L%d"):format(start_line) or ("L%d-%d"):format(start_line, end_line)
			blocks[#blocks + 1] = { record = record, head_line = #lines + 1, location = location }
			local comment_lines = split_lines(record.comment)
			local indent = string.rep(" ", #location)
			lines[#lines + 1] = location .. "  " .. (comment_lines[1] or "")
			for i = 2, #comment_lines do
				lines[#lines + 1] = indent .. "  " .. comment_lines[i]
			end
			-- 該当ソース（文脈）
			local source = source_lines(record, start_line, end_line)
			if source then
				local max_preview = 6
				for sindex = 1, math.min(#source, max_preview) do
					lines[#lines + 1] = string.format("   %4d | %s", start_line + sindex - 1, source[sindex])
				end
				if #source > max_preview then
					lines[#lines + 1] = string.format("   … 全%d行", #source)
				end
			end
			if index < #group then
				-- コメント間の区切り線（薄く・インデント）
				lines[#lines + 1] = ""
				lines[#lines + 1] = "    " .. string.rep("─", math.max(1, inner_width - 4))
				divider_rows[#lines] = true
			else
				lines[#lines + 1] = ""
			end
		end
	end

	state.blocks = blocks
	if #blocks == 0 then
		notify("コメントが全て削除されました")
		list_close()
		return
	end
	if not state.sel or state.sel > #blocks then
		state.sel = 1
	end

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	-- ハイライト: ファイル見出し / 行チップ+コメント本文 / ソース文脈
	vim.api.nvim_buf_clear_namespace(state.buf, list_ns, 0, -1)
	for lineno in pairs(headers) do
		vim.api.nvim_buf_add_highlight(state.buf, list_ns, "PiReviewListHeader", lineno - 1, 0, -1)
	end
	for _, block in ipairs(blocks) do
		local row0 = block.head_line - 1
		local chip_len = #block.location
		vim.api.nvim_buf_set_extmark(state.buf, list_ns, row0, 0, {
			hl_group = "PiReviewListLoc",
			end_row = row0,
			end_col = chip_len,
			strict = false,
		})
		local comment_lines = split_lines(block.record.comment)
		for i = 0, #comment_lines - 1 do
			local start_col = i == 0 and (chip_len + 2) or 2
			vim.api.nvim_buf_set_extmark(state.buf, list_ns, row0 + i, start_col, {
				hl_group = "PiReviewListComment",
				end_row = row0 + i,
				end_col = -1,
				strict = false,
			})
		end
	end
	for row0 = 0, #lines - 1 do
		if lines[row0 + 1]:match("^   %-?%d+ |") then
			vim.api.nvim_buf_add_highlight(state.buf, list_ns, "PiReviewListSource", row0, 0, -1)
		end
	end
	for lineno in pairs(divider_rows) do
		vim.api.nvim_buf_add_highlight(state.buf, list_ns, "PiReviewListDivider", lineno - 1, 0, -1)
	end

	-- 選択コメントへカーソルを置く（ウィンドウが自動スクロール）
	vim.api.nvim_win_set_cursor(state.win, { blocks[state.sel].head_line, 0 })

	-- 高さを内容に合わせる（上限付き）
	local max_height = math.max(10, vim.o.lines - vim.o.cmdheight - 6)
	local height = math.min(#lines + 2, max_height)
	local row = math.max(0, math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2))
	pcall(vim.api.nvim_win_set_height, state.win, height)
	pcall(vim.api.nvim_win_set_config, state.win, {
		row = row,
		height = height,
		title = string.format(" Pi Comments · %d件 ", #blocks),
		title_pos = "center",
		footer = " j/k コメント移動 · <CR> ソースへ · e 編集 · d 削除 · s 提出 · q 閉じる ",
		footer_pos = "center",
	})
end

function M.list()
	if #records == 0 then
		notify("表示するコメントがありません", vim.log.levels.WARN)
		return
	end
	if list_state then
		list_close()
		return
	end

	local width = math.min(96, vim.o.columns - 4)
	local height = math.min(12, vim.o.lines - vim.o.cmdheight - 6)
	local row = math.max(0, math.floor((vim.o.lines - vim.o.cmdheight - height - 2) / 2))

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	list_state = { buf = buf, win = nil, sel = 1, width = width, blocks = {} }

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " Pi Comments ",
		title_pos = "center",
		footer = " j/k コメント移動 · <CR> ソースへ · e 編集 · d 削除 · s 提出 · q 閉じる ",
		footer_pos = "center",
	})
	list_state.win = win

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].signcolumn = "no"
	vim.wo[win].wrap = false
	vim.wo[win].cursorline = true

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			list_state = nil
		end,
	})

	local function move(delta)
		if not list_state or #list_state.blocks == 0 then
			return
		end
		list_state.sel = math.max(1, math.min(#list_state.blocks, list_state.sel + delta))
		list_render()
	end
	local function selected_record()
		return list_state and list_state.blocks and list_state.blocks[list_state.sel]
			and list_state.blocks[list_state.sel].record
	end

	local map = { buffer = buf, silent = true, nowait = true }
	vim.keymap.set("n", "j", function()
		move(1)
	end, map)
	vim.keymap.set("n", "k", function()
		move(-1)
	end, map)
	vim.keymap.set("n", "<Down>", function()
		move(1)
	end, map)
	vim.keymap.set("n", "<Up>", function()
		move(-1)
	end, map)
	vim.keymap.set("n", "g", function()
		if list_state then
			list_state.sel = 1
			list_render()
		end
	end, map)
	vim.keymap.set("n", "G", function()
		if list_state then
			list_state.sel = #list_state.blocks
			list_render()
		end
	end, map)
	vim.keymap.set("n", "<CR>", function()
		local record = selected_record()
		list_close()
		if record then
			vim.schedule(function()
				jump(record)
			end)
		end
	end, map)
	vim.keymap.set("n", "e", function()
		local record = selected_record()
		list_close()
		if record then
			vim.schedule(function()
				edit_comment(record.id)
			end)
		end
	end, map)
	vim.keymap.set("n", "d", function()
		local record = selected_record()
		if record and remove_comment(record.id) then
			notify("コメントを削除しました")
			list_render()
		end
	end, map)
	vim.keymap.set("n", "s", function()
		list_close()
		vim.schedule(function()
			M.submit()
		end)
	end, map)
	vim.keymap.set("n", "q", list_close, map)
	vim.keymap.set("n", "<Esc>", list_close, map)
	vim.keymap.set("n", "<C-c>", list_close, map)

	list_render()
end

-- --------------------------------------------------------------------------
-- コマンド・キーマップ
-- --------------------------------------------------------------------------
vim.api.nvim_create_user_command("PiReviewAnnotate", function(args)
	M.annotate(args.line1, args.line2)
end, { range = true, desc = "Piレビュー: 行/範囲にコメント追加" })

vim.api.nvim_create_user_command("PiReviewList", function()
	M.list()
end, { desc = "Piレビュー: コメント一覧" })

vim.api.nvim_create_user_command("PiReviewSubmit", function()
	M.submit()
end, { desc = "Piレビュー: コメント提出" })

vim.api.nvim_create_user_command("PiReviewClear", function()
	M.clear()
end, { desc = "Piレビュー: 未提出コメント破棄" })

vim.keymap.set("n", "<leader>pa", "<Cmd>PiReviewAnnotate<CR>", { desc = "[Pi] 行にレビューコメント" })
vim.keymap.set("x", "<leader>pa", ":<C-U>'<,'>PiReviewAnnotate<CR>", { desc = "[Pi] 選択範囲にレビューコメント" })
vim.keymap.set("n", "<leader>pl", "<Cmd>PiReviewList<CR>", { desc = "[Pi] コメント一覧" })
vim.keymap.set("n", "<leader>px", "<Cmd>PiReviewSubmit<CR>", { desc = "[Pi] レビュー提出" })

load_state()

return M