return {
	"choplin/code-review.nvim",
	cmd = "CodeReview",
	keys = {
		{ "<leader>gc", function() require("code-review").add_comment() end, mode = { "n", "v" }, desc = "[Review] コメント追加" },
		{ "<leader>gl", function() require("code-review").list_comments() end, desc = "[Review] コメント一覧" },
		{
			"<leader>gy",
			function()
				-- minimal形式はPreviewの:wでparseできず全コメントが消えるupstreamバグがあるため、
				-- 全体はdetailedのままコピーの瞬間だけminimalに切り替える
				local conf = require("code-review.config").get_all()
				conf.output = conf.output or {}
				local prev = conf.output.format
				conf.output.format = "minimal"
				local ok, err = pcall(require("code-review").copy)
				conf.output.format = prev
				if not ok then
					vim.notify(tostring(err), vim.log.levels.ERROR)
				end
			end,
			desc = "[Review] レビューをクリップボードへ（AI向けminimal形式）",
		},
		{ "<leader>gd", function() require("code-review").delete_comment_at_cursor() end, desc = "[Review] カーソル行のコメント削除" },
		{ "<leader>gp", function() require("code-review").preview() end, desc = "[Review] プレビュー（編集して:wで反映）" },
	},
	opts = {
		-- デフォルトの<leader>r系は fff(grep) / LSP(rename) と衝突するため無効化
		keymaps = false,
		-- output.format は detailed のまま（minimalにするとPreviewの:wで全コメント消失）
	},
	config = function(_, opts)
		require("code-review").setup(opts)
		-- 入力ウィンドウのsubmitは標準ではC-CRのみで、tmuxが拡張キー未対応のため届かない。
		-- バッファ公開フック b:_code_review_submit を使い normalモードのEnterに確定を割り当てる
		vim.api.nvim_create_autocmd("BufEnter", {
			pattern = "codereview://input/*",
			callback = function(ev)
				vim.keymap.set("n", "<CR>", function()
					if vim.b[ev.buf]._code_review_submit then
						vim.b[ev.buf]._code_review_submit()
					end
				end, { buffer = ev.buf, nowait = true, desc = "[Review] コメント確定" })
			end,
		})
	end,
}
