return {
	"b0o/incline.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	config = function()
		local devicons = require("nvim-web-devicons")
		local C = require("catppuccin.palettes").get_palette("mocha")

		local set_hl = function()
			vim.api.nvim_set_hl(0, "InclineNormal", { fg = C.text, bg = C.surface0 })
			vim.api.nvim_set_hl(0, "InclineNormalNC", { fg = C.overlay1, bg = C.mantle })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

		require("incline").setup({
			window = {
				winhighlight = {
					active = { Normal = "InclineNormal" },
					inactive = { Normal = "InclineNormalNC" },
				},
			},
			render = function(props)
				local full = vim.api.nvim_buf_get_name(props.buf)
				if full == "" then
					return { { "[No Name]" } }
				end
				local relative = vim.fn.fnamemodify(full, ":~:.")
				local filename = vim.fn.fnamemodify(relative, ":t")
				local dir = vim.fn.fnamemodify(relative, ":h")
				dir = (dir == "." or dir == "") and "" or (dir .. "/")
				local ext = vim.fn.fnamemodify(filename, ":e")
				local icon, color = devicons.get_icon_color(filename, ext, { default = true })
				return {
					{ icon, guifg = color },
					{ " " .. dir, guifg = C.overlay0 },
					{ filename },
				}
			end,
		})
	end,
}
