-- pi-nvim-comment / threads
-- 回答スレッドファイル（.walkthroughs/comments.json）の読み書きと変更監視。
-- piが回答を書き込むとここが検出し、pi-commentsセッションへの再同期を呼び出す。

local util = require("pi-nvim-comment.util")

local M = {}

local WATCH_INTERVAL_MS = 3000

local timer
local last_mtime -- 最後に取り込んだmtime（nilなら未取得＝起動直後）
local failed_mtime -- 直近でパースに失敗したmtime（警告は同じmtimeに1回だけ）

function M.path(root)
	return (root or util.project_root()) .. "/.walkthroughs/comments.json"
end

local function stamp()
	local st = vim.uv.fs_stat(M.path())
	return st and (tostring(st.mtime.sec) .. "." .. tostring(st.mtime.nsec)) or ""
end

--- comments.json の生データ（{ description?, commit?, steps }）。読めない・壊れていれば nil
function M.read()
	local path = M.path()
	if vim.fn.filereadable(path) ~= 1 then
		return nil
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or not lines or #lines == 0 then
		return nil
	end
	-- readfileは行ごとに返す。整形（複数行）JSONでも読めるよう全体を連結してデコードする
	local decode_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not decode_ok or type(data) ~= "table" or type(data.steps) ~= "table" then
		return nil
	end
	return data
end

--- 自分の書き込みを取り込み済みとして記録する（監視が自分の変更を「piの回答」と誤検出しないように）
local function mark_synced()
	last_mtime = stamp()
	failed_mtime = nil
end

--- スレッドを1件削除する（file_idx は comments.json 内のステップ番号）
function M.remove_step(file_idx)
	local data = M.read()
	if not data or not data.steps[file_idx] then
		return false
	end
	table.remove(data.steps, file_idx)
	if not util.write_json(M.path(), data) then
		util.notify("comments.json を書き込めませんでした", vim.log.levels.ERROR)
		return false
	end
	mark_synced()
	return true
end

--- ファイルごと削除する（purge用）
function M.delete_file()
	local path = M.path()
	if vim.fn.filereadable(path) == 1 then
		os.remove(path)
	end
	mark_synced()
end

-- mtimeが変わったら on_change(is_update) を呼ぶ。
-- is_update=false は起動時のベースライン取り込み（通知やフロートの自動表示はしない）。
-- 書き込み途中でパースに失敗した場合はベースラインを進めず、次のtickで読めるまで再試行する
local function tick(on_change)
	local mtime = stamp()
	if mtime == last_mtime then
		return
	end
	if mtime ~= "" and M.read() == nil then
		if failed_mtime ~= mtime then
			failed_mtime = mtime
			util.notify("comments.json が読み込めません（書き込み途中？再試行します）", vim.log.levels.WARN)
		end
		return
	end
	local primed = last_mtime ~= nil
	last_mtime, failed_mtime = mtime, nil
	on_change(primed)
end

function M.start_watch(on_change)
	if timer then
		return
	end
	timer = vim.uv.new_timer()
	timer:start(
		WATCH_INTERVAL_MS,
		WATCH_INTERVAL_MS,
		vim.schedule_wrap(function()
			tick(on_change)
		end)
	)
end

function M.stop_watch()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
end

return M
