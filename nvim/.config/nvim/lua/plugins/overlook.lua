return {
	"WilliamHsieh/overlook.nvim",
	opts = {},
	keys = {
		{ "<leader>pd", function() require("overlook.api").peek_definition() end,         desc = "[Overlook] 定義をpeek" },
		{ "<leader>pp", function() require("overlook.api").peek_cursor() end,             desc = "[Overlook] カーソル位置をpeek" },
		{ "<leader>pu", function() require("overlook.api").restore_popup() end,           desc = "[Overlook] 直前のpopupを復元" },
		{ "<leader>pU", function() require("overlook.api").restore_all_popups() end,      desc = "[Overlook] 全popupを復元" },
		{ "<leader>pc", function() require("overlook.api").close_all() end,               desc = "[Overlook] 全popupを閉じる" },
		{ "<leader>pf", function() require("overlook.api").switch_focus() end,            desc = "[Overlook] popupとrootをフォーカス切替" },
		{ "<leader>ps", function() require("overlook.api").open_in_split() end,           desc = "[Overlook] popupを水平分割で開く" },
		{ "<leader>pv", function() require("overlook.api").open_in_vsplit() end,          desc = "[Overlook] popupを垂直分割で開く" },
		{ "<leader>pt", function() require("overlook.api").open_in_tab() end,             desc = "[Overlook] popupを新規タブで開く" },
		{ "<leader>po", function() require("overlook.api").open_in_original_window() end, desc = "[Overlook] popupを元ウィンドウで開く" },
	},
}
