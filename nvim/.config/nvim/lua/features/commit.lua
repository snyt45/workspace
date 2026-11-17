-- ステージ済みの変更をコミットする。下にメッセージ欄を開き、:wq でコミット、:q! で取りやめ
-- 開いた時点で書き始められる。裏で Claude が差分から1行の下書きを作り、1行目が空のままなら届いた時に入れる
local M = {}

local DRAFT_PROMPT = "あなたは git のコミットメッセージを書く。標準入力の差分を読み、日本語で1行のメッセージだけを出力する。"
	.. "「〜する」の形で終える。説明・引用符・コードブロックは付けない。"
local DIFF_LIMIT = 30000 -- 下書きに渡す差分の上限（バイト）

local function git(cwd, ...)
	return vim.system({ "git", ... }, { cwd = cwd, text = true }):wait()
end

local function draft(buf, cwd)
	if vim.fn.executable("claude") == 0 then
		return
	end
	local diff = git(cwd, "diff", "--cached").stdout or ""
	vim.system({
		"claude", "-p", "--model", "haiku", "--no-session-persistence",
		-- 設定・CLAUDE.md・ツール・スキルを読まずに、差分だけを渡す（約2秒で返る）
		"--setting-sources", "", "--tools", "", "--disable-slash-commands",
		"--system-prompt", DRAFT_PROMPT,
		"コミットメッセージを書いて",
	}, { cwd = vim.uv.os_tmpdir(), text = true, stdin = diff:sub(1, DIFF_LIMIT) }, vim.schedule_wrap(function(res)
		local msg = vim.trim(res.stdout or ""):match("^[^\n]*")
		if res.code ~= 0 or msg == "" or not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		if vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
			vim.api.nvim_buf_set_lines(buf, 0, 1, false, { msg })
		end
	end))
end

-- # の行を除いたメッセージでコミットする。失敗したら modified を残し、:wq で閉じないようにする
local function commit(buf, cwd)
	local lines = vim.tbl_filter(function(l)
		return not l:match("^#")
	end, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	local message = vim.trim(table.concat(lines, "\n"))
	if message == "" then
		vim.bo[buf].modified = false
		vim.notify("メッセージが空なのでコミットしません", vim.log.levels.WARN)
		return
	end
	local res = vim.system({ "git", "commit", "-F", "-" }, { cwd = cwd, text = true, stdin = message }):wait()
	if res.code ~= 0 then
		vim.notify(vim.trim((res.stdout or "") .. (res.stderr or "")), vim.log.levels.ERROR)
		return
	end
	vim.bo[buf].modified = false
	vim.notify(vim.trim(res.stdout or ""):match("^[^\n]*"))
	pcall(vim.cmd, "DiffviewRefresh")
end

function M.open()
	local root = git(vim.fn.getcwd(), "rev-parse", "--show-toplevel")
	if root.code ~= 0 then
		vim.notify("git リポジトリではありません", vim.log.levels.WARN)
		return
	end
	local cwd = vim.trim(root.stdout)
	local stat = vim.trim(git(cwd, "diff", "--cached", "--stat").stdout or "")
	if stat == "" then
		vim.notify("ステージされた変更がありません", vim.log.levels.WARN)
		return
	end

	local lines = { "", "", "# :wq でコミット / :q! で取りやめ" }
	for line in stat:gmatch("[^\n]+") do
		table.insert(lines, "# " .. line)
	end

	vim.cmd("botright " .. math.min(#lines + 2, 15) .. "new")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(buf, "commit://" .. cwd)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "gitcommit"
	vim.bo[buf].modified = false
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			commit(buf, cwd)
		end,
	})
	vim.cmd("startinsert")
	draft(buf, cwd)
end

return M
