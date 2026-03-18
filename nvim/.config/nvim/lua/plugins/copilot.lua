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
					accept = "<Right>",
					accept_word = "<M-Right>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			panel = { enabled = false },
			filetypes = { ["*"] = true },
		})
	end,
}
