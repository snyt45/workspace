return {
	"mason-org/mason.nvim",
	dependencies = { "mason-org/mason-lspconfig.nvim" },
	config = function()
		require("mason").setup()
		require("mason-lspconfig").setup({
			-- ruby_lsp は mason で入れない（lsp/ruby_lsp.lua）
			ensure_installed = { "ts_ls", "lua_ls" },
		})
	end,
}
