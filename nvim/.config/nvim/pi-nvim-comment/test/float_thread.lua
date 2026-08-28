-- headless test: cursor on the pi-comments marker (in a pinned, non-active session)
-- while ANOTHER walkthrough is active -> ,wt must show the THREAD float of that step
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

	-- 別のwalkthroughをアクティブにする（pi-commentsはpinのまま非アクティブへ）
	wt.start({ name = "other", steps = { { file = "init.lua", line = 1, note = "other step" } } })

	-- カーソルをコメント行（L6）に置いて ,wt
	vim.api.nvim_win_set_cursor(0, { 6, 0 })
	wt.toggle_float()

	local float_lines = nil
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		local b = vim.api.nvim_win_get_buf(w)
		if vim.bo[b].filetype == "markdown" then
			float_lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
		end
	end
	assert(float_lines, "float not opened")
	local text = table.concat(float_lines, "\n")
	assert(text:find("hello") ~= nil, "thread content missing: " .. text)
	assert(text:find("▌ pi") ~= nil, "pi author label missing: " .. text)
	assert(text:find("💬") ~= nil, "thread marker (💬) missing: " .. text)
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")