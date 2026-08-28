-- 別のwalkthroughがアクティブでも、pi-comments（pin・非アクティブ）のマーカー上で
-- ,wt を押せばそのステップのスレッドフロートが開く
H.run(function()
	H.setup()
	local wt = require("walkthrough")

	H.open("init.lua")
	wt.start({ name = "other", steps = { { file = "init.lua", line = 1, note = "other step" } } })

	-- カーソルをコメント行（L6）に置いて ,wt
	vim.api.nvim_win_set_cursor(0, { 6, 0 })
	wt.toggle_float()

	local text = H.float_text()
	assert(text, "float not opened")
	assert(text:find("hello") ~= nil, "thread content missing: " .. text)
	assert(text:find("▌ pi") ~= nil, "pi author label missing: " .. text)
	assert(text:find("💬") ~= nil, "thread marker (💬) missing: " .. text)
end)
