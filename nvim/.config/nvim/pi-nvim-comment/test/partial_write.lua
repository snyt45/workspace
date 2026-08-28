-- 書き込み途中の（壊れた）comments.json ではマージせず再試行し、正しく書ければ反映される
H.run(function()
	H.setup()
	assert(H.total() == 1, "setup should merge 1 step")

	-- 壊れたJSON（書き込み途中相当）→ マージされない
	local bad = assert(io.open(H.json, "w"))
	bad:write('{"description":"partial')
	bad:close()
	vim.wait(5000, function()
		return H.total() ~= 1
	end)
	assert(H.total() == 1, "broken JSON must not merge (total=" .. H.total() .. ")")

	-- 正しいJSONに直す → 監視が再試行して反映される
	H.write({
		description = "test",
		commit = "0000000000000000000000000000000000000000",
		steps = {
			{ file = "init.lua", line = 1, thread = { { author = "you", text = "q" }, { author = "pi", text = "a" } } },
			{ file = "init.lua", line = 6, thread = { { author = "you", text = "q2" }, { author = "pi", text = "a2" } } },
		},
	})
	vim.wait(6000, function()
		return H.total() == 2
	end)
	assert(H.total() == 2, "fixed JSON did not merge (total=" .. H.total() .. ")")
end)
