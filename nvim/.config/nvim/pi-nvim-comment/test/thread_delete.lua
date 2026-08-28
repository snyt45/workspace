-- headless: (1) ,wt で開いたフロートはフォーカスされる、(2) フォーカス内で d → pi回答スレッドを
-- comments.json から削除、(3) wt.show() でフロートを開ける
local ok_all, err_all = pcall(function()
	local tmp = vim.env.PI_TEST_DIR
	assert(tmp and vim.fn.isdirectory(tmp) == 1, "PI_TEST_DIR missing")

	package.preload["pi-nvim"] = function()
		return { get_socket_path = function()
			return nil
		end }
	end
	local cfg = vim.fn.stdpath("config")
	vim.opt.rtp:prepend(cfg .. "/pi-nvim-comment")
	vim.opt.rtp:prepend(cfg .. "/walkthrough.nvim")

	local pc = require("pi-nvim-comment")
	pc.setup({ keymaps = false, prompt_suffix = "" })
	local wt = require("walkthrough")

	local buf = vim.fn.bufadd(tmp .. "/init.lua")
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_win_set_cursor(0, { 6, 0 })

	-- (3) M.show: カーソル移動なしでスレッドフロートを開ける
	assert(wt.show("pi-comments", 1), "show() returned false")
	local float_win
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		local b = vim.api.nvim_win_get_buf(w)
		if vim.bo[b].filetype == "markdown" then
			float_win = w
		end
	end
	assert(float_win, "float not opened by show()")

	-- 閉じて ,wt で開き直し → (1) フォーカスされている
	vim.api.nvim_win_close(float_win, true)
	wt.toggle_float()
	local now = vim.api.nvim_get_current_win()
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		local b = vim.api.nvim_win_get_buf(w)
		if vim.bo[b].filetype == "markdown" then
			assert(now == w, "float should be focused after ,wt")
		end
	end

	-- (2) フォーカスされたフロートで d → スレッドステップが comments.json から消える
	-- （normal! はマッピングを通らないため normal d を使う）
	vim.cmd("normal d")
	vim.wait(2000, function()
		local f = io.open(tmp .. "/.walkthroughs/comments.json", "r")
		if not f then
			return true
		end
		local data = vim.json.decode(f:read("*a"))
		f:close()
		return #data.steps == 0
	end)
	local f = io.open(tmp .. "/.walkthroughs/comments.json", "r")
	local data = f and vim.json.decode(f:read("*a")) or nil
	if f then
		f:close()
	end
	assert(data and #data.steps == 0, "thread step not deleted: " .. vim.inspect(data))
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")