-- walkthrough.nvim / session
-- セッションレジストリ（データ層）。描画・ジャンプはここでは行わない。
-- セッション: { name, steps, description?, commit?, root, json_path?, index, hooks, pin, protect_json }

local util = require("walkthrough.util")

local M = {}

local sessions = {}
local active = nil
local unnamed_count = 0

function M.list()
	return sessions
end

function M.get_active()
	return active
end

function M.set_active(session)
	active = session
end

function M.find(name)
	for _, s in ipairs(sessions) do
		if s.name == name then
			return s
		end
	end
	return nil
end

function M.next_unnamed()
	unnamed_count = unnamed_count + 1
	return "walkthrough-" .. unnamed_count
end

--- hooks を正規化する。
--- keys    = フロート内キーシーケンス（例 e/d）→ fn(session, idx)
--- actions = 意味的アクション（edit/delete/purge）→ fn(session, idx)。キーマップにはしない
local function normalize_hooks(hooks)
	if type(hooks) ~= "table" then
		return { keys = {}, actions = {} }
	end
	local keys, actions = {}, {}
	for k, v in pairs(type(hooks.keys) == "table" and hooks.keys or {}) do
		if type(v) == "function" then
			keys[k] = v
		end
	end
	for k, v in pairs(type(hooks.actions) == "table" and hooks.actions or {}) do
		if type(v) == "function" then
			actions[k] = v
		end
	end
	return { keys = keys, actions = actions }
end

--- 意味的アクションを取り出す（なければ nil）
function M.action(session, name)
	local actions = session and session.hooks and session.hooks.actions
	return type(actions) == "table" and actions[name] or nil
end

local function invalid(message)
	util.notify(message, vim.log.levels.ERROR)
	return nil
end

--- spec を検証してセッションを組み立てる。不正なら notify して nil
function M.build(spec, name)
	if type(spec) ~= "table" or type(spec.steps) ~= "table" or #spec.steps == 0 then
		return invalid("start/updateにはstepsの配列が必要です")
	end
	for i, step in ipairs(spec.steps) do
		if type(step) ~= "table" or type(step.file) ~= "string" or type(step.line) ~= "number" then
			return invalid(string.format("ステップ%dが不正です（file/lineが必要）", i))
		end
		if step.note ~= nil and type(step.note) ~= "string" then
			return invalid(string.format("ステップ%dのnoteは文字列である必要があります", i))
		end
		if step.thread ~= nil then
			if type(step.thread) ~= "table" then
				return invalid(string.format("ステップ%dのthreadは配列である必要があります", i))
			end
			for j, entry in ipairs(step.thread) do
				if type(entry) ~= "table" or type(entry.text) ~= "string" then
					return invalid(string.format("ステップ%dのthread[%d]が不正です（textが必要）", i, j))
				end
			end
		end
	end
	return {
		name = name,
		steps = spec.steps,
		description = spec.description,
		commit = spec.commit,
		root = spec.root or util.repo_root(vim.uv.cwd()) or vim.uv.cwd(),
		json_path = spec.json_path,
		index = math.max(1, math.min(spec.index or 1, #spec.steps)),
		hooks = normalize_hooks(spec.hooks),
		step_label = spec.step_label or "step",
		-- pin: 非アクティブでもマークを常時表示し、close()でレジストリから消えない
		pin = spec.pin == true,
		-- protect_json: json_pathのファイルをremove()で削除しない（連携セッションが所有するJSON用）
		protect_json = spec.protect_json == true,
	}
end

--- name で置換（なければ追加）し、置き換えた旧セッションを返す
function M.upsert(session)
	for i, s in ipairs(sessions) do
		if s.name == session.name then
			sessions[i] = session
			return s
		end
	end
	sessions[#sessions + 1] = session
	return nil
end

--- レジストリから外す（ファイル削除・描画更新はしない）。外せたら true
function M.unregister(session)
	for i, s in ipairs(sessions) do
		if s == session then
			table.remove(sessions, i)
			if s == active then
				active = nil
			end
			return true
		end
	end
	return false
end

--- 描画対象: アクティブ + pinされた非アクティブ（pinはマークのみ常時表示）
function M.to_render()
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

--- bufnr に対応するセッションのステップ一覧（{idx, step} の配列）
function M.buffer_steps(session, bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return {}
	end
	local real = vim.uv.fs_realpath(name) or name
	local out = {}
	for i, step in ipairs(session.steps) do
		local p = util.resolve_path(session.root, step.file)
		if p and (vim.uv.fs_realpath(p) or p) == real then
			out[#out + 1] = { idx = i, step = step }
		end
	end
	return out
end

--- カーソル行に該当する (セッション, idx)。アクティブ優先、次にロード順。
--- 同じ行に複数ステップがあればスレッド付きを優先する（コメント本文でなく返信スレッドを開く）
function M.step_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	if vim.api.nvim_buf_get_name(bufnr) == "" then
		return nil
	end

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
		local fallback
		for _, entry in ipairs(M.buffer_steps(s, bufnr)) do
			if entry.step.line == line then
				if util.has_thread(entry.step) then
					return s, entry.idx
				end
				fallback = fallback or entry.idx
			end
		end
		if fallback then
			return s, fallback
		end
	end
	return nil
end

--- JSON由来のwalkthroughがHEADと別のcommitで作られていたら警告する（commitはoptional）
function M.check_stale(session)
	if type(session.commit) ~= "string" or session.commit == "" then
		return
	end
	local out = vim.fn.systemlist({ "git", "-C", session.root, "rev-parse", "HEAD" })
	if vim.v.shell_error == 0 and out[1] and out[1] ~= session.commit then
		util.notify(
			("%s は現在のHEADと別のcommitで作られています（行がずれている可能性・再生成推奨）"):format(session.name),
			vim.log.levels.WARN
		)
	end
end

--- JSONファイルを読み、start() へ渡せるspecへ変換する
function M.load_json(json_path)
	json_path = vim.fn.fnamemodify(json_path, ":p")
	local f = io.open(json_path, "r")
	if not f then
		return invalid("読み込めません: " .. json_path)
	end
	local content = f:read("*a")
	f:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok then
		return invalid("不正なJSONです: " .. tostring(data))
	end
	if type(data) ~= "table" or type(data.steps) ~= "table" or #data.steps == 0 then
		return invalid("stepsがありません: " .. json_path)
	end

	return {
		name = vim.fn.fnamemodify(json_path, ":t:r"),
		steps = data.steps,
		description = data.description,
		commit = data.commit,
		root = util.repo_root(vim.fn.fnamemodify(json_path, ":h")) or vim.fn.fnamemodify(json_path, ":h"),
		json_path = json_path,
	}
end

return M
