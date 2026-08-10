return {
	"cursortab/cursortab.nvim",
	-- 節約のためデフォルト無効。使いたいセッションでのみ :CursortabToggle
	cmd = "CursortabToggle",
	build = "cd server && go build",
	config = function()
		require("cursortab").setup({
			enabled = false,
			provider = {
				type = "mercuryapi",
				api_key_env = "MERCURY_AI_TOKEN",
			},
		})
	end,
}
