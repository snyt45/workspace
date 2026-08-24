vim.g.mapleader = ","

-- Load settings
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load plugins
require("config.lazy")

require("config.lsp")
require("features.palette")
require("features.review")
