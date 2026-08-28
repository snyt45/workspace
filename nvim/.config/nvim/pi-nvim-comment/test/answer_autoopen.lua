-- 回答が届いたときの自動表示:
-- (1) フロートを開いていなければ、新しい回答スレッドのフロートが自動で開く
-- (2) そのスレッドに返信が追記されたら、開いたまま内容が増える
H.run(function()
	H.setup()
	H.open("init.lua")

	-- 起動時のベースライン取り込みが終わるのを待つ（それ以降の追記だけが「回答」）
	H.wait_baseline()

	-- (1) 新スレッド（L8）への回答を追記 → 自動でフロートが開く
	local data = H.read()
	table.insert(data.steps, {
		file = "init.lua",
		line = 8,
		thread = { { author = "you", text = "sent via C-x" }, { author = "pi", text = "C-X_REPLY_TEXT" } },
	})
	H.write(data)

	vim.wait(8000, function()
		local t = H.float_text()
		return t and t:find("C-X_REPLY_TEXT") ~= nil
	end)
	assert((H.float_text() or ""):find("C-X_REPLY_TEXT"), "answer float did not auto-open: " .. tostring(H.float_text()))

	-- (2) 開いたまま、そのスレッドに返信が追記される
	data = H.read()
	table.insert(data.steps[2].thread, { author = "pi", text = "SECOND_REPLY" })
	H.write(data)

	vim.wait(8000, function()
		local t = H.float_text()
		return t and t:find("SECOND_REPLY") ~= nil
	end)
	local text = H.float_text() or ""
	assert(text:find("C-X_REPLY_TEXT") ~= nil, "first reply disappeared: " .. text)
	assert(text:find("SECOND_REPLY") ~= nil, "open float not updated in place: " .. text)
end)
