-- headless regression: 複数行（整形）JSONの comments.json が読めること
-- （vim.fn.readfile は行ごとに返すため、連結してデコードする必要がある）
local ok_all, err_all = pcall(function()
	local tmp = vim.env.PI_TEST_DIR
	assert(tmp and vim.fn.isdirectory(tmp) == 1, "PI_TEST_DIR missing")

	local json = tmp .. "/.walkthroughs/comments.json"
	vim.fn.writefile({
		"{",
		'  "description": "test",',
		'  "commit": "0000000000000000000000000000000000000000",',
		'  "steps": [',
		"    {",
		'      "file": "init.lua",',
		'      "line": 6,',
		'      "thread": [',
		'        { "author": "you", "text": "hello" },',
		'        { "author": "pi", "text": "reply" }',
		"      ]",
		"    }",
		"  ]",
		"}",
	}, json)

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

	local found = false
	for _, s in ipairs(require("walkthrough").get_state()) do
		if s.name == "pi-comments" then
			found = true
			assert(s.total == 1, "expected 1 step from multiline json, got " .. s.total)
		end
	end
	assert(found, "pi-comments not created")
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")