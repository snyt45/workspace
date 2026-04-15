return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			close_if_last_window = true,
			popup_border_style = "rounded",
			filesystem = {
				use_libuv_file_watcher = true,
				follow_current_file = {
					enabled = true,
				},
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
			window = {
				width = 30,
				mappings = {
					["l"] = "open",
					["h"] = "close_node",
				},
			},
		})
		vim.keymap.set("n", "<leader>e", function()
			local ok, grug = pcall(require, "grug-far")
			if ok and grug.has_instance("main") and grug.is_instance_open("main") then
				grug.toggle_instance({ instanceName = "main" })
			end
			vim.cmd("Neotree focus")
		end, { desc = "[NeoTree] ファイルツリー" })
	end,
}
