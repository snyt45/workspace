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
				window = {
					mappings = {
						["F"] = function(state)
							local node = state.tree:get_node()
							local path = node.type == "directory" and node:get_id() or
							    vim.fn.fnamemodify(node:get_id(), ":h")
							require("telescope.builtin").live_grep({
								search_dirs = { path },
								additional_args = { "--hidden" },
							})
						end,
					},
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
		vim.keymap.set("n", "<leader>e", "<cmd>Neotree focus<cr>", { desc = "[NeoTree] ファイルツリー" })
	end,
}
