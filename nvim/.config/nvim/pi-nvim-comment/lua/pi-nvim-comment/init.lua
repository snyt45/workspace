-- pi-nvim-comment
-- 実行中のpiセッションへの行コメントレビュー + walkthrough連携。
-- 公開API・キーマップ・設定は README.md 参照。
-- carderne/pi-nvim の自動発見(get_socket_path)と送信(send_raw)を再利用する:
--   pi を起動すると拡張が自動でソケットを開き、nvim は cwd 一致セッションを掴む。

local M = {}
local records = {}
local foreign_items = {} -- 現在のプロジェクト外のstate項目。触らず保存時にそのまま書き戻す
local next_id = 1
local submitting = false
local active_modal
local save_state -- 前方宣言（clear_records 等が先に定義されているため）
local sync_walkthrough -- 前方宣言（edit_comment を参照するため後方で定義）
local submit_records -- 前方宣言（annotate の即送信が参照するため後方で定義）
-- 環境固有の指示はプラグインに埋め込まず setup の opts で注入する
local prompt_suffix -- opts.prompt_suffix: 提出プロンプトの指示文の後に付記する文
local instructions -- opts.instructions: 指示文の差し替え（省略時は DEFAULT_INSTRUCTIONS）

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

local function notify(message, level)
	vim.notify("pi-nvim-comment: " .. message, level or vim.log.levels.INFO)
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

-- --------------------------------------------------------------------------
-- コメント入力モーダル（多行エディタ）
-- --------------------------------------------------------------------------
-- action: "save"=未提出リストへ / "send"=この1件だけ即送信（キャンセル時は value=nil）
local function modal_finish(value, action)
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
		current.callback(value, action)
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
		footer = " <C-s> 保存 · <C-x> 即送信 · <Esc> キャンセル ",
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

	local function finish(action)
		if not vim.api.nvim_buf_is_valid(buf) then
			modal_finish(nil)
			return
		end
		modal_finish(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"), action)
	end
	local function cancel()
		modal_finish(nil)
	end
	local map = { buffer = buf, silent = true, nowait = true }
	vim.keymap.set({ "n", "i" }, "<C-s>", function()
		finish("save")
	end, map)
	vim.keymap.set({ "n", "i" }, "<C-x>", function()
		finish("send")
	end, map)
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

	local root = project_root()
	local path = relative_path(root, absolute)
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
	comment_modal(string.format("Piコメント · %s:%s", path, location), nil, function(comment, action)
		if comment == nil then
			return
		end
		comment = validate_comment(comment)
		if not comment then
			return
		end

		-- 行は追加時点で固定（extmark追跡なし）。バッファ編集でずれたら ,pa し直す
		local record = {
			id = next_id,
			bufnr = bufnr,
			absolute_path = absolute,
			start_line = first_line,
			end_line = last_line,
			comment = comment,
			root = root,
		}
		records[#records + 1] = record
		next_id = next_id + 1
		save_state()
		sync_walkthrough()
		if action == "send" then
			-- 即送信でも先にrecord化しておく: 送信失敗時は未提出コメントとして残る
			submit_records({ record }, "コメント%d件をpiへ即送信しました")
		else
			notify(("コメントを追加: %s:%s（切替: ,wo / 巡回: ]w）"):format(path, location))
		end
	end)
end

-- --------------------------------------------------------------------------
-- ペイロード・メッセージ構築
-- --------------------------------------------------------------------------
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

local function build_payload(root, list)
	local resolved = {}
	for _, record in ipairs(list) do
		local path = relative_path(root, record.absolute_path)
		if not path then
			return nil, "Piプロジェクトの外にあるコメントを中断しました: " .. record.absolute_path
		end
		local start_line, end_line = record.start_line, record.end_line
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
			reply = record.reply_to,
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

local function format_review_prompt(root, payload)
	local parts = {}
	local text = instructions or DEFAULT_INSTRUCTIONS
	if text ~= "" then
		parts[#parts + 1] = text
		parts[#parts + 1] = ""
	end
	if prompt_suffix and prompt_suffix ~= "" then
		parts[#parts + 1] = prompt_suffix
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
		if annotation.reply then
			local json_path = relative_path(root, annotation.reply.json) or annotation.reply.json
			parts[#parts + 1] = string.format(
				"Reply to walkthrough thread: %s (step %d)",
				vim.json.encode(json_path),
				annotation.reply.step
			)
			if annotation.reply.context and annotation.reply.context ~= "" then
				parts[#parts + 1] = ""
				parts[#parts + 1] = "Thread so far:"
				for _, line in ipairs(split_lines(annotation.reply.context)) do
					parts[#parts + 1] = "> " .. line
				end
			end
		end
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

	return (table.concat(parts, "\n"):gsub("%s+$", ""))
end

-- --------------------------------------------------------------------------
-- 提出・破棄
-- --------------------------------------------------------------------------
local function clear_records()
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
	-- ファイル名は旧pi_review時代のまま（リネーム跨ぎで未提出コメントを保持するため）
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
			root = record.root,
			reply_to = record.reply_to,
		}
	end
	for _, item in ipairs(foreign_items) do
		data[#data + 1] = item
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
	-- stateはプロジェクト横断で1ファイルのため、現在のプロジェクトの項目だけ復元する。
	-- 他プロジェクトの項目は foreign_items に退避し、保存時にそのまま書き戻す
	local root = project_root()
	for _, item in ipairs(data) do
		if type(item) == "table"
			and type(item.absolute_path) == "string"
			and type(item.comment) == "string"
			and type(item.start_line) == "number"
			then
			local belongs
			if type(item.root) == "string" then
				belongs = item.root == root
			else
				-- 旧形式（rootなし）: パスが現在のプロジェクト配下なら引き取る
				belongs = relative_path(root, item.absolute_path) ~= nil
			end
			if belongs then
				local start_line = math.max(1, math.floor(item.start_line))
				local end_line = type(item.end_line) == "number" and math.floor(item.end_line) or start_line
				local record = {
					id = type(item.id) == "number" and item.id or next_id,
					bufnr = vim.fn.bufadd(item.absolute_path),
					absolute_path = item.absolute_path,
					start_line = start_line,
					end_line = math.max(start_line, end_line),
					comment = item.comment,
					root = root,
					reply_to = (type(item.reply_to) == "table" and type(item.reply_to.json) == "string")
							and item.reply_to
						or nil,
				}
				records[#records + 1] = record
				if record.id >= next_id then
					next_id = record.id + 1
				end
			else
				foreign_items[#foreign_items + 1] = item
			end
		end
	end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		save_state()
	end,
})

-- 提出内容（指示文 + コメント一覧）を組み立てる。submit と copy で共用
local function build_message(list)
	local root = project_root()
	local payload, payload_error = build_payload(root, list)
	if not payload then
		return nil, nil, nil, payload_error
	end
	return root, payload, format_review_prompt(root, payload), nil
end

-- 指定したrecord群だけを提出する。成功時はそのrecordだけをリストから外す（他の未提出は残る）
-- label: 成功通知のformat文字列（%d=件数）
-- 前方宣言と同じスコープのため代入で定義する（save_state と同パターン）
submit_records = function(list, label)
	if submitting then
		notify("送信処理が進行中です", vim.log.levels.WARN)
		return
	end
	if #list == 0 then
		notify("提出するコメントがありません", vim.log.levels.WARN)
		return
	end
	if not socket_path() then
		notify("piセッションが見つかりません（piを起動してください）", vim.log.levels.WARN)
		return
	end

	local _, payload, message, build_error = build_message(list)
	if not payload then
		notify(build_error, vim.log.levels.ERROR)
		return
	end

	submitting = true
	pi_nvim().send_raw({ type = "prompt", message = message }, function(err, response)
		submitting = false
		if err or not response or not response.ok then
			notify((err or "piがレビューを受け付けませんでした") .. "; コメントは保持されました", vim.log.levels.ERROR)
			return
		end

		local sent = {}
		for _, record in ipairs(list) do
			sent[record.id] = true
		end
		for i = #records, 1, -1 do
			if sent[records[i].id] then
				table.remove(records, i)
			end
		end
		save_state()
		sync_walkthrough()
		notify(label:format(#payload))
	end)
end

function M.submit()
	submit_records(records, "%dコメントをpiに提出しました")
end

--- 提出内容（指示文 + コメント一覧）をクリップボードにコピーする。piセッションは不要
function M.copy()
	if #records == 0 then
		notify("コピーするコメントがありません", vim.log.levels.WARN)
		return
	end

	local _, payload, message, build_error = build_message(records)
	if not payload then
		notify(build_error, vim.log.levels.ERROR)
		return
	end

	vim.fn.setreg("+", message) -- システムクリップボード
	-- vim.notify 経由なので noice（noise）導入時はそのUIに通知として表示される
	notify(("%dコメント分の提出内容をクリップボードにコピーしました"):format(#payload))
end

function M.clear()
	if #records == 0 then
		notify("破棄するコメントはありません")
		return
	end
	local count = #records
	clear_records()
	sync_walkthrough()
	notify(("%dコメントを破棄しました"):format(count))
end

-- --------------------------------------------------------------------------
-- 一覧・編集・削除・ジャンプ
-- --------------------------------------------------------------------------
--- コメントを編集中のモーダルを開く
local function edit_comment(record)
	if not record then
		notify("コメントが見つかりません（既に削除された可能性）", vim.log.levels.WARN)
		return
	end

	local path = relative_path(project_root(), record.absolute_path) or record.absolute_path
	local start_line, end_line = record.start_line, record.end_line
	local location = start_line == end_line and tostring(start_line) or string.format("%d-%d", start_line, end_line)

	comment_modal(string.format("Piコメント編集 · %s:%s", path, location), record.comment, function(text, action)
		if text == nil then
			return
		end
		text = validate_comment(text)
		if not text then
			return
		end

		record.comment = text
		save_state()
		sync_walkthrough()
		if action == "send" then
			submit_records({ record }, "コメント%d件をpiへ即送信しました")
		else
			notify(("コメントを編集: %s:%s"):format(path, location))
		end
	end)
end

--- walkthroughのthread付きステップへの返信（walkthrough.nvimの set_reply_handler 経由で呼ばれる）
--- 返信は「そのステップと同じ行に付いた未提出コメント」になり、reply_to にスレッド参照を持つ
function M.reply(session, idx)
	local step = session.steps and session.steps[idx]
	if not step then
		return
	end
	if not session.json_path then
		notify("このセッションはファイル由来ではないため返信できません", vim.log.levels.WARN)
		return
	end
	local absolute = session.root and (session.root .. "/" .. step.file) or step.file
	absolute = vim.uv.fs_realpath(absolute)
	if not absolute then
		notify("返信先のファイルが見つかりません: " .. tostring(step.file), vim.log.levels.WARN)
		return
	end

	-- スレッド履歴のスナップショット（提出プロンプトの Thread so far に使う）
	local context_lines = {}
	for _, entry in ipairs(step.thread or {}) do
		for i, line in ipairs(split_lines(entry.text or "")) do
			context_lines[#context_lines + 1] = (i == 1 and ("[" .. tostring(entry.author or "?") .. "] ") or "")
				.. line
		end
	end

	local root = project_root()
	local path = relative_path(root, absolute) or step.file
	comment_modal(string.format("Pi返信 · %s:%d", path, step.line), nil, function(comment, action)
		if comment == nil then
			return
		end
		comment = validate_comment(comment)
		if not comment then
			return
		end

		local record = {
			id = next_id,
			bufnr = vim.fn.bufadd(absolute),
			absolute_path = absolute,
			start_line = step.line,
			end_line = step.line,
			comment = comment,
			root = root,
			reply_to = {
				json = session.json_path,
				step = idx,
				context = table.concat(context_lines, "\n"),
			},
		}
		records[#records + 1] = record
		next_id = next_id + 1
		save_state()
		sync_walkthrough()
		if action == "send" then
			submit_records({ record }, "返信%d件をpiへ即送信しました（回答が返ったら ,wR）")
		else
			notify(("返信を追加: %s:%d（,pxで提出）"):format(path, step.line))
		end
	end)
end

--- コメントを1件削除
local function remove_comment(id)
	for index, record in ipairs(records) do
		if record.id == id then
			table.remove(records, index)
			save_state()
			sync_walkthrough()
			return true
		end
	end
	return false
end

-- --------------------------------------------------------------------------
-- walkthrough連携: 未提出コメントは「pi-comments」セッションとして常に同期し、
-- コード上の表示はwalkthrough.nvimのUIに一本化する（claim: 表示・移動・フォーカス・編集フック）
-- --------------------------------------------------------------------------
-- walkthroughのステップ（id）から対応するrecordを引く
local function find_by_step(session, idx)
	local step = session.steps[idx]
	if not step then
		return nil
	end
	for _, record in ipairs(records) do
		if record.id == step.id then
			return record
		end
	end
	return nil
end

--- コメント追加/編集/削除のたびに呼ぶ。0件ならセッションを閉じる
-- 前方宣言と同じスコープのため `local function` ではなく代入で定義する（save_state と同パターン）
sync_walkthrough = function()
	local ok, wt = pcall(require, "walkthrough")
	if not ok then
		return
	end

	local root = project_root()
	if #records == 0 then
		wt.remove("pi-comments")
		return
	end

	local steps = {}
	for _, record in ipairs(records) do
		local path = relative_path(root, record.absolute_path) or record.absolute_path
		local start_line, end_line = record.start_line, record.end_line
		local note = record.comment
		if end_line > start_line then
			note = string.format("対象: L%d-%d\n\n%s", start_line, end_line, note)
		end
		if record.reply_to then
			note = string.format(
				"↩ %s · step %d への返信\n\n%s",
				vim.fn.fnamemodify(record.reply_to.json, ":t:r"),
				record.reply_to.step,
				note
			)
		end
		steps[#steps + 1] = { file = path, line = start_line, note = note, id = record.id }
	end
	table.sort(steps, function(a, b)
		if a.file ~= b.file then
			return a.file < b.file
		end
		if a.line ~= b.line then
			return a.line < b.line
		end
		return a.id < b.id
	end)

	-- フロート内キー（e/d）と、,we（カーソル下編集）用の意味的キー（edit/delete）で同じアクションを共有
	local edit_hook = function(session, idx)
		local record = find_by_step(session, idx)
		if record then
			vim.schedule(function()
				edit_comment(record)
			end)
		end
	end
	local delete_hook = function(session, idx)
		local record = find_by_step(session, idx)
		if record and remove_comment(record.id) then
			notify("コメントを削除しました")
		end
	end
	wt.update({
		name = "pi-comments",
		steps = steps,
		root = root,
		-- 非アクティブでもマークを常時表示し、,wqで消えない（コメントは打てば常に見える）
		pin = true,
		-- walkthrough の表示名「step」を pi-comment の文脈では「comment」にする
		step_label = "comment",
		-- フロートにフォーカス中のキー: e=編集モーダル（入力UIは comment_modal と同じ） / d=コメント削除
		hooks = {
			e = edit_hook,
			d = delete_hook,
			edit = edit_hook,
			delete = delete_hook,
		},
	})
end

-- --------------------------------------------------------------------------
-- setup
-- --------------------------------------------------------------------------
local default_keymaps = {
	-- 提出は <leader>px（,ps は他プラグイン使用済みのため）
	-- 表示系のキーは持たない: 見る・切替・巡回はすべてwalkthrough側（,wo / ]w 等）
	annotate = "<leader>pa",
	submit = "<leader>px",
	-- 提出内容のコピーは <leader>py（,pc は他プラグイン使用済みのため yank の y）
	copy = "<leader>py",
}

local did_setup = false

function M.setup(opts)
	if did_setup then
		return
	end
	did_setup = true
	opts = opts or {}

	if type(opts.prompt_suffix) == "string" then
		prompt_suffix = opts.prompt_suffix
	end
	if type(opts.instructions) == "string" then
		instructions = opts.instructions
	end

	vim.api.nvim_create_user_command("PiReviewAnnotate", function(args)
		M.annotate(args.line1, args.line2)
	end, { range = true, desc = "Piレビュー: 行/範囲にコメント追加" })

	vim.api.nvim_create_user_command("PiReviewSubmit", function()
		M.submit()
	end, { desc = "Piレビュー: コメント提出" })

	vim.api.nvim_create_user_command("PiReviewClear", function()
		M.clear()
	end, { desc = "Piレビュー: 未提出コメント破棄" })

	vim.api.nvim_create_user_command("PiReviewCopy", function()
		M.copy()
	end, { desc = "Piレビュー: 提出内容をクリップボードにコピー" })

	if opts.keymaps ~= false then
		local keys = vim.tbl_extend("force", {}, default_keymaps)
		if type(opts.keymaps) == "table" then
			for k, v in pairs(opts.keymaps) do
				keys[k] = v ~= false and v or nil
			end
		end
		if keys.annotate then
			vim.keymap.set("n", keys.annotate, "<Cmd>PiReviewAnnotate<CR>", { desc = "[Pi] 行にレビューコメント" })
			vim.keymap.set("x", keys.annotate, ":<C-U>'<,'>PiReviewAnnotate<CR>", { desc = "[Pi] 選択範囲にレビューコメント" })
		end
		if keys.submit then
			vim.keymap.set("n", keys.submit, "<Cmd>PiReviewSubmit<CR>", { desc = "[Pi] レビュー提出" })
		end
		if keys.copy then
			vim.keymap.set("n", keys.copy, "<Cmd>PiReviewCopy<CR>", { desc = "[Pi] 提出内容をクリップボードにコピー" })
		end
	end

	load_state()
	sync_walkthrough()

	-- thread付きステップのフロートで r=返信 を有効にする
	local ok, wt = pcall(require, "walkthrough")
	if ok and type(wt.set_reply_handler) == "function" then
		wt.set_reply_handler(function(session, idx)
			M.reply(session, idx)
		end)
	end
end

return M