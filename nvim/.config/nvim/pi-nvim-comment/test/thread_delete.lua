-- (1) show() でカーソル移動なしにフロートを開ける (2) ,wt はフォーカスまで移す
-- (3) フォーカス中の d で pi の回答スレッドが comments.json から消える
H.run(function()
	H.setup()
	local wt = require("walkthrough")

	H.open("init.lua", 6)

	assert(wt.show("pi-comments", 1), "show() returned false")
	local _, float_win = H.float_text()
	assert(float_win, "float not opened by show()")

	-- 閉じて ,wt で開き直す → フォーカスされている
	vim.api.nvim_win_close(float_win, true)
	wt.toggle_float()
	local _, win = H.float_text()
	assert(win and vim.api.nvim_get_current_win() == win, "float should be focused after ,wt")

	-- normal! はマッピングを通らないため normal を使う
	vim.cmd("normal d")
	vim.wait(2000, function()
		local data = H.read()
		return data and #data.steps == 0
	end)
	local data = H.read()
	assert(data and #data.steps == 0, "thread step not deleted: " .. vim.inspect(data))

	-- 自分の削除を監視が「piの回答」と誤検出しない（セッションが復活しない）
	vim.wait(5000, function()
		return H.session() ~= nil
	end)
	assert(not H.session(), "session came back after own write")
end)
