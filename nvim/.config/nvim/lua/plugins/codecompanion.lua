return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("codecompanion").setup({
			language = "Japanese",
			interactions = {
				chat = { adapter = "copilot" },
				inline = { adapter = "copilot" },
				cmd = { adapter = "copilot" },
			},
			display = {
				action_palette = {
					opts = {
						show_preset_prompts = false,
					},
				},
				chat = {
					window = {
						layout = "vertical",
						width = 0.4,
					},
				},
			},
		})
		vim.keymap.set({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AIチャット" })
		vim.keymap.set({ "n", "v" }, "<leader>ccp", "<cmd>CodeCompanionActions<cr>", { desc = "AIアクション" })
		vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "チャットに追加" })
	end,
}
