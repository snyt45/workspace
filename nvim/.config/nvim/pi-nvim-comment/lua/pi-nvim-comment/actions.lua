-- pi-nvim-comment / actions
-- ユーザー操作の入口（追加・編集・返信・提出・コピー・破棄・全削除）。
-- state / threads を変更したら必ず sync.refresh() で walkthrough 表示を合わせる。

local modal = require("pi-nvim-comment.modal")
local prompt = require("pi-nvim-comment.prompt")
local state = require("pi-nvim-comment.state")
local sync = require("pi-nvim-comment.sync")
local threads = require("pi-nvim-comment.threads")
local util = require("pi-nvim-comment.util")

local M = {}

local submitting = false

-- --------------------------------------------------------------------------
-- 提出
-- --------------------------------------------------------------------------
--- 指定したrecord群だけを提出する。成功時はそのrecordだけをリストから外す（他の未提出は残る）
--- label: 成功通知のformat文字列（%d=件数）
local function submit_list(list, label)
	if submitting then
		util.notify("送信処理が進行中です", vim.log.levels.WARN)
		return
	end
	if #list == 0 then
		util.notify("提出するコメントがありません", vim.log.levels.WARN)
		return
	end
	if not util.socket_path() then
		util.notify("piセッションが見つかりません（piを起動してください）", vim.log.levels.WARN)
		return
	end

	local message, count = prompt.build(list)
	if not message then
		util.notify(count, vim.log.levels.ERROR)
		return
	end

	submitting = true
	util.pi_nvim().send_raw({ type = "prompt", message = message }, function(err, response)
		submitting = false
		if err or not response or not response.ok then
			util.notify((err or "piがレビューを受け付けませんでした") .. "; コメントは保持されました", vim.log.levels.ERROR)
			return
		end
		state.remove_all(list)
		sync.refresh()
		util.notify(label:format(count))
	end)
end

function M.submit()
	submit_list(state.list(), "%dコメントをpiに提出しました")
end

--- 提出内容（指示文 + コメント一覧）をクリップボードにコピーする。piセッションは不要
function M.copy()
	if state.count() == 0 then
		util.notify("コピーするコメントがありません", vim.log.levels.WARN)
		return
	end
	local message, count = prompt.build(state.list())
	if not message then
		util.notify(count, vim.log.levels.ERROR)
		return
	end
	vim.fn.setreg("+", message) -- システムクリップボード
	util.notify(("%dコメント分の提出内容をクリップボードにコピーしました"):format(count))
end

-- --------------------------------------------------------------------------
-- 追加・編集・返信
-- --------------------------------------------------------------------------
-- モーダル確定後の共通処理: 未提出リストへ入れるか、この1件だけ即送信するか
local function accept(record, action, saved_message, send_label)
	sync.refresh()
	if action == "send" then
		-- 即送信でも先にrecord化しておく: 送信失敗時は未提出コメントとして残る
		submit_list({ record }, send_label)
		return
	end
	-- 保存したコメントをすぐ確認できるよう、そのコメントのフロートを開く（カーソル移動なし）
	sync.show_now(sync.index_of_draft(record.id))
	util.notify(saved_message)
end

function M.annotate(start_line, end_line)
	local bufnr = vim.api.nvim_get_current_buf()
	if vim.bo[bufnr].buftype ~= "" then
		util.notify("コメントは通常のファイルバッファでのみ追加できます", vim.log.levels.WARN)
		return
	end

	local absolute = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(bufnr))
	if not absolute then
		util.notify("ファイルを保存してからコメントを追加してください", vim.log.levels.WARN)
		return
	end

	local root = util.project_root()
	local path = util.relative_path(root, absolute)
	if not path then
		util.notify("現在のファイルはPiプロジェクトの外にあります", vim.log.levels.WARN)
		return
	end

	local first_line = math.min(start_line, end_line)
	local last_line = math.max(start_line, end_line)
	if last_line - first_line + 1 > prompt.MAX_SOURCE_LINES then
		util.notify(
			("1コメントで %d 行を超える範囲にはコメントできません"):format(prompt.MAX_SOURCE_LINES),
			vim.log.levels.WARN
		)
		return
	end

	local location = util.location(first_line, last_line)
	modal.open(string.format("Piコメント · %s:%s", path, location), nil, function(comment, action)
		comment = comment and util.validate_comment(comment)
		if not comment then
			return
		end
		local record = state.add({
			bufnr = bufnr,
			absolute_path = absolute,
			line = first_line,
			span = last_line - first_line,
			comment = comment,
			root = root,
		})
		accept(
			record,
			action,
			("コメントを追加: %s:%s（切替: ,wo / 巡回: ]w）"):format(path, location),
			"コメント%d件をpiへ即送信しました"
		)
	end)
end

--- コメントを編集する（sync のフロート内キー e / ,we から呼ばれる）
function M.edit(record)
	local path = util.relative_path(util.project_root(), record.absolute_path) or record.absolute_path
	local location = util.location(state.range_of(record))

	modal.open(string.format("Piコメント編集 · %s:%s", path, location), record.comment, function(text, action)
		text = text and util.validate_comment(text)
		if not text then
			return
		end
		record.comment = text
		state.save()
		sync.refresh()
		if action == "send" then
			submit_list({ record }, "コメント%d件をpiへ即送信しました")
		else
			util.notify(("コメントを編集: %s:%s"):format(path, location))
		end
	end)
end

--- walkthroughのthread付きステップへの返信（walkthrough.nvim の set_reply_handler 経由で呼ばれる）
--- 返信は「そのステップと同じ行に付いた未提出コメント」になり、reply_to にスレッド参照を持つ
function M.reply(session, idx)
	local step = session.steps and session.steps[idx]
	if not step then
		return
	end
	if not session.json_path then
		util.notify("このセッションはファイル由来ではないため返信できません", vim.log.levels.WARN)
		return
	end

	local absolute = vim.uv.fs_realpath(session.root and (session.root .. "/" .. step.file) or step.file)
	if not absolute then
		util.notify("返信先のファイルが見つかりません: " .. tostring(step.file), vim.log.levels.WARN)
		return
	end

	-- スレッド履歴のスナップショット（提出プロンプトの Thread so far に使う）
	local context = {}
	for _, entry in ipairs(step.thread or {}) do
		for i, line in ipairs(util.split_lines(entry.text or "")) do
			context[#context + 1] = (i == 1 and ("[" .. tostring(entry.author or "?") .. "] ") or "") .. line
		end
	end

	local root = util.project_root()
	local path = util.relative_path(root, absolute) or step.file
	modal.open(string.format("Pi返信 · %s:%d", path, step.line), nil, function(comment, action)
		comment = comment and util.validate_comment(comment)
		if not comment then
			return
		end
		local record = state.add({
			bufnr = vim.fn.bufadd(absolute),
			absolute_path = absolute,
			line = step.line,
			span = 0,
			comment = comment,
			root = root,
			reply_to = {
				json = session.json_path,
				-- 統合ビューではセッション内indexとファイル内ステップ番号が一致しないため file_idx を使う
				step = step.file_idx or idx,
				context = table.concat(context, "\n"),
			},
		})
		accept(
			record,
			action,
			("返信を追加: %s:%d（,pxで提出）"):format(path, step.line),
			"返信%d件をpiへ即送信しました（回答は自動反映されます）"
		)
	end)
end

-- --------------------------------------------------------------------------
-- 破棄
-- --------------------------------------------------------------------------
function M.clear()
	local count = state.count()
	if count == 0 then
		util.notify("破棄するコメントはありません")
		return
	end
	state.clear()
	sync.refresh()
	util.notify(("%dコメントを破棄しました"):format(count))
end

--- コメント・返信・スレッドをすべて削除する（,wo の削除アクションから呼ばれる）。
--- 未提出レコード（state）と comments.json を消し、pi-commentsセッションも閉じる
function M.purge()
	state.clear()
	threads.delete_file()
	local ok, wt = pcall(require, "walkthrough")
	if ok then
		wt.remove(sync.SESSION)
	end
	util.notify("コメント・返信・スレッドを削除しました")
end

return M
