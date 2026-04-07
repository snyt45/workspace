-- ==========================================================================
-- LSP設定 (Neovim 0.11+ 組み込み API)
-- mason-lspconfigでインストール、vim.lsp.config/enableで設定
-- ==========================================================================

-- TypeScript
vim.lsp.config.ts_ls = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	root_markers = { "tsconfig.json", "package.json" },
}
vim.lsp.enable("ts_ls")

-- Ruby
vim.lsp.config.ruby_lsp = {
	cmd = { "ruby-lsp" },
	filetypes = { "ruby" },
	root_markers = { "Gemfile", ".ruby-version" },
}
vim.lsp.enable("ruby_lsp")

-- Lua (Neovim設定ファイル用)
vim.lsp.config.lua_ls = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc" },
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = { library = { vim.env.VIMRUNTIME } },
		},
	},
}
vim.lsp.enable("lua_ls")

-- diagnostic表示設定
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

-- LSP共通キーマップ (LSPがアタッチされたバッファでのみ有効)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local buf = args.buf
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "[LSP] 定義ジャンプ" })
		vim.keymap.set("n", "gr", function()
			vim.g.last_lsp_search = vim.fn.expand("<cword>")
			vim.lsp.buf.references()
		end, { buffer = buf, desc = "[LSP] 参照一覧" })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "[LSP] ホバー" })
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf, desc = "[LSP] リネーム" })
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "[LSP] コードアクション" })
		vim.keymap.set("n", "<leader>cs", function()
			vim.lsp.buf.code_action({ context = { only = { "source" } } })
		end, { buffer = buf, desc = "[LSP] ソースアクション (import整理等)" })
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { buffer = buf, desc = "[LSP] 型定義" })
		vim.keymap.set("n", "gl", vim.diagnostic.open_float, { buffer = buf, desc = "[LSP] diagnostic" })
	end,
})
