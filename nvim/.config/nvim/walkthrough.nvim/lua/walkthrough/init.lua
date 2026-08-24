-- walkthrough.nvim
-- コード上のポイント列（ステップ）を順に辿るUIプラグイン。
-- 公開APIとスキーマは README.md を参照。利用者との接点は setup(opts) と公開APIのみ。

local M = {}

-- --------------------------------------------------------------------------
-- 設定
-- --------------------------------------------------------------------------
local config = {
	-- pull型受け渡しの保存ディレクトリ名（対象リポジトリ直下からの相対）。
	-- 変更する場合はJSONを生成するスキル側の規約も合わせて変えること。
	dir = ".walkthroughs",
	-- true=デフォルトキーマップ / false=無効 / テーブル=個別上書き（false指定でそのキーだけ無効）
	keymaps = true,
}

local default_keymaps = {
	next = "]w",
	prev = "[w",
	steps = "<leader>wg",
	open = "<leader>wo",
	switch = "<leader>ww",
	toggle_float = "<leader>wt",
	focus_float = "<leader>w<CR>",
	close = "<leader>wq",
	reload = "<leader>wR",
}

-- --------------------------------------------------------------------------
-- 状態
-- --------------------------------------------------------------------------
local ns_marker = vim.api.nvim_create_namespace("walkthrough_marker")
local ns_values = vim.api.nvim_create_namespace("walkthrough_values")
local ns_float = vim.api.nvim_create_namespace("walkthrough_float")

vim.api.nvim_set_hl(0, "WalkthroughLocator", { link = "Title", default = true })
vim.api.nvim_set_hl(0, "WalkthroughSeparator", { link = "FloatBorder", default = true })

-- セッション: ロード済みwalkthrough 1本 + 現在位置
--   { name, steps, description?, commit?, root, json_path?, index }
-- 複数ロードできるが、描画されるのは active の1本だけ (ADR-0004)
local sessions = {}
local active = nil
local float_state = { win = nil, buf = nil }
local unnamed_count = 0

local function notify(message, level)
	vim.notify("Walkthrough: " .. message, level or vim.log.levels.INFO)
end

-- --------------------------------------------------------------------------
-- 描画（マーカー・変数値・noteフロート）
-- --------------------------------------------------------------------------
local function close_float()
	if float_state.win and vim.api.nvim_win_is_valid(float_state.win) then
		vim.api.nvim_win_close(float_state.win, true)
	end
	float_state.win = nil
	float_state.buf = nil
end

local function clear_marks()
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(b) then
			vim.api.nvim_buf_clear_namespace(b, ns_marker, 0, -1)
			vim.api.nvim_buf_clear_namespace(b, ns_values, 0, -1)
		end
	end
end

local function place_marker(bufnr, line, idx, total)
	local count = vim.api.nvim_buf_line_count(bufnr)
	if line < 1 or line > count then
		notify(
			string.format("ステップ%dの行%dが範囲外です（ファイルは%d行）", idx, line, count),
			vim.log.levels.WARN
		)
		return
	end
	pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_marker, line - 1, 0, {
		sign_text = "▶ ",
		sign_hl_group = "DiagnosticHint",
		line_hl_group = "Visual",
		virt_text = { { string.format("  ● step %d/%d", idx, total), "Comment" } },
		virt_text_pos = "eol",
	})
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
		notify("valuesをスキップ: " .. table.concat(skipped, ", "), vim.log.levels.WARN)
	end
end

local function wrap_line(line, max_width)
	if line == "" or vim.fn.strdisplaywidth(line) <= max_width then
		return { line }
	end
	local out = {}
	local current = ""
	local function flush()
		if current ~= "" then
			table.insert(out, current)
			current = ""
		end
	end
	local function push_word(word)
		local candidate = current == "" and word or (current .. " " .. word)
		if vim.fn.strdisplaywidth(candidate) <= max_width then
			current = candidate
			return
		end
		flush()
		if vim.fn.strdisplaywidth(word) <= max_width then
			current = word
			return
		end
		local chunk = ""
		for ch in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			if vim.fn.strdisplaywidth(chunk .. ch) > max_width then
				table.insert(out, chunk)
				chunk = ch
			else
				chunk = chunk .. ch
			end
		end
		current = chunk
	end
	for word in line:gmatch("%S+") do
		push_word(word)
	end
	flush()
	if #out == 0 then
		table.insert(out, "")
	end
	return out
end

local function show_float(session)
	close_float()

	local step = session.steps[session.index]
	local locator =
		string.format("  ▎ %s · %d/%d   %s:%d", session.name, session.index, #session.steps, step.file, step.line)

	local max_width = math.max(20, math.floor(vim.o.columns * 0.7) - 2)
	local lines = {}
	for _, sub in ipairs(wrap_line(locator, max_width)) do
		table.insert(lines, sub)
	end
	local locator_lines = #lines

	local sep_width = 0
	for _, l in ipairs(lines) do
		sep_width = math.max(sep_width, vim.fn.strdisplaywidth(l))
	end
	table.insert(lines, string.rep("━", math.min(sep_width, max_width)))
	local sep_line = #lines

	local note_raw = {}
	for line in (step.note or ""):gmatch("([^\n]*)\n?") do
		if line ~= "" or #note_raw > 0 then
			table.insert(note_raw, line)
		end
	end
	if #note_raw > 0 and note_raw[#note_raw] == "" then
		table.remove(note_raw)
	end
	for _, l in ipairs(note_raw) do
		for _, sub in ipairs(wrap_line(l, max_width)) do
			table.insert(lines, sub)
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"

	for i = 0, locator_lines - 1 do
		pcall(vim.api.nvim_buf_set_extmark, buf, ns_float, i, 0, { line_hl_group = "WalkthroughLocator" })
	end
	pcall(vim.api.nvim_buf_set_extmark, buf, ns_float, sep_line - 1, 0, { line_hl_group = "WalkthroughSeparator" })

	local width = 0
	for _, l in ipairs(lines) do
		if vim.fn.strdisplaywidth(l) > width then
			width = vim.fn.strdisplaywidth(l)
		end
	end
	width = math.min(width + 2, math.floor(vim.o.columns * 0.7))
	local max_height = math.max(5, math.floor(vim.o.lines * 0.7))
	local height = math.min(#lines, max_height)

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = vim.o.columns - 1,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		focusable = true,
		noautocmd = true,
	})
	vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

	vim.keymap.set("n", "q", function()
		pcall(vim.cmd, "wincmd p")
	end, { buffer = buf, nowait = true, silent = true, desc = "[Walkthrough] フロートを離れる" })

	float_state.win = win
	float_state.buf = buf
end

-- --------------------------------------------------------------------------
-- ジャンプ
-- --------------------------------------------------------------------------
local function resolve_path(session, file)
	if session.root then
		local p = session.root .. "/" .. file
		if vim.fn.filereadable(p) == 1 then
			return p
		end
	end
	if vim.fn.filereadable(file) == 1 then
		return vim.fn.fnamemodify(file, ":p")
	end
	return nil
end

local function jump_to(session, idx)
	if idx < 1 or idx > #session.steps then
		notify(string.format("範囲外です (1..%d)", #session.steps), vim.log.levels.WARN)
		return
	end

	local step = session.steps[idx]
	if type(step.file) ~= "string" or step.file == "" then
		notify(string.format("ステップ%dにfileがありません", idx), vim.log.levels.ERROR)
		return
	end
	local path = resolve_path(session, step.file)
	if not path then
		notify(
			string.format("ステップ%dのファイルが見つかりません: %s (root: %s)", idx, step.file, session.root or "?"),
			vim.log.levels.ERROR
		)
		return
	end

	session.index = idx

	local existing = vim.fn.bufnr(path)
	if existing ~= -1 and vim.api.nvim_buf_is_loaded(existing) then
		vim.api.nvim_set_current_buf(existing)
	else
		local ok, err = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(path))
		if not ok then
			notify("編集エラー（続行します）: " .. tostring(err), vim.log.levels.WARN)
		end
	end

	local line = math.max(1, step.line or 1)
	pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
	pcall(vim.cmd, "normal! zz")

	clear_marks()
	local bufnr = vim.api.nvim_get_current_buf()
	place_marker(bufnr, line, idx, #session.steps)
	place_values(bufnr, step)

	show_float(session)
end

-- --------------------------------------------------------------------------
-- セッション管理
-- --------------------------------------------------------------------------
local function repo_root(dir)
	local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error == 0 and out[1] and #out[1] > 0 then
		return out[1]
	end
	return nil
end

local function activate(session)
	active = session
	jump_to(session, session.index)
end

-- JSONファイルを読み、start() へ渡せるspecへ変換する
local function load_json(json_path)
	json_path = vim.fn.fnamemodify(json_path, ":p")
	local f = io.open(json_path, "r")
	if not f then
		notify("読み込めません: " .. json_path, vim.log.levels.ERROR)
		return nil
	end
	local content = f:read("*a")
	f:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok then
		notify("不正なJSONです: " .. tostring(data), vim.log.levels.ERROR)
		return nil
	end
	if type(data) ~= "table" or type(data.steps) ~= "table" or #data.steps == 0 then
		notify("stepsがありません: " .. json_path, vim.log.levels.ERROR)
		return nil
	end

	return {
		name = vim.fn.fnamemodify(json_path, ":t:r"),
		steps = data.steps,
		description = data.description,
		commit = data.commit,
		root = repo_root(vim.fn.fnamemodify(json_path, ":h")) or vim.fn.fnamemodify(json_path, ":h"),
		json_path = json_path,
	}
end

-- --------------------------------------------------------------------------
-- 公開API
-- --------------------------------------------------------------------------

--- コアAPI: メモリ上のステップ列からセッションを作成しアクティブ化する (ADR-0002)
--- spec: { steps (必須), name?, root?, description?, commit?, json_path?, index? }
--- 同名セッションが既にあれば置き換える。
function M.start(spec)
	if type(spec) ~= "table" or type(spec.steps) ~= "table" or #spec.steps == 0 then
		notify("start()にはstepsの配列が必要です", vim.log.levels.ERROR)
		return
	end
	for i, step in ipairs(spec.steps) do
		if type(step) ~= "table" or type(step.file) ~= "string" or type(step.line) ~= "number" then
			notify(string.format("ステップ%dが不正です（file/lineが必要）", i), vim.log.levels.ERROR)
			return
		end
	end

	local name = spec.name
	if not name or name == "" then
		unnamed_count = unnamed_count + 1
		name = "walkthrough-" .. unnamed_count
	end

	local session = {
		name = name,
		steps = spec.steps,
		description = spec.description,
		commit = spec.commit,
		root = spec.root or repo_root(vim.uv.cwd()) or vim.uv.cwd(),
		json_path = spec.json_path,
		index = math.max(1, math.min(spec.index or 1, #spec.steps)),
	}

	local replaced = false
	for i, s in ipairs(sessions) do
		if s.name == name then
			sessions[i] = session
			replaced = true
			break
		end
	end
	if not replaced then
		sessions[#sessions + 1] = session
	end

	activate(session)
end

--- JSONラッパー: ファイルを読んで start() する
function M.start_file(json_path)
	local spec = load_json(json_path)
	if spec then
		M.start(spec)
	end
end

function M.next()
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end
	jump_to(active, active.index + 1)
end

function M.prev()
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end
	jump_to(active, active.index - 1)
end

function M.goto_step(idx)
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end
	jump_to(active, idx)
end

-- プレビュー用テキスト: note全文 + values
local function step_preview_text(step)
	local parts = { string.format("`%s:%d`", step.file, step.line), "", step.note or "" }
	if type(step.values) == "table" and #step.values > 0 then
		parts[#parts + 1] = ""
		parts[#parts + 1] = "**values**"
		for _, v in ipairs(step.values) do
			parts[#parts + 1] = string.format("- `%s = %s` (L%s)", v.name or "?", tostring(v.value), v.line or "?")
		end
	end
	return table.concat(parts, "\n")
end

--- アクティブセッションのステップ一覧から選んでジャンプする
--- snacksがあればnoteプレビュー付きpicker、なければvim.ui.select
function M.steps()
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end

	local items = {}
	for i, step in ipairs(active.steps) do
		local marker = i == active.index and "●" or " "
		local summary = (step.note or ""):gsub("%s+", " ")
		if vim.fn.strchars(summary) > 60 then
			summary = vim.fn.strcharpart(summary, 0, 60) .. "…"
		end
		items[#items + 1] = {
			idx = i,
			text = string.format("%s %d  %s:%d  %s", marker, i, step.file, step.line, summary),
			preview = { text = step_preview_text(step), ft = "markdown", loc = false },
		}
	end

	local ok, snacks = pcall(require, "snacks")
	if ok and snacks.picker then
		snacks.picker.pick({
			title = "Walkthrough: " .. active.name,
			items = items,
			format = "text",
			preview = "preview",
			confirm = function(picker, item)
				picker:close()
				if item then
					vim.schedule(function()
						jump_to(active, item.idx)
					end)
				end
			end,
		})
		return
	end

	vim.ui.select(items, {
		prompt = "ステップ一覧: " .. active.name,
		format_item = function(item)
			return item.text
		end,
	}, function(choice)
		if choice then
			jump_to(active, choice.idx)
		end
	end)
end

--- 保存ディレクトリ（<git root>/config.dir）のJSONをmtime降順で選んで開く (ADR-0005)
function M.open()
	local root = repo_root(vim.uv.cwd()) or vim.uv.cwd()
	local dir = root .. "/" .. config.dir
	local files = vim.fn.glob(dir .. "/*.json", false, true)
	if #files == 0 then
		notify("walkthroughがありません: " .. dir, vim.log.levels.WARN)
		return
	end

	table.sort(files, function(a, b)
		local sa = vim.uv.fs_stat(a)
		local sb = vim.uv.fs_stat(b)
		return (sa and sa.mtime.sec or 0) > (sb and sb.mtime.sec or 0)
	end)

	vim.ui.select(files, {
		prompt = "Walkthroughを開く",
		format_item = function(path)
			local stat = vim.uv.fs_stat(path)
			local mtime = stat and os.date("%m/%d %H:%M", stat.mtime.sec) or "?"
			return string.format("%s  (%s)", vim.fn.fnamemodify(path, ":t:r"), mtime)
		end,
	}, function(choice)
		if choice then
			M.start_file(choice)
		end
	end)
end

--- セッション切り替え。各セッションの現在位置は保持され、選択で即ジャンプする (ADR-0004)
function M.switch()
	if #sessions == 0 then
		notify("セッションがありません", vim.log.levels.WARN)
		return
	end

	vim.ui.select(sessions, {
		prompt = "セッション切り替え",
		format_item = function(s)
			local marker = s == active and "● " or "  "
			return string.format("%s%s  [%d/%d]", marker, s.name, s.index, #s.steps)
		end,
	}, function(choice)
		if choice then
			activate(choice)
		end
	end)
end

--- アクティブセッションを閉じる（レジストリから除去し描画をクリア）
function M.close()
	if not active then
		close_float()
		clear_marks()
		return
	end
	for i, s in ipairs(sessions) do
		if s == active then
			table.remove(sessions, i)
			break
		end
	end
	local name = active.name
	active = nil
	close_float()
	clear_marks()
	notify(("セッションを閉じました: %s（残り%d）"):format(name, #sessions))
end

--- アクティブセッションのJSONを再読み込み（現在位置は維持、範囲外ならクランプ）
function M.reload()
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end
	if not active.json_path then
		notify("このセッションはファイル由来ではないため再読み込みできません", vim.log.levels.WARN)
		return
	end
	local spec = load_json(active.json_path)
	if not spec then
		return
	end
	spec.name = active.name
	spec.index = active.index
	M.start(spec)
end

function M.toggle_float()
	if float_state.win and vim.api.nvim_win_is_valid(float_state.win) then
		close_float()
		return
	end
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
		return
	end
	show_float(active)
end

function M.focus_float()
	if not (float_state.win and vim.api.nvim_win_is_valid(float_state.win)) then
		if not active then
			notify("walkthroughがロードされていません", vim.log.levels.WARN)
			return
		end
		show_float(active)
	end
	if float_state.win and vim.api.nvim_win_is_valid(float_state.win) then
		vim.api.nvim_set_current_win(float_state.win)
	end
end

function M.status()
	if not active then
		notify("walkthroughがロードされていません", vim.log.levels.INFO)
		return
	end
	notify(
		string.format(
			"%s [%d/%d] @ %s",
			active.name,
			active.index,
			#active.steps,
			active.commit or "unknown commit"
		)
	)
end

--- テスト・連携用の読み取り専用スナップショット
function M.get_state()
	local list = {}
	for _, s in ipairs(sessions) do
		list[#list + 1] = { name = s.name, index = s.index, total = #s.steps, active = s == active }
	end
	return list
end

-- --------------------------------------------------------------------------
-- setup
-- --------------------------------------------------------------------------
local function apply_keymaps(keys)
	local function map(lhs, rhs, desc)
		if lhs then
			vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
		end
	end
	map(keys.next, M.next, "[Walkthrough] 次のステップ")
	map(keys.prev, M.prev, "[Walkthrough] 前のステップ")
	map(keys.steps, M.steps, "[Walkthrough] ステップ一覧から選んでジャンプ")
	map(keys.open, M.open, "[Walkthrough] walkthroughを開く")
	map(keys.switch, M.switch, "[Walkthrough] セッション切り替え")
	map(keys.toggle_float, M.toggle_float, "[Walkthrough] noteフロート表示/非表示")
	map(keys.focus_float, M.focus_float, "[Walkthrough] noteフロートにフォーカス")
	map(keys.close, M.close, "[Walkthrough] セッションを閉じる")
	map(keys.reload, M.reload, "[Walkthrough] JSONを再読み込み")
end

function M.setup(opts)
	opts = opts or {}
	if opts.dir ~= nil then
		config.dir = opts.dir
	end
	if opts.keymaps ~= nil then
		config.keymaps = opts.keymaps
	end

	if config.keymaps ~= false then
		local keys = vim.tbl_extend("force", {}, default_keymaps)
		if type(config.keymaps) == "table" then
			for k, v in pairs(config.keymaps) do
				keys[k] = v ~= false and v or nil
			end
		end
		apply_keymaps(keys)
	end

	vim.api.nvim_create_user_command("Walkthrough", function(args)
		if args.args ~= "" then
			M.start_file(args.args)
		else
			M.open()
		end
	end, { nargs = "?", complete = "file", desc = "[Walkthrough] JSONを指定して開く（無指定はpicker）" })
end

return M
