return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({
			signs = {
				add          = { text = "+" },
				change       = { text = ">" },
				delete       = { text = "-" },
				topdelete    = { text = "^" },
				changedelete = { text = "<" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				vim.keymap.set("n", "gn", gs.next_hunk, { buffer = bufnr, desc = "次のhunk" })
				vim.keymap.set("n", "gp", gs.prev_hunk, { buffer = bufnr, desc = "前のhunk" })
				vim.keymap.set("n", "gha", gs.stage_hunk, { buffer = bufnr, desc = "hunkをstage" })
				vim.keymap.set("n", "ghu", gs.reset_hunk, { buffer = bufnr, desc = "hunkをreset" })
				vim.keymap.set("n", "ghp", gs.preview_hunk, { buffer = bufnr, desc = "hunkをプレビュー" })
			end,
		})
	end,
}
