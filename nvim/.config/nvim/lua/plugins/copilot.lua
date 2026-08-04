return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			-- miseのnodeバージョン更新に追従するため固定パスにしない
			copilot_node_command = vim.fn.exepath("node"),
			-- インラインサジェストは使わない (補完はsidekickのNESに一本化)
			suggestion = { enabled = false },
			panel = { enabled = false },
			filetypes = { ["*"] = true },
		})
	end,
}
