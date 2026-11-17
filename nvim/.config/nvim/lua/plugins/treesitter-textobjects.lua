-- メソッド・クラスを1つの単位として選ぶ・移動する（treesitter の構文木を使う）
-- 例: vaf でメソッド全体を選択 → ,ai で Claude に渡す / daf で削除 / ]m で次のメソッドへ
return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = "VeryLazy",
	init = function()
		-- Ruby の ftplugin が持つ ]m・am などと重なるので、そちらを止めて全言語で同じ動きにする
		vim.g.no_ruby_maps = true
	end,
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				-- カーソルが外にあっても、先にある対象を選ぶ
				lookahead = true,
				-- メソッドとクラスの全体は行単位で選ぶ
				selection_modes = {
					["@function.outer"] = "V",
					["@class.outer"] = "V",
				},
			},
			move = { set_jumps = true },
		})

		local map = vim.keymap.set
		local function select(lhs, query, desc)
			map({ "x", "o" }, lhs, function()
				require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
			end, { desc = "[Textobject] " .. desc })
		end
		select("af", "@function.outer", "メソッド全体")
		select("if", "@function.inner", "メソッドの中身")
		select("ac", "@class.outer", "クラス全体")
		select("ic", "@class.inner", "クラスの中身")

		map({ "n", "x", "o" }, "]m", function()
			require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
		end, { desc = "[Textobject] 次のメソッドへ" })
		map({ "n", "x", "o" }, "[m", function()
			require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
		end, { desc = "[Textobject] 前のメソッドへ" })
	end,
}
