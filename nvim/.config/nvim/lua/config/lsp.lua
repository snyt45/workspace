-- ==========================================================================
-- LSP設定 (Neovim 0.11+ 組み込み API)
-- ts_ls・lua_ls は mason-lspconfig がインストールして自動で起動する
-- ruby_lsp は各 Ruby の gem を使うので、ここで起動する
-- ==========================================================================

vim.lsp.enable("ruby_lsp")

vim.diagnostic.config({
	virtual_text = { prefix = "●" },
	severity_sort = true,
})

-- LSP の進捗（インデックス中など）をメッセージに出す。同じ id のメッセージは上書きされる（:h LspProgress の例）
vim.api.nvim_create_autocmd("LspProgress", {
	callback = function(ev)
		local value = ev.data.params.value
		if type(value) ~= "table" then
			return
		end
		local message = value.message or "done"
		vim.api.nvim_echo({ { message } }, false, {
			id = "lsp." .. ev.data.params.token,
			kind = "progress",
			source = "vim.lsp",
			title = value.title,
			status = value.kind ~= "end" and "running" or "success",
			-- ruby-lsp のように文言に割合が入っているときは、割合を重ねて出さない
			percent = not message:find("%%") and value.percentage or nil,
		})
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local buf = args.buf
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "[LSP] 定義ジャンプ" })
		vim.keymap.set("n", "<C-w>gs", function()
			vim.cmd.split()
			vim.lsp.buf.definition()
		end, { buffer = buf, desc = "[LSP] 横分割して定義ジャンプ" })
		vim.keymap.set("n", "<C-w>gv", function()
			vim.cmd.vsplit()
			vim.lsp.buf.definition()
		end, { buffer = buf, desc = "[LSP] 縦分割して定義ジャンプ" })
		vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = buf, desc = "[LSP] 参照一覧" })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "[LSP] ホバー" })
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf, desc = "[LSP] リネーム" })
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "[LSP] コードアクション" })
		vim.keymap.set("n", "<leader>cs", function()
			vim.lsp.buf.code_action({
				context = {
					only = { "source" },
					diagnostics = vim.diagnostic.get(buf),
				},
			})
		end, { buffer = buf, desc = "[LSP] ソースアクション (import整理等)" })
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { buffer = buf, desc = "[LSP] 型定義" })
		vim.keymap.set("n", "gl", vim.diagnostic.open_float, { buffer = buf, desc = "[LSP] diagnostic" })
	end,
})
