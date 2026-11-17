-- 補完（本体の機能だけで行う）
-- 入力中に自動で候補を出す。出どころは LSP → 今のバッファ → 他のウィンドウ・バッファ
-- パスは自動では出ないので <C-x><C-f>

vim.o.autocomplete = true
vim.o.complete = "o,.,w,b"
vim.o.completeopt = "menuone,noselect,fuzzy,popup"
vim.o.pumborder = "rounded"

-- 自動で候補を出すのは普通のファイルだけ。ピッカーの入力欄（buftype=prompt）などでは出さない
vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "OptionSet" }, {
	callback = function(args)
		if args.event == "OptionSet" and args.match ~= "buftype" then
			return
		end
		local buf = vim.api.nvim_get_current_buf()
		if vim.bo[buf].buftype ~= "" then
			vim.bo[buf].autocomplete = false
		end
	end,
})

-- LSP の候補を使う。確定したときに import の追加やスニペットの展開が行われる
-- autotrigger は、"." などサーバーが決めた文字を打った直後にも候補を出す
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

local map = vim.keymap.set

map("i", "<Tab>", function()
	return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, desc = "[Completion] 次の候補" })

map("i", "<S-Tab>", function()
	return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true, desc = "[Completion] 前の候補" })

-- 候補が出ていれば確定する。何も選んでいなければ先頭を選んで確定する
map("i", "<CR>", function()
	if vim.fn.pumvisible() == 0 then
		return "<CR>"
	end
	return vim.fn.complete_info({ "selected" }).selected == -1 and "<C-n><C-y>" or "<C-y>"
end, { expr = true, desc = "[Completion] 確定" })

map("i", "<C-Space>", function()
	vim.lsp.completion.get()
end, { desc = "[Completion] 候補を出す" })
