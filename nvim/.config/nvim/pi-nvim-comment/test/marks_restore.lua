-- 再起動後（state復元後）もコメントの行追従が効く:
-- 復元時点ではバッファが未ロードでextmarkを張れないため、BufReadPost で張り直している。
-- 追従した行は保存にも反映される（次の起動で位置が巻き戻らない）
H.run(function()
	local file = H.tmp .. "/init.lua"
	vim.fn.writefile({
		vim.json.encode({
			{ id = 1, absolute_path = file, line = 6, span = 0, comment = "追従テスト", root = H.tmp },
		}),
	}, H.state_file)

	H.setup()
	local state = require("pi-nvim-comment.state")
	local record = state.list()[1]
	assert(record, "record was not restored from state")
	assert(state.line_of(record) == 6, "restored line should be 6, got " .. state.line_of(record))

	-- ファイルを開く（BufReadPost でマークが張られる）→ 上に3行挿入
	H.open("init.lua")
	vim.api.nvim_buf_set_lines(0, 0, 0, false, { "-- a", "-- b", "-- c" })

	assert(state.line_of(record) == 9, "line should follow the edit (expected 9, got " .. state.line_of(record) .. ")")

	-- 保存されるのは記録時の行ではなく追従後の行
	state.save()
	local saved = vim.json.decode(vim.fn.readfile(H.state_file)[1])
	assert(saved[1].line == 9, "saved line should be 9, got " .. tostring(saved[1].line))
end)
