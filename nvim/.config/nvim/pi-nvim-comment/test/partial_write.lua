-- headless: (1) 書き込み途中のcomments.jsonではマージせず再試行、後から正しく書ければ反映される
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

	local function total()
		for _, s in ipairs(require("walkthrough").get_state()) do
			if s.name == "pi-comments" then
				return s.total
			end
		end
		return 0
	end
	assert(total() == 1, "setup should merge 1 step")

	local json = tmp .. "/.walkthroughs/comments.json"

	-- (1) 壊れたJSONを書き込む（書き込み途中相当）→ マージされず total のまま
	local bad = io.open(json, "w")
	bad:write('{"description":"partial')
	bad:close()
	vim.wait(5000, function()
		return total() ~= 1
	end)
	assert(total() == 1, "broken JSON must not merge (total=" .. total() .. ")")

	-- (2) 正しいJSONに直す → 監視が再試行して反映される
	local good = io.open(json, "w")
	good:write(vim.json.encode({
		description = "test",
		commit = "0000000000000000000000000000000000000000",
		steps = {
			{ file = "init.lua", line = 1, thread = {
				{ author = "you", text = "q" },
				{ author = "pi", text = "a" },
			} },
		},
	}))
	good:close()
	vim.wait(5000, function()
		return total() == 1 and true -- baseline時点ですでに1のため、追加ステップを足して検証
	end)
	-- 念のため: 2ステップ目の追記でも機能することを確認
	local f = io.open(json, "r")
	local data = vim.json.decode(f:read("*a"))
	f:close()
	table.insert(data.steps, { file = "init.lua", line = 1, thread = {
		{ author = "you", text = "q2" },
		{ author = "pi", text = "a2" },
	} })
	local w = io.open(json, "w")
	w:write(vim.json.encode(data))
	w:close()
	vim.wait(5000, function()
		return total() == 2
	end)
	assert(total() == 2, "fixed JSON did not merge (total=" .. total() .. ")")
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")