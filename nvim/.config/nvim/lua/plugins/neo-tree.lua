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
			local cur = vim.api.nvim_get_current_win()
			local neotree_win
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
					neotree_win = win
					break
				end
			end
			if not neotree_win then
				local ok, grug = pcall(require, "grug-far")
				if ok and grug.has_instance("main") and grug.is_instance_open("main") then
					grug.toggle_instance({ instanceName = "main" })
				end
				vim.cmd("Neotree focus")
			elseif neotree_win == cur then
				vim.cmd("Neotree close")
			else
				vim.api.nvim_set_current_win(neotree_win)
			end
		end, { desc = "[NeoTree] toggle/focus" })
	end,
}
