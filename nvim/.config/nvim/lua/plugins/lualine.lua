return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			globalstatus = true,
		},
		sections = {
			lualine_c = { { "filename", path = 1 } },
			lualine_x = { "encoding", "fileformat", "filetype" },
			lualine_z = {
				"location",
				{
					function() return "  REVIEW: " .. (vim.g.review_base or "") .. "...HEAD" end,
					cond = function() return vim.g.review_base ~= nil end,
					color = { bg = "#fab387", fg = "#1e1e2e", gui = "bold" },
				},
			},
		},
		extensions = { "neo-tree", "lazy" },
	},
}
