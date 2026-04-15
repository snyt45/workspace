return {
	"MagicDuck/grug-far.nvim",
	cmd = { "GrugFar", "GrugFarWithin", "GrugFarFocus" },
	keys = {
		{ "<leader>s", "<cmd>GrugFarFocus<cr>", desc = "[GrugFar] フォーカス" },
	},
	opts = {
		windowCreationCommand = "topleft 60vsplit",
		openTargetWindow = {
			preferredLocation = "right",
		},
	},
	config = function(_, opts)
		local grug = require("grug-far")
		grug.setup(opts)

		vim.api.nvim_create_user_command("GrugFarFocus", function()
			pcall(vim.cmd, "Neotree close")
			if grug.has_instance("main") then
				if not grug.is_instance_open("main") then
					grug.toggle_instance({ instanceName = "main" })
				end
				local inst = grug.get_instance("main")
				local win = vim.fn.bufwinid(inst._buf)
				if win ~= -1 then
					vim.api.nvim_set_current_win(win)
				end
			else
				grug.open({ instanceName = "main" })
			end
		end, { desc = "[GrugFar] 開く or フォーカス移動" })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "grug-far",
			callback = function(ev)
				local function set_paths(paths)
					grug.get_instance(0):update_input_values({ paths = paths }, false)
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
				vim.keymap.set("n", "q", function()
					grug.toggle_instance({ instanceName = "main" })
				end, { buffer = ev.buf, desc = "[GrugFar] 閉じる (状態保持)" })
			end,
		})
	end,
}
