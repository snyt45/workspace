-- comments.json を pi-comments セッションへ統合し、ファイルへの追記（piの回答）を監視で自動反映する
H.run(function()
	H.setup()

	local s = H.session()
	assert(s and s.total == 1, "expected 1 step at setup, got " .. H.total())
	assert(s.pin, "pi-comments must be pinned")

	-- protect_json: セッションを remove してもスレッドJSONは消えない（,wo d での誤削除防止）
	require("walkthrough").remove("pi-comments")
	assert(vim.fn.filereadable(H.json) == 1, "thread file was deleted on session remove")

	-- JSONに回答を追記（mtime変更）→ 監視が拾ってセッションを作り直し2ステップに
	local data = H.read()
	table.insert(data.steps, {
		file = "init.lua",
		line = 1,
		thread = { { author = "you", text = "second comment" }, { author = "pi", text = "second answer" } },
	})
	H.write(data)

	vim.wait(6000, function()
		return H.total() == 2
	end)
	assert(H.total() == 2, "watcher did not merge: total=" .. H.total())
end)
