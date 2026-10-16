return {
	"dlyongemallo/diffview-plus.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
	keys = {
		{ "<leader>gg", function() require("features.review").code_diff() end, desc = "[Diffview] 全差分 (レビューモード時はbase...HEAD)" },
		{ "<leader>gf", function() require("features.review").code_diff_file() end, desc = "[Diffview] 現バッファの単一ファイル差分 (レビューモード時はbase...HEAD)" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "[Diffview] 履歴" },
	},
	opts = {
		view = {
			-- 1画面unified で開き、g<C-x> で左右2画面と切り替える
			default = { layout = "diff1_inline" },
			file_history = { layout = "diff1_inline" },
			cycle_layouts = {
				default = { "diff1_inline", "diff2_horizontal" },
			},
			-- 新規・削除ファイルは空ペインを出さず1画面で表示する
			one_sided_layout = "raw",
			-- unified で変更のない部分を折りたたむ（zo / zR で開く）
			inline = { fold_unchanged = true },
			-- 差分ウィンドウでの定義ジャンプなどでレイアウトが崩れる代わりにエラーで止める
			winfixbuf = true,
		},
		-- w で選んだファイルと H で隠した状態を再起動後も残す
		persist_selections = { enabled = true },
		keymaps = {
			view = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
		},
		hooks = {
			diff_buf_win_enter = function(bufnr, winid, ctx)
				-- Turn off cursor line for diffview windows because of bg conflict
				-- https://github.com/neovim/neovim/issues/9800
				vim.wo[winid].culopt = 'number'
			end,
		},
	},
}
