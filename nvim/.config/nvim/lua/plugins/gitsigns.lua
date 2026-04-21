return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({
			current_line_blame = true,
			signs = {
				add          = { text = "+" },
				change       = { text = ">" },
				delete       = { text = "-" },
				topdelete    = { text = "^" },
				changedelete = { text = "<" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				vim.keymap.set("n", "]c", gs.next_hunk, { buffer = bufnr, desc = "[GitSigns] 次のhunk" })
				vim.keymap.set("n", "[c", gs.prev_hunk, { buffer = bufnr, desc = "[GitSigns] 前のhunk" })
				vim.keymap.set("n", "<leader>gb", gs.blame, { buffer = bufnr, desc = "[GitSigns] blame" })
			end,
		})
	end,
}
