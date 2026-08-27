-- walkthrough.nvim
-- コード上のポイント列（ステップ）を順に辿るUIプラグイン。
-- 公開APIとスキーマは README.md を参照。利用者との接点は setup(opts) と公開APIのみ。

local M = {}

-- --------------------------------------------------------------------------
-- 設定
-- --------------------------------------------------------------------------
local config = {
	-- スキルが生成したJSONの保存ディレクトリ名（対象リポジトリ直下からの相対）。<leader>wo で開く。
	-- 変更する場合はJSONを生成するスキル側の規約も合わせて変えること。
	dir = ".walkthroughs",
	-- true=デフォルトキーマップ / false=無効 / テーブル=個別上書き（false指定でそのキーだけ無効）
	keymaps = true,
}

local default_keymaps = {
	next = "]w",
	prev = "[w",
	steps = "<leader>wl",
	open = "<leader>wo",
	toggle_float = "<leader>wt",
	focus_float = "<leader>w<CR>",
	close = "<leader>wq",
	edit_at_cursor = "<leader>we",
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
vim.api.nvim_set_hl(0, "WalkthroughAuthor", { link = "Identifier", default = true })

-- セッション: ロード済みwalkthrough 1本 + 現在位置
--   { name, steps, description?, commit?, root, json_path?, index }
-- 複数ロードできるが、描画されるのは active の1本だけ
local sessions = {}
local active = nil
-- noteフロート（常に1枚）。表示中のステップを覚えてトグル判定に使う
local float_state = { win = nil, session = nil, idx = nil }
local unnamed_count = 0
-- thread付きステップのフロートで r を押したときの返信ハンドラ（連携プラグインが登録）
local reply_handler = nil

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
	float_state.session = nil
	float_state.idx = nil
end

local function has_float()
	return float_state.win ~= nil and vim.api.nvim_win_is_valid(float_state.win)
end


local function place_marker(bufnr, line, idx, total, is_active, label)
	label = label or "step"
	local count = vim.api.nvim_buf_line_count(bufnr)
	if line < 1 or line > count then
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

local function has_thread(step)
	return type(step.thread) == "table" and #step.thread > 0
end

-- ステップ1枚分の描画行を組み立てる（ウィンドウは開かない）
-- 戻り値: lines, marks（{row, group} の配列。行ハイライト用）
local function note_layout(session, idx, max_width)
	local step = session.steps[idx]
	local marker = idx == session.index and "●" or "▎"
	local locator =
		string.format("  %s %s · %d/%d   %s:%d", marker, session.name, idx, #session.steps, step.file, step.line)
	if has_thread(step) then
		locator = locator .. string.format("   💬 %d", #step.thread)
	end

	local lines = {}
	local marks = {}
	local seps = {} -- 区切り行の位置と文字。内容幅が確定してからまとめて引き直す

	for _, sub in ipairs(wrap_line(locator, max_width)) do
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
			for _, sub in ipairs(wrap_line(l, max_width)) do
				lines[#lines + 1] = sub
			end
		end
	end

	if has_thread(step) then
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

	local content = 0
	for _, l in ipairs(lines) do
		content = math.max(content, vim.fn.strdisplaywidth(l))
	end
	content = math.min(math.max(content, 1), max_width)
	for _, sep in ipairs(seps) do
		lines[sep.row] = string.rep(sep.char, content)
	end

	return lines, marks
end

-- 指定ステップのnoteフロートを右上に開く（既存のフロートは閉じる）
local function show_note_float(session, idx)
	close_float()
	local max_width = math.max(20, math.floor(vim.o.columns * 0.7) - 2)
	local lines, marks = note_layout(session, idx, max_width)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"

	for _, m in ipairs(marks) do
		pcall(vim.api.nvim_buf_set_extmark, buf, ns_float, m.row - 1, 0, { line_hl_group = m.group })
	end

	local content = 0
	for _, l in ipairs(lines) do
		if vim.fn.strdisplaywidth(l) > content then
			content = vim.fn.strdisplaywidth(l)
		end
	end
	local width = math.min(content + 2, math.floor(vim.o.columns * 0.7))
	local height = math.min(#lines, math.max(5, math.floor(vim.o.lines * 0.7)))

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

	-- セッションのhooks（例: pi-comment の e=編集）。フロート内キーとして登録
	if type(session.hooks) == "table" then
		for key, fn in pairs(session.hooks) do
			if type(fn) == "function" then
				vim.keymap.set("n", key, function()
					fn(session, idx)
				end, { buffer = buf, nowait = true, silent = true, desc = "[Walkthrough] ステップアクション: " .. key })
			end
		end
	end

	if has_thread(session.steps[idx]) then
		-- スレッドは最新の発言から読みたいので末尾を表示した状態で開く
		pcall(vim.api.nvim_win_set_cursor, win, { #lines, 0 })
		if type(reply_handler) == "function" then
			vim.keymap.set("n", "r", function()
				reply_handler(session, idx)
			end, { buffer = buf, nowait = true, silent = true, desc = "[Walkthrough] スレッドに返信" })
		end
	end

	float_state.win = win
	float_state.session = session
	float_state.idx = idx
end

-- アクティブステップのnoteを表示
local function show_float(session)
	show_note_float(session, session.index)
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

-- bufnr に対応するセッションのステップ一覧（{idx, step} の配列）
local function buffer_steps(session, bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return {}
	end
	local real = vim.uv.fs_realpath(name) or name
	local out = {}
	for i, step in ipairs(session.steps) do
		if type(step.file) == "string" then
			local p = resolve_path(session, step.file)
			if p and (vim.uv.fs_realpath(p) or p) == real then
				out[#out + 1] = { idx = i, step = step }
			end
		end
	end
	return out
end

-- カーソル行に該当する (セッション, idx) を返す。アクティブ優先、次にロード順
local function step_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return nil
	end
	local real = vim.uv.fs_realpath(name) or name
	local order = {}
	if active then
		order[#order + 1] = active
	end
	for _, s in ipairs(sessions) do
		if s ~= active then
			order[#order + 1] = s
		end
	end
	for _, s in ipairs(order) do
		for i, step in ipairs(s.steps) do
			if step.line == line then
				local p = resolve_path(s, step.file)
				if p and (vim.uv.fs_realpath(p) or p) == real then
					return s, i
				end
			end
		end
	end
	return nil
end

-- 描画対象セッション: アクティブ + pinされた非アクティブ（pinはマークのみ常時表示）
local function sessions_to_render()
	local list = {}
	if active then
		list[#list + 1] = active
	end
	for _, s in ipairs(sessions) do
		if s.pin and s ~= active then
			list[#list + 1] = s
		end
	end
	return list
end

-- バッファ内のステップを描画（アクティブセッションのアクティブステップ=▶+行ハイライト、それ以外=▷サインのみ）
local function decorate_buffer(bufnr)
	if not (vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns_marker, 0, -1)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_values, 0, -1)
	for _, session in ipairs(sessions_to_render()) do
		local is_session_active = session == active
		for _, entry in ipairs(buffer_steps(session, bufnr)) do
			local is_active = is_session_active and entry.idx == session.index
			local placed =
				place_marker(bufnr, entry.step.line or 1, entry.idx, #session.steps, is_active, session.step_label)
			if not placed and is_active then
				-- 範囲外警告はセッション×ステップごとに1回だけ（BufWinEnterのたびに連発させない）
				session.warned = session.warned or {}
				if not session.warned[entry.idx] then
					session.warned[entry.idx] = true
					notify(
						string.format(
							"ステップ%dの行%dが範囲外です（コード編集で行がずれた可能性）",
							entry.idx,
							entry.step.line or 1
						),
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

local function refresh_marks()
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(b) then
			decorate_buffer(b)
		end
	end
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

	-- bufnr(path) はパスをfile-patternとして解釈するため（[id] 等が壊れる）bufaddで完全一致させる
	local ok, err = pcall(vim.api.nvim_set_current_buf, vim.fn.bufadd(path))
	if not ok then
		notify("バッファを開けません（続行します）: " .. tostring(err), vim.log.levels.WARN)
	end

	local line = math.max(1, step.line or 1)
	pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
	pcall(vim.cmd, "normal! zz")

	refresh_marks()
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

--- コアAPI: メモリ上のステップ列からセッションを作成しアクティブ化する
--- spec: { steps (必須), name?, root?, description?, commit?, json_path?, index?, hooks? }
--- 同名セッションが既にあれば置き換える。hooks はフロート内キー → fn(session, idx)。
--- 不正なら notify して nil を返す（start/update 共通の検証・組み立て）
local function build_session(spec, name)
	if type(spec) ~= "table" or type(spec.steps) ~= "table" or #spec.steps == 0 then
		notify("start/updateにはstepsの配列が必要です", vim.log.levels.ERROR)
		return nil
	end
	for i, step in ipairs(spec.steps) do
		if type(step) ~= "table" or type(step.file) ~= "string" or type(step.line) ~= "number" then
			notify(string.format("ステップ%dが不正です（file/lineが必要）", i), vim.log.levels.ERROR)
			return nil
		end
		if step.note ~= nil and type(step.note) ~= "string" then
			notify(string.format("ステップ%dのnoteは文字列である必要があります", i), vim.log.levels.ERROR)
			return nil
		end
		if step.thread ~= nil then
			if type(step.thread) ~= "table" then
				notify(string.format("ステップ%dのthreadは配列である必要があります", i), vim.log.levels.ERROR)
				return nil
			end
			for j, entry in ipairs(step.thread) do
				if type(entry) ~= "table" or type(entry.text) ~= "string" then
					notify(
						string.format("ステップ%dのthread[%d]が不正です（textが必要）", i, j),
						vim.log.levels.ERROR
					)
					return nil
				end
			end
		end
	end
	return {
		name = name,
		steps = spec.steps,
		description = spec.description,
		commit = spec.commit,
		root = spec.root or repo_root(vim.uv.cwd()) or vim.uv.cwd(),
		json_path = spec.json_path,
		index = math.max(1, math.min(spec.index or 1, #spec.steps)),
		hooks = spec.hooks,
		step_label = spec.step_label or "step",
		-- pin: 非アクティブでもマークを常時表示し、close()でレジストリから消えない
		pin = spec.pin == true,
	}
end

-- sessions を name で置換（なければ追加）し、置き換えた旧セッションを返す
local function upsert(session)
	for i, s in ipairs(sessions) do
		if s.name == session.name then
			sessions[i] = session
			return s
		end
	end
	sessions[#sessions + 1] = session
	return nil
end

-- JSON由来のwalkthroughがHEADと別のcommitで作られていたら警告する（commitはコアではoptional）
local function check_stale(session)
	if type(session.commit) ~= "string" or session.commit == "" then
		return
	end
	local out = vim.fn.systemlist({ "git", "-C", session.root, "rev-parse", "HEAD" })
	if vim.v.shell_error == 0 and out[1] and out[1] ~= session.commit then
		notify(
			("%s は現在のHEADと別のcommitで作られています（行がずれている可能性・再生成推奨）"):format(
				session.name
			),
			vim.log.levels.WARN
		)
	end
end

function M.start(spec)
	if type(spec) ~= "table" then
		notify("start()にはstepsの配列が必要です", vim.log.levels.ERROR)
		return
	end

	local name = spec.name
	if not name or name == "" then
		unnamed_count = unnamed_count + 1
		name = "walkthrough-" .. unnamed_count
	end

	local session = build_session(spec, name)
	if not session then
		return
	end

	upsert(session)
	check_stale(session)
	activate(session)
end

--- セッション更新API（連携用）: name で置き換え、カーソル移動なしで表示だけ切り替える
--- （例: pi-nvim-comment がコメント追加/編集/削除のたびに「pi-comments」を同期）
--- spec: start() と同じ。index 省略時は既存セッションの現在位置を維持。フロートが開いていれば再描画する
function M.update(spec)
	if type(spec) ~= "table" or type(spec.name) ~= "string" or spec.name == "" then
		notify("update()にはnameが必要です", vim.log.levels.ERROR)
		return
	end
	local session = build_session(spec, spec.name)
	if not session then
		return
	end

	local prev = upsert(session)
	if prev and spec.index == nil then
		session.index = math.max(1, math.min(prev.index, #session.steps))
	end

	-- アクティブ表示は奪わない: 更新対象が表示中（または何も表示していない）ときだけフロートを更新する。
	-- マークはpinセッションを含めて常に再描画する
	local was_active = prev ~= nil and active == prev
	if was_active or active == nil then
		active = session
		if has_float() then
			show_float(session)
		end
	end
	refresh_marks()
end

--- セッションを名前で削除。JSON由来ならファイル自体も削除する（アクティブなら表示もクリア）。連携API
function M.remove(name)
	if type(name) ~= "string" or name == "" then
		return false
	end
	for i, s in ipairs(sessions) do
		if s.name == name then
			-- 永続化はされない設計だが、JSON由来の場合はファイルごと消す（,woのc-dと同じ挙動）
			if s.json_path then
				os.remove(s.json_path)
			end
			table.remove(sessions, i)
			if s == active then
				active = nil
				close_float()
			end
			refresh_marks()
			return true
		end
	end
	return false
end

--- セッションを一覧から選んで削除する（JSONごと削除。pinセッションも削除できる）
function M.delete()
	if #sessions == 0 then
		notify("セッションがありません", vim.log.levels.WARN)
		return
	end
	vim.ui.select(sessions, {
		prompt = "セッション削除（JSONごと）",
		format_item = function(s)
			local marker = s == active and "● " or "  "
			return string.format("%s%s  [%d/%d]", marker, s.name, s.index, #s.steps)
		end,
	}, function(choice)
		if choice and M.remove(choice.name) then
			notify("セッションを削除しました（JSONごと）: " .. choice.name)
		end
	end)
end

--- セッションを名前でアクティブ化（現在位置へジャンプ）。連携API
function M.activate(name)
	for _, s in ipairs(sessions) do
		if s.name == name then
			activate(s)
			return true
		end
	end
	notify("セッションが見つかりません: " .. tostring(name), vim.log.levels.WARN)
	return false
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

--- thread付きステップのフロートで r を押したときの返信ハンドラを登録する。連携API
--- fn(session, idx)。nil で解除
function M.set_reply_handler(fn)
	reply_handler = fn
end

-- プレビュー用テキスト: note全文（threadは発言ごとにauthor付き）+ values
local function step_preview_text(step)
	local parts = { string.format("`%s:%d`", step.file, step.line), "" }
	if has_thread(step) then
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
		local text = step.note or ""
		if has_thread(step) then
			-- スレッドは最新の発言を要約に出す
			text = string.format("💬%d %s", #step.thread, step.thread[#step.thread].text or "")
		end
		local summary = text:gsub("%s+", " ")
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

--- 統合picker: ロード済みセッション（位置保持で切替）+ 保存ディレクトリの未ロードJSON（新規ロード）
--- snacks があれば <c-d>（または一覧での d）で選択項目を削除（JSONごと直接削除）。なければ vim.ui.select にフォールバック
function M.open()
	local items = {}
	local loaded_paths = {}
	for _, s in ipairs(sessions) do
		local marker = s == active and "● " or "  "
		items[#items + 1] = {
			kind = "session",
			session = s,
			text = string.format("%s%s  [%d/%d]", marker, s.name, s.index, #s.steps),
		}
		if s.json_path then
			loaded_paths[s.json_path] = true
		end
	end

	local root = repo_root(vim.uv.cwd()) or vim.uv.cwd()
	local dir = root .. "/" .. config.dir
	local files = vim.fn.glob(dir .. "/*.json", false, true)
	table.sort(files, function(a, b)
		local sa = vim.uv.fs_stat(a)
		local sb = vim.uv.fs_stat(b)
		return (sa and sa.mtime.sec or 0) > (sb and sb.mtime.sec or 0)
	end)
	for _, f in ipairs(files) do
		if not loaded_paths[vim.fn.fnamemodify(f, ":p")] then
			local stat = vim.uv.fs_stat(f)
			local mtime = stat and os.date("%m/%d %H:%M", stat.mtime.sec) or "?"
			items[#items + 1] = {
				kind = "file",
				path = f,
				text = string.format("  %s  (%s · 未ロード)", vim.fn.fnamemodify(f, ":t:r"), mtime),
			}
		end
	end

	if #items == 0 then
		notify("walkthroughがありません: " .. dir, vim.log.levels.WARN)
		return
	end

	local ok, snacks = pcall(require, "snacks")
	if ok and snacks.picker then
		snacks.picker.pick({
			title = "Walkthrough",
			items = items,
			format = "text",
			confirm = function(picker, item)
				picker:close()
				if not item then
					return
				end
				vim.schedule(function()
					if item.kind == "session" then
						activate(item.session)
					else
						M.start_file(item.path)
					end
				end)
			end,
			actions = {
				remove = function(picker)
					local item = picker:current()
					if not item then
						return
					end
					if item.kind == "session" then
						local name = item.session.name
						M.remove(name) -- 内部でJSONごと削除
						notify("削除しました: " .. name)
					else
						os.remove(item.path)
						notify("削除しました: " .. vim.fn.fnamemodify(item.path, ":t:r"))
					end
					picker:close()
					vim.schedule(M.open) -- 一覧から消えた状態で開き直す
				end,
			},
			win = {
				input = {
					keys = {
						["<c-d>"] = { "remove", mode = { "n", "i" }, desc = "Walkthrough削除（JSONごと）" },
					},
				},
				list = {
					keys = {
						["d"] = { "remove", mode = "n", desc = "Walkthrough削除（JSONごと）" },
					},
				},
			},
		})
		return
	end

	vim.ui.select(items, {
		prompt = "Walkthrough",
		format_item = function(item)
			return item.text
		end,
	}, function(choice)
		if not choice then
			return
		end
		if choice.kind == "session" then
			activate(choice.session)
		else
			M.start_file(choice.path)
		end
	end)
end

--- アクティブセッションを閉じる（レジストリから除去し描画をクリア）
function M.close()
	if not active then
		close_float()
		refresh_marks()
		return
	end
	local name = active.name
	if active.pin then
		-- pinセッションはレジストリに残す（マークも表示されたまま）。,ww で戻れる
		active = nil
		close_float()
		refresh_marks()
		notify(("セッションを非アクティブ化しました: %s（,woで戻れます）"):format(name))
		return
	end
	for i, s in ipairs(sessions) do
		if s == active then
			table.remove(sessions, i)
			break
		end
	end
	active = nil
	close_float()
	refresh_marks()
	notify(("セッションを閉じました: %s（残り%d）"):format(name, #sessions))
end

--- カーソル下のステップ（アクティブ優先・ロード順）の編集アクションを呼ぶ。フロートを開かず直接 edit フックへ
function M.edit_at_cursor()
	local s, idx = step_at_cursor()
	if not s then
		notify("カーソル上にステップがありません（,wtでnote表示はできます）", vim.log.levels.WARN)
		return
	end
	local fn = type(s.hooks) == "table" and s.hooks.edit
	if type(fn) ~= "function" then
		notify("このセッションに編集アクションがありません: " .. s.name, vim.log.levels.WARN)
		return
	end
	vim.schedule(function()
		fn(s, idx)
	end)
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

--- noteフロートをトグルする。開くのはカーソル下のステップ（なければアクティブステップ）。
--- 表示中に別ステップの上で押した場合は閉じずにそのステップへ切り替える
function M.toggle_float()
	local s, idx = step_at_cursor()
	if has_float() then
		if s and (float_state.session ~= s or float_state.idx ~= idx) then
			show_note_float(s, idx)
		else
			close_float()
		end
		return
	end
	if s then
		show_note_float(s, idx)
	elseif active then
		show_float(active)
	else
		notify("walkthroughがロードされていません", vim.log.levels.WARN)
	end
end

function M.focus_float()
	if not has_float() then
		if not active then
			notify("walkthroughがロードされていません", vim.log.levels.WARN)
			return
		end
		show_float(active)
	end
	vim.api.nvim_set_current_win(float_state.win)
end

--- テスト・連携用の読み取り専用スナップショット
function M.get_state()
	local list = {}
	for _, s in ipairs(sessions) do
		list[#list + 1] = { name = s.name, index = s.index, total = #s.steps, active = s == active, pin = s.pin == true }
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
	map(keys.open, M.open, "[Walkthrough] 開く/切り替え（セッション+JSON）")
	map(keys.toggle_float, M.toggle_float, "[Walkthrough] noteフロート表示/非表示")
	map(keys.focus_float, M.focus_float, "[Walkthrough] noteフロートにフォーカス")
	map(keys.close, M.close, "[Walkthrough] セッションを閉じる")
	map(keys.edit_at_cursor, M.edit_at_cursor, "[Walkthrough] カーソル下のステップを編集（hooks.edit）")
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

	-- 後から開いたバッファにもステップのサインを描画する（アクティブ + pinセッション）
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = vim.api.nvim_create_augroup("walkthrough_decorate", { clear = true }),
		callback = function(ev)
			decorate_buffer(ev.buf)
		end,
	})
end

return M
