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

-- LSP共通キーマップ (LSPがアタッチされたバッファでのみ有効)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local buf = args.buf
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "定義ジャンプ" })
		vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = buf, desc = "参照一覧" })
		vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "ホバー" })
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf, desc = "リネーム" })
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "コードアクション" })
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { buffer = buf, desc = "型定義" })
		vim.keymap.set("n", "gl", vim.diagnostic.open_float, { buffer = buf, desc = "diagnostic" })
	end,
})
