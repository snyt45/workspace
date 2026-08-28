-- headless: M.purge() がコメント・返信・スレッド（state + comments.json）を実削除し、
-- pi-commentsセッションを閉じる（,woのC-d/d相当）
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

	local function has_session()
		for _, s in ipairs(require("walkthrough").get_state()) do
			if s.name == "pi-comments" then
				return true
			end
		end
		return false
	end

	local json = tmp .. "/.walkthroughs/comments.json"
	assert(has_session(), "pi-comments should exist after setup")
	assert(vim.fn.filereadable(json) == 1, "thread file should exist")

	pc.purge()

	assert(not has_session(), "pi-comments should be gone after purge")
	assert(vim.fn.filereadable(json) == 0, "thread file should be deleted")

	-- state にも未提出レコードが残らない（再起動後に復活しない）
	local state_path = vim.fn.stdpath("state") .. "/pi_review.json"
	if vim.fn.filereadable(state_path) == 1 then
		local ok2, lines = pcall(vim.fn.readfile, state_path)
		if ok2 and lines and lines[1] then
			local d = vim.json.decode(lines[1])
			for _, item in ipairs(d) do
				if type(item) == "table" and item.root == tmp then
					error("record for this project still in state: " .. vim.inspect(item))
				end
			end
		end
	end
end)
print("RESULT: " .. (ok_all and "OK" or ("ERR: " .. tostring(err_all))))
vim.cmd("qa!")