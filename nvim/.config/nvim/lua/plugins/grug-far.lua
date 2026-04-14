return {
	"MagicDuck/grug-far.nvim",
	cmd = { "GrugFar", "GrugFarWithin" },
	keys = {
		{ "<leader>sr", function() require("grug-far").open() end, desc = "[GrugFar] 検索・置換" },
		{ "<leader>sw", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "[GrugFar] カーソル下の単語で検索" },
		{ "<leader>sd", function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%:p:h") } }) end, desc = "[GrugFar] 現在のディレクトリ内で検索" },
	},
	opts = {},
}
