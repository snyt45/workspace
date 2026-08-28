-- pi-nvim-comment / modal
-- コメント入力の多行エディタ（追加・編集・返信で共用）。

local util = require("pi-nvim-comment.util")

local M = {}

local active = nil

-- action: "save"=未提出リストへ / "send"=この1件だけ即送信（キャンセル時は value=nil）
local function finish(value, action)
	local current = active
	if not current then
		return
	end
	active = nil
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

--- モーダルを開く。callback(text|nil, action) は閉じたあとに呼ばれる
function M.open(title, initial, callback)
	if active then
		util.notify("別のコメントエディタが開いています", vim.log.levels.WARN)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"

	if type(initial) == "string" and initial ~= "" then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, util.split_lines(initial))
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

	for option, value in pairs({
		wrap = true,
		linebreak = true,
		cursorline = false,
		number = false,
		relativenumber = false,
		signcolumn = "no",
		foldcolumn = "0",
	}) do
		vim.wo[win][option] = value
	end

	active = { buf = buf, win = win, callback = callback }

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			if active and active.win == win then
				finish(nil)
			end
		end,
	})

	local function submit(action)
		if not vim.api.nvim_buf_is_valid(buf) then
			finish(nil)
			return
		end
		finish(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"), action)
	end
	local function cancel()
		finish(nil)
	end

	local map = { buffer = buf, silent = true, nowait = true }
	vim.keymap.set({ "n", "i" }, "<C-s>", function()
		submit("save")
	end, map)
	vim.keymap.set({ "n", "i" }, "<C-x>", function()
		submit("send")
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

return M
