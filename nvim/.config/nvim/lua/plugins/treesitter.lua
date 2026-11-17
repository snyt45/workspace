-- パーサとクエリの配布だけを担う。ハイライトは本体の機能（vim.treesitter.start）
-- パーサのビルドに tree-sitter-cli（Brewfile）と C コンパイラが要る
local LANGUAGES = {
	"ruby", "embedded_template",
	"typescript", "tsx", "javascript",
	"json", "yaml", "toml", "html", "css",
	"bash", "diff", "gitcommit",
}

return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		-- 入っていないものだけ入れる
		require("nvim-treesitter").install(LANGUAGES)

		-- パーサがある filetype だけハイライトを treesitter にする（無ければ従来の syntax のまま）
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				pcall(vim.treesitter.start, args.buf)
			end,
		})
	end,
}
