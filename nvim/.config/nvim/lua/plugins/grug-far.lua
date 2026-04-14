return {
	"MagicDuck/grug-far.nvim",
	cmd = { "GrugFar", "GrugFarWithin", "GrugFarToggle" },
	keys = {
		{ "<leader>s", "<cmd>GrugFarToggle<cr>", desc = "[GrugFar] トグル" },
	},
	opts = {
		windowCreationCommand = "topleft 60vsplit",
	},
	config = function(_, opts)
		require("grug-far").setup(opts)

		vim.api.nvim_create_user_command("GrugFarToggle", function()
			require("grug-far").toggle_instance({ instanceName = "main" })
		end, { desc = "[GrugFar] トグル (検索状態を保持)" })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "grug-far",
			callback = function(ev)
				local function set_paths(paths)
					require("grug-far").get_instance(0):update_input_values({ paths = paths }, false)
				end
				vim.keymap.set("n", "<localleader>1", function()
					set_paths(vim.fn.fnamemodify(vim.fn.expand("#:p"), ":h"))
				end, { buffer = ev.buf, desc = "[GrugFar] path: 元ファイルのdir" })
				vim.keymap.set("n", "<localleader>2", function()
					set_paths("<buflist>")
				end, { buffer = ev.buf, desc = "[GrugFar] path: 開いているバッファ" })
				vim.keymap.set("n", "<localleader>3", function()
					set_paths("<qflist>")
				end, { buffer = ev.buf, desc = "[GrugFar] path: quickfix" })
			end,
		})
	end,
}
