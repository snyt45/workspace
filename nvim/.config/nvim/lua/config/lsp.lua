-- ==========================================================================
-- LSP設定 (Neovim 0.11+ 組み込み API)
-- mason-lspconfigでインストール、自動的にLSPサーバーを起動
-- ==========================================================================

vim.diagnostic.config({
	virtual_text = { prefix = "●" },
	severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local buf = args.buf
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "[LSP] 定義ジャンプ" })
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
		vim.keymap.set("n", "<leader>ll", function()
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
				local config = client.config
				client:stop()
				vim.defer_fn(function()
					vim.lsp.start(config)
				end, 500)
			end
		end, { buffer = buf, desc = "[LSP] 再起動" })
	end,
})
