-- headless: merge while the thread float is OPEN on the pinned pi-comments -> float must refresh
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

	-- スレッドフロートを開く
	wt.toggle_float()

	local function float_text()
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			local b = vim.api.nvim_win_get_buf(w)
			if vim.bo[b].filetype == "markdown" then
				return table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
			end
		end
		return nil
	end
	local before = float_text()
	assert(before and before:find("💬") ~= nil, "float not showing thread before merge")

	-- JSONに返信を追記（mtime変更）→ watcherがマージ → 開いたままのフロートに反映されるか
	local json = tmp .. "/.walkthroughs/comments.json"
	local f = io.open(json, "r")
	local data = vim.json.decode(f:read("*a"))
	f:close()
	data.steps[1].thread[#data.steps[1].thread + 1] = { author = "pi", text = "新着返信REPLY" }
	local out = io.open(json, "w")
	out:write(vim.json.encode(data))
	out:close()

	vim.wait(5000, function()
		local t = float_text()
		return t and t:find("新着返信REPLY") ~= nil
	end)
	local after = float_text() or ""
	assert(after:find("新着返信REPLY") ~= nil, "open float not refreshed: " .. after)
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")