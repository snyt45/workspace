return {
	"carderne/pi-nvim",
	-- nvimから実行中のpiセッションへファイル/選択/プロンプトを送る（拡張がソケットを開く）
	-- ,P: 送信ダイアログ / ,PS: セッション切替（:PiSendFile / :PiSendSelection / :PiSendBuffer も可）
	-- 注意: 小文字の <leader>p は overlook の pd/pp/pu 等と衝突するため大文字Pを使用
	event = "VeryLazy",
	keys = {
		{ "<leader>P", ":Pi<CR>", desc = "[Pi] 送信ダイアログ" },
		{ "<leader>P", ":Pi<CR>", mode = "v", desc = "[Pi] 選択を送信" },
		{ "<leader>PS", ":PiSessions<CR>", desc = "[Pi] セッション切替" },
	},
	config = function()
		require("pi-nvim").setup({
			set_default_keymaps = false,
		})
	end,
}