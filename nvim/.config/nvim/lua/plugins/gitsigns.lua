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
				vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "[GitSigns] hunkをstage" })
				vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, { buffer = bufnr, desc = "[GitSigns] hunkをunstage" })
				vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, desc = "[GitSigns] hunkをreset" })
				vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "[GitSigns] hunkをプレビュー" })
				vim.keymap.set("n", "<leader>hb", gs.blame, { buffer = bufnr, desc = "[GitSigns] blame" })
			end,
		})
	end,
}
