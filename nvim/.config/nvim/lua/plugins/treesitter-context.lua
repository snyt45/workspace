-- スクロールしても、画面の上端がどのクラス・メソッドの中かを、定義行を上に残して示す（1行目がクラス、2行目がメソッド）
-- 何を残すか（クラス・メソッドだけ。if や case は残さない）は queries/<言語>/context.scm で決めている
return {
	"nvim-treesitter/nvim-treesitter-context",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	-- 起動時から有効にする（,uc は一時的に消したいとき用）
	lazy = false,
	keys = {
		{ "<leader>uc", "<cmd>TSContext toggle<cr>", desc = "[Context] 上に残す定義行の表示を切り替える" },
	},
	config = function()
		require("treesitter-context").setup({
			-- カーソルの位置ではなく、画面の一番上の行を基準にする。
			-- カーソル基準だと、カーソルが別のメソッドや空行にあるときに出たり消えたりする
			mode = "topline",
			-- 残すのは2行。1行目がクラス、2行目がメソッド。
			-- module > class > method のように3段以上あるときは、外側から削る（trim_scope = "outer"）
			max_lines = 2,
			trim_scope = "outer",
			multiline_threshold = 1,
		})

		-- 背景が透過だと張り付いた行が本文と見分けられないので、背景色を付ける
		local C = require("catppuccin.palettes").get_palette("mocha")
		local set_hl = function()
			vim.api.nvim_set_hl(0, "TreesitterContext", { bg = C.surface0 })
			vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { fg = C.overlay1, bg = C.surface0 })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
	end,
}
