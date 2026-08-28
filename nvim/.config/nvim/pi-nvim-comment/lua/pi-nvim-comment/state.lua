-- pi-nvim-comment / state
-- 未提出コメント（record）の所有者。行位置は extmark で追跡し、state ファイルへ永続化する。
--
-- record = { id, bufnr, absolute_path, line, span, comment, root, reply_to? }
--   line = コメント開始行（extmarkが張れているあいだは line_of() が現在行を返す）
--   span = 範囲コメントの行数-1（0なら単一行）

local util = require("pi-nvim-comment.util")

local M = {}

local records = {}
local foreign_items = {} -- 現在のプロジェクト外のstate項目。触らず保存時にそのまま書き戻す
local next_id = 1

local ns_pos = vim.api.nvim_create_namespace("pi_comment_pos")
local pos_marks = {} -- record.id -> { buf = bufnr, mark = extmark_id }

-- --------------------------------------------------------------------------
-- extmarkによる行追跡
-- --------------------------------------------------------------------------
local function place_mark(record, bufnr)
	if not (vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)) then
		return false
	end
	local line = math.min(math.max(record.line, 1), vim.api.nvim_buf_line_count(bufnr))
	local ok, mark = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_pos, line - 1, 0, {})
	if not ok then
		return false
	end
	record.bufnr = bufnr
	pos_marks[record.id] = { buf = bufnr, mark = mark }
	return true
end

local function clear_mark(record)
	local mark = pos_marks[record.id]
	if mark and vim.api.nvim_buf_is_valid(mark.buf) then
		pcall(vim.api.nvim_buf_del_extmark, mark.buf, ns_pos, mark.mark)
	end
	pos_marks[record.id] = nil
end

--- コメントの現在行。マークが張れていなければ記録行にフォールバックする
function M.line_of(record)
	local mark = pos_marks[record.id]
	if mark and vim.api.nvim_buf_is_valid(mark.buf) then
		local pos = vim.api.nvim_buf_get_extmark_by_id(mark.buf, ns_pos, mark.mark, {})
		if pos and pos[1] ~= nil then
			return pos[1] + 1
		end
	end
	return record.line
end

--- コメントの現在の範囲（開始行, 終了行）
function M.range_of(record)
	local start_line = M.line_of(record)
	return start_line, start_line + (record.span or 0)
end

--- バッファがロードされたタイミングで、そのファイルのコメントにマークを張り直す。
--- state復元直後は対象バッファが未ロードでマークを張れないため、この再配置が追跡の起点になる
function M.attach_marks(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" or not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end
	local real = vim.uv.fs_realpath(name) or name
	for _, record in ipairs(records) do
		local existing = pos_marks[record.id]
		if not (existing and vim.api.nvim_buf_is_valid(existing.buf)) and record.absolute_path == real then
			place_mark(record, bufnr)
		end
	end
end

-- --------------------------------------------------------------------------
-- レコード操作
-- --------------------------------------------------------------------------
function M.list()
	return records
end

function M.count()
	return #records
end

function M.find(id)
	for _, record in ipairs(records) do
		if record.id == id then
			return record
		end
	end
	return nil
end

--- record を追加して保存する（idの採番とマーク配置はここが担当）
function M.add(fields)
	local record = vim.tbl_extend("force", fields, { id = next_id })
	next_id = next_id + 1
	record.span = record.span or 0
	records[#records + 1] = record
	place_mark(record, record.bufnr)
	M.save()
	return record
end

function M.remove(id)
	for index, record in ipairs(records) do
		if record.id == id then
			clear_mark(record)
			table.remove(records, index)
			M.save()
			return true
		end
	end
	return false
end

--- 提出済みのrecord群をまとめて取り除く
function M.remove_all(list)
	local ids = {}
	for _, record in ipairs(list) do
		clear_mark(record)
		ids[record.id] = true
	end
	for i = #records, 1, -1 do
		if ids[records[i].id] then
			table.remove(records, i)
		end
	end
	M.save()
end

function M.clear()
	for _, record in ipairs(records) do
		clear_mark(record)
	end
	records = {}
	M.save()
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

function M.save()
	local data = {}
	for _, record in ipairs(records) do
		data[#data + 1] = {
			id = record.id,
			absolute_path = record.absolute_path,
			-- 追跡中の現在行を保存する（記録時の行ではない。再起動で位置が巻き戻らないように）
			line = M.line_of(record),
			span = record.span or 0,
			comment = record.comment,
			root = record.root,
			reply_to = record.reply_to,
		}
	end
	for _, item in ipairs(foreign_items) do
		data[#data + 1] = item
	end
	local ok, encoded = pcall(vim.json.encode, data)
	if ok then
		pcall(vim.fn.writefile, { encoded }, state_file())
	end
end

local function is_valid(item)
	return type(item) == "table"
		and type(item.absolute_path) == "string"
		and type(item.comment) == "string"
		and type(item.line or item.start_line) == "number"
end

-- 保存項目 → record。旧形式（start_line/end_line）も読めるようにする
local function to_record(item, root)
	local line = math.max(1, math.floor(item.line or item.start_line))
	local span = item.span
	if type(span) ~= "number" then
		span = type(item.end_line) == "number" and math.max(0, math.floor(item.end_line) - line) or 0
	end
	return {
		id = type(item.id) == "number" and item.id or nil,
		bufnr = vim.fn.bufadd(item.absolute_path),
		absolute_path = item.absolute_path,
		line = line,
		span = span,
		comment = item.comment,
		root = root,
		reply_to = (type(item.reply_to) == "table" and type(item.reply_to.json) == "string") and item.reply_to or nil,
	}
end

--- state を読み、現在のプロジェクトのコメントだけ復元する。
--- 他プロジェクトの項目は foreign_items に退避し、保存時にそのまま書き戻す（stateは横断で1ファイル）
function M.load()
	local path = state_file()
	if vim.fn.filereadable(path) ~= 1 then
		return
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not (ok and lines and lines[1]) then
		return
	end
	local decode_ok, data = pcall(vim.json.decode, lines[1])
	if not decode_ok or type(data) ~= "table" then
		return
	end

	local root = util.project_root()
	for _, item in ipairs(data) do
		if is_valid(item) then
			local belongs
			if type(item.root) == "string" then
				belongs = item.root == root
			else
				-- 旧形式（rootなし）: パスが現在のプロジェクト配下なら引き取る
				belongs = util.relative_path(root, item.absolute_path) ~= nil
			end
			if belongs then
				local record = to_record(item, root)
				record.id = record.id or next_id
				records[#records + 1] = record
				if record.id >= next_id then
					next_id = record.id + 1
				end
				-- 復元直後のバッファは未ロードなのでここでは張れないことが多い。
				-- 実際の配置は BufReadPost からの attach_marks が行う
				place_mark(record, record.bufnr)
			else
				foreign_items[#foreign_items + 1] = item
			end
		end
	end
end

return M
