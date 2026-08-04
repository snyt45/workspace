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
				vim.keymap.set("n", "]c", function() gs.nav_hunk("next") end, { buffer = bufnr, desc = "[GitSigns] 次のhunk" })
				vim.keymap.set("n", "[c", function() gs.nav_hunk("prev") end, { buffer = bufnr, desc = "[GitSigns] 前のhunk" })
				vim.keymap.set("n", "<leader>gb", gs.blame, { buffer = bufnr, desc = "[GitSigns] blame" })
				vim.keymap.set("n", "<leader>ga", gs.stage_buffer, { buffer = bufnr, desc = "[GitSigns] 現在のファイルをstage" })
			end,
		})
	end,
}
