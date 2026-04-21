local map = vim.keymap.set

map("n", "q", "<Nop>")
map({ "n", "i" }, "<F1>", "<Nop>")

map("n", "<Esc>", ":nohlsearch<CR>")

map("i", "<C-a>", "<Home>")
map("i", "<C-e>", "<End>")

map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "<C-f>", "<C-f>zz")
map("n", "<C-b>", "<C-b>zz")

map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "[Buffer] バッファを閉じる" })

-- quickfix
map("n", "]q", "<cmd>cnext<cr>", { desc = "[Quickfix] 次のquickfix" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "[Quickfix] 前のquickfix" })
map("n", "<leader>q", function()
	local wins = vim.fn.getqflist({ winid = 0 }).winid
	if wins ~= 0 then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end, { desc = "[Quickfix] quickfixトグル" })
map("n", "<leader>Q", "<cmd>cexpr []<cr>", { desc = "[Quickfix] quickfixクリア" })

map("n", "<leader>m", function()
	local file = vim.fn.shellescape(vim.fn.expand("%"))
	local output = vim.fn.system("mo " .. file .. " 2>&1")
	local url = output:match("(http://[^%s]+)")
	if url then
		vim.fn.jobstart({ "open", url })
	end
end, { desc = "[General] Markdownプレビュー" })

-- copy
map("n", "<leader>c", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "[General] ファイルパスコピー" })

map("v", "<leader>cc", function()
	local path = vim.fn.expand("%:.")
	vim.cmd('normal! "vy')
	local selected_text = vim.fn.getreg("v")
	local formatted = "@" .. path .. "\n\n```\n" .. selected_text .. "\n```"
	vim.fn.setreg("+", formatted)
	vim.notify("Copied: @" .. path .. " with selected text", vim.log.levels.INFO)
end, { desc = "[General] ファイルパス+コードコピー" })

