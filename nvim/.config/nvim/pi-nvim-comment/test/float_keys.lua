-- フロート内キーは hooks.keys だけ。意味的アクション（edit/delete/purge）は
-- キーシーケンスとして登録されない（フロートで "purge" とタイプして全削除が走らないこと）
H.run(function()
	H.setup()
	local wt = require("walkthrough")

	H.open("init.lua", 6)
	assert(wt.show("pi-comments", 1), "show() returned false")

	local _, win = H.float_text()
	assert(win, "float not opened")

	local lhs = {}
	for _, map in ipairs(vim.api.nvim_buf_get_keymap(vim.api.nvim_win_get_buf(win), "n")) do
		lhs[map.lhs] = true
	end

	for _, key in ipairs({ "e", "d", "q", "r" }) do
		assert(lhs[key], "float should map " .. key)
	end
	for _, name in ipairs({ "edit", "delete", "purge" }) do
		assert(not lhs[name], "semantic action must not be a key sequence: " .. name)
	end
end)
