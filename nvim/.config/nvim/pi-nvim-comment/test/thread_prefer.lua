-- headless: 同じ行に note-only ステップと thread ステップが並ぶ場合、,wt はスレッドを優先して開く
local ok_all, err_all = pcall(function()
	local tmp = vim.env.PI_TEST_DIR
	assert(tmp and vim.fn.isdirectory(tmp) == 1, "PI_TEST_DIR missing")

	local cfg = vim.fn.stdpath("config")
	vim.opt.rtp:prepend(cfg .. "/walkthrough.nvim")

	local buf = vim.fn.bufadd(tmp .. "/init.lua")
	vim.api.nvim_set_current_buf(buf)

	local wt = require("walkthrough")
	wt.start({
		name = "t",
		steps = {
			{ file = "init.lua", line = 6, note = "draft comment" },
			{ file = "init.lua", line = 6, thread = {
				{ author = "you", text = "question" },
				{ author = "pi", text = "REPLY_TEXT" },
			} },
		},
	})
	-- start でアクティブステップ(L6・noteのみ)のフロートが開く。もう一度 ,wt → スレッド優先で切替
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
	assert(text:find("REPLY_TEXT") ~= nil, "thread not preferred: " .. text)
	assert(text:find("💬") ~= nil, "thread marker missing: " .. text)
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")