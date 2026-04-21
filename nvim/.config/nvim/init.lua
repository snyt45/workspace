vim.g.mapleader = ","

-- Load settings
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load plugins
require("config.lazy")

require("config.lsp")
require("features.command_palette")
require("features.keymap_picker")
require("features.review")
