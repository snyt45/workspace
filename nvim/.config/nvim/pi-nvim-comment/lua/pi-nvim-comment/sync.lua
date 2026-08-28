-- pi-nvim-comment / sync
-- 未提出コメント（state）と回答スレッド（comments.json）を「pi-comments」セッションとして
-- walkthrough へ同期する。コード上の表示・移動・フォーカスはすべて walkthrough.nvim に委ねる。
--
-- ステップは2種類。種別は kind で持ち、参照先だけが違う:
--   kind = "draft"  → record_id  未提出コメント（編集・削除できる）
--   kind = "thread" → file_idx   comments.json のスレッド（piの回答。返信・削除できる）

local state = require("pi-nvim-comment.state")
local threads = require("pi-nvim-comment.threads")
local util = require("pi-nvim-comment.util")

local M = {}

local SESSION = "pi-comments"

local steps = {} -- 直近のステップ列（record_id/file_idx からセッション内indexを引くのに使う）
local thread_len = {} -- file_idx -> スレッド発言数。回答が増えたスレッドの検出に使う

-- --------------------------------------------------------------------------
-- ステップアクション（フロート内キー e/d と ,we から共有）
-- --------------------------------------------------------------------------
local function edit_step(session, idx)
	local step = session.steps[idx]
	if not step or step.kind ~= "draft" then
		util.notify("このステップはpiの回答です（編集は不可・削除は d）", vim.log.levels.WARN)
		return
	end
	local record = state.find(step.record_id)
	if not record then
		util.notify("コメントが見つかりません（既に削除された可能性）", vim.log.levels.WARN)
		return
	end
	vim.schedule(function()
		require("pi-nvim-comment.actions").edit(record)
	end)
end

local function delete_step(session, idx)
	local step = session.steps[idx]
	if not step then
		return
	end
	if step.kind == "draft" then
		if state.remove(step.record_id) then
			M.refresh()
			util.notify("コメントを削除しました")
		end
		return
	end
	if threads.remove_step(step.file_idx) then
		M.refresh()
		util.notify("スレッドを削除しました（comments.jsonから除外）")
	end
end

local HOOKS = {
	-- フロート内キー: e=編集モーダル / d=削除
	keys = { e = edit_step, d = delete_step },
	-- 意味的アクション（キーマップにはならない）: ,we の編集、,wo の削除
	actions = {
		edit = edit_step,
		delete = delete_step,
		purge = function()
			require("pi-nvim-comment.actions").purge()
		end,
	},
}

-- --------------------------------------------------------------------------
-- ステップ組み立て
-- --------------------------------------------------------------------------
local function thread_steps()
	local out = {}
	local data = threads.read()
	if not data then
		return out
	end
	for index, st in ipairs(data.steps) do
		if type(st) == "table" and type(st.file) == "string" and type(st.line) == "number" then
			local has_thread = type(st.thread) == "table" and #st.thread > 0
			out[#out + 1] = {
				kind = "thread",
				file_idx = index,
				file = st.file,
				line = st.line,
				thread = has_thread and st.thread or nil,
				-- threadで表示するステップはnote不要（nilのままキーなしにする）
				note = (not has_thread) and st.note or nil,
			}
		end
	end
	return out
end

local function draft_steps(root)
	local out = {}
	for _, record in ipairs(state.list()) do
		local start_line, end_line = state.range_of(record)
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
		out[#out + 1] = {
			kind = "draft",
			record_id = record.id,
			file = util.relative_path(root, record.absolute_path) or record.absolute_path,
			line = start_line,
			note = note,
		}
	end
	return out
end

-- 同じ位置ならスレッド（回答）を先に、その中では元の並び順を保つ
local function sort_steps(list)
	local function rank(step)
		return step.kind == "thread" and 0 or 1
	end
	local function seq(step)
		return step.file_idx or step.record_id
	end
	table.sort(list, function(a, b)
		if a.file ~= b.file then
			return a.file < b.file
		end
		if a.line ~= b.line then
			return a.line < b.line
		end
		if rank(a) ~= rank(b) then
			return rank(a) < rank(b)
		end
		return seq(a) < seq(b)
	end)
end

-- 前回の同期から発言が増えた（または新しく現れた）スレッドのセッション内index
local function detect_new_answer(list)
	local changed = nil
	local current = {}
	for index, step in ipairs(list) do
		if step.kind == "thread" and step.thread then
			current[step.file_idx] = #step.thread
			local before = thread_len[step.file_idx]
			if not changed and (before == nil or before < #step.thread) then
				changed = index
			end
		end
	end
	thread_len = current
	return changed
end

-- --------------------------------------------------------------------------
-- 同期
-- --------------------------------------------------------------------------
--- コメントの追加/編集/削除・回答の反映のたびに呼ぶ。
--- 戻り値: 新しい回答が入ったスレッドのセッション内index（なければ nil）
function M.refresh()
	local ok, wt = pcall(require, "walkthrough")
	if not ok then
		return nil
	end

	local root = util.project_root()
	local list = thread_steps()
	vim.list_extend(list, draft_steps(root))
	sort_steps(list)

	steps = list
	local changed = detect_new_answer(list)

	if #list == 0 then
		wt.remove(SESSION)
		return nil
	end

	wt.update({
		name = SESSION,
		steps = list,
		root = root,
		-- スレッドJSONへの参照を持たせ、,woでは1つのwalkthroughとして扱う（未ロード重複表示を防ぐ）
		json_path = threads.path(root),
		-- このJSONはコメントの記録先なので、セッション削除でファイルまで消さない
		protect_json = true,
		-- 非アクティブでもマークを常時表示し、,wqで消えない（コメントは打てば常に見える）
		pin = true,
		-- walkthrough の表示名「step」を pi-comment の文脈では「comment」にする
		step_label = "comment",
		hooks = HOOKS,
	})
	return changed
end

--- 未提出コメントのセッション内index（フロートを開く位置の特定に使う）
function M.index_of_draft(record_id)
	for index, step in ipairs(steps) do
		if step.kind == "draft" and step.record_id == record_id then
			return index
		end
	end
	return nil
end

--- スレッドのフロートを開く（既に何か表示中なら奪わない）
function M.show(index)
	local ok, wt = pcall(require, "walkthrough")
	if ok and index then
		wt.show(SESSION, index, { if_free = true })
	end
end

--- 指定ステップのフロートを開く（保存直後の確認用。表示中でも切り替える）
function M.show_now(index)
	local ok, wt = pcall(require, "walkthrough")
	if ok and index then
		wt.show(SESSION, index)
	end
end

M.SESSION = SESSION

return M
