-- スレッドフロートを開いたまま回答が追記されたら、その場で内容が更新される。
-- このときフォーカスは移動しない（フロート内で読んでいる最中に飛ばされない）
H.run(function()
	H.setup()
	local wt = require("walkthrough")

	H.open("init.lua", 6)
	wt.toggle_float() -- ,wt は開くと同時にフォーカスする

	local before, float_win = H.float_text()
	assert(before and before:find("💬") ~= nil, "float not showing thread before merge")
	assert(vim.api.nvim_get_current_win() == float_win, "float should be focused after ,wt")

	local data = H.read()
	table.insert(data.steps[1].thread, { author = "pi", text = "新着返信REPLY" })
	H.write(data)

	vim.wait(6000, function()
		local t = H.float_text()
		return t and t:find("新着返信REPLY") ~= nil
	end)

	local after, win_after = H.float_text()
	assert(after and after:find("新着返信REPLY") ~= nil, "open float not refreshed: " .. tostring(after))
	assert(vim.api.nvim_get_current_win() == win_after, "focus was stolen by the refresh")
end)
