-- headless smoke test (run with: nvim --headless -u NONE -i NONE -c "luafile <this file>")
-- 検証内容: pi-nvim-comment が (1) .walkthroughs/comments.json を pi-comments セッションへ統合し、
-- (2) ファイルへの追記（pi回答）を3秒間隔の監視で自動反映する。
-- 実行前にシェル側で PI_TEST_DIR に「init.lua + .walkthroughs/comments.json」を持つ一時プロジェクトを作ること。
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
				return s.total, s.pin
			end
		end
		return 0, false
	end

	local n, pin = total()
	assert(n == 1, "expected 1 step at setup, got " .. n)
	assert(pin, "pi-comments must be pinned")

	-- protect_json: セッションを remove してもスレッドJSONは消えない（,wo d での誤削除防止）
	local json = tmp .. "/.walkthroughs/comments.json"
	require("walkthrough").remove("pi-comments")
	assert(vim.fn.filereadable(json) == 1, "thread file was deleted on session remove")

	-- (2) JSONに回答を追記（mtime変更）→ 監視が拾ってセッションを再作成し2ステップに
	local f = io.open(json, "r")
	local data = vim.json.decode(f:read("*a"))
	f:close()
	table.insert(data.steps, { file = "init.lua", line = 1, thread = {
		{ author = "you", text = "second comment" },
		{ author = "pi", text = "second answer" },
	} })
	local out = io.open(json, "w")
	out:write(vim.json.encode(data))
	out:close()

	vim.wait(5000, function()
		return total() == 2
	end)
	n = total()
	assert(n == 2, "watcher did not merge: total=" .. n)
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")