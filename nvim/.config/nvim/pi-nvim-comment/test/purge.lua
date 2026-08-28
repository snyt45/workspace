-- purge がコメント・返信・スレッド（state + comments.json）を実削除し、pi-commentsを閉じる
H.run(function()
	local pc = H.setup()

	assert(H.session(), "pi-comments should exist after setup")
	assert(vim.fn.filereadable(H.json) == 1, "thread file should exist")

	pc.purge()

	assert(not H.session(), "pi-comments should be gone after purge")
	assert(vim.fn.filereadable(H.json) == 0, "thread file should be deleted")

	-- state にも未提出レコードが残らない（再起動後に復活しない）
	if vim.fn.filereadable(H.state_file) == 1 then
		local ok, lines = pcall(vim.fn.readfile, H.state_file)
		if ok and lines and lines[1] then
			for _, item in ipairs(vim.json.decode(lines[1])) do
				if type(item) == "table" and item.root == H.tmp then
					error("record for this project still in state: " .. vim.inspect(item))
				end
			end
		end
	end

	-- 削除したファイルを監視が「回答」と誤検出して復活させない
	vim.wait(5000, function()
		return H.session() ~= nil
	end)
	assert(not H.session(), "purged session came back")
end)
