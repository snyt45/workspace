-- headless: C-x即送信後の回答で、
-- (1) 新規スレッドの回答 → フロートが自動で開く
-- (2) 開いているスレッドに返信が追記 → 開いたままフロートが更新される
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

	local buf = vim.fn.bufadd(tmp .. "/init.lua")
	vim.api.nvim_set_current_buf(buf)

	local function float_text()
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			local b = vim.api.nvim_win_get_buf(w)
			if vim.bo[b].filetype == "markdown" then
				return table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
			end
		end
		return nil
	end

	local json = tmp .. "/.walkthroughs/comments.json"
	local function read()
		local f = io.open(json, "r")
		local d = vim.json.decode(f:read("*a"))
		f:close()
		return d
	end
	local function write(d)
		local out = io.open(json, "w")
		out:write(vim.json.encode(d))
		out:close()
	end

	-- 起動後最初のtick（ベースライン記録）が終わるのを待つ。それ以降の追記だけが
	-- 「変化」として検出され、自動表示の対象になる（実運用のC-x送信はこの前提）
	vim.wait(4000, function()
		return false
	end)

	-- (1) 新スレッド（L8）への回答を追記 → 自動でフロートが開く
	local d = read()
	table.insert(d.steps, { file = "init.lua", line = 8, thread = {
		{ author = "you", text = "sent via C-x" },
		{ author = "pi", text = "C-X_REPLY_TEXT" },
	} })
	write(d)
	vim.wait(6000, function()
		local t = float_text()
		return t and t:find("C-X_REPLY_TEXT") ~= nil
	end)
	local t = float_text() or ""
	assert(t:find("C-X_REPLY_TEXT") ~= nil, "answer thread float did not auto-open: " .. t)

	-- (2) 開いているまま、そのスレッドに返信が追記 → フロートに追加される
	d = read()
	d.steps[2].thread[#d.steps[2].thread + 1] = { author = "pi", text = "SECOND_REPLY" }
	write(d)
	vim.wait(6000, function()
		local t2 = float_text()
		return t2 and t2:find("SECOND_REPLY") ~= nil
	end)
	local t2 = float_text() or ""
	assert(t2:find("C-X_REPLY_TEXT") ~= nil, "first reply disappeared: " .. t2)
	assert(t2:find("SECOND_REPLY") ~= nil, "open float not updated in place: " .. t2)
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")