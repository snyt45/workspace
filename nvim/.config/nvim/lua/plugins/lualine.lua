return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			globalstatus = true,
		},
		sections = {
			lualine_c = { { "filename", path = 1 } },
			lualine_x = {
				{ function() return require("review").status() end },
				"encoding", "fileformat", "filetype",
			},
		},
		extensions = { "neo-tree", "lazy" },
	},
}
