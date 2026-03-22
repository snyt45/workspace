return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			copilot_node_command = vim.fn.expand(
				"~/.local/share/mise/installs/node/22.22.1/bin/node"),
			suggestion = {
				enabled = true,
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
