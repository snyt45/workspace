-- 同じ行に note-only ステップと thread ステップが並ぶ場合、,wt はスレッドを優先して開く
H.run(function()
	local wt = require("walkthrough")
	H.open("init.lua")

	wt.start({
		name = "t",
		steps = {
			{ file = "init.lua", line = 6, note = "draft comment" },
			{
				file = "init.lua",
				line = 6,
				thread = { { author = "you", text = "question" }, { author = "pi", text = "REPLY_TEXT" } },
			},
		},
	})
	-- start でアクティブステップ（L6・noteのみ）のフロートが開く。もう一度 ,wt でスレッド優先に切替
	wt.toggle_float()

	local text = H.float_text()
	assert(text, "float not opened")
	assert(text:find("REPLY_TEXT") ~= nil, "thread not preferred: " .. text)
	assert(text:find("💬") ~= nil, "thread marker missing: " .. text)
end)
