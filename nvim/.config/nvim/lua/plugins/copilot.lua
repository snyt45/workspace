return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			-- miseのnodeバージョン更新に追従するため固定パスにしない
			copilot_node_command = vim.fn.exepath("node"),
			suggestion = {
				enabled = false,
				auto_trigger = true,
				keymap = {
					accept = false,
					accept_word = "<C-l>",
					next = "<C-j>",
					prev = "<C-k>",
					dismiss = "<C-e>",
				},
			},
			panel = { enabled = false },
			filetypes = { ["*"] = true },
		})

		vim.keymap.set("i", "<Right>", function()
			local suggestion = require("copilot.suggestion")
			if suggestion.is_visible() then
				suggestion.accept()
			else
				return "<Right>"
			end
		end, { expr = true })
	end,
}
