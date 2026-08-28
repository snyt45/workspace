-- pi-nvim-comment
-- 実行中のpiセッションへの行コメントレビュー + walkthrough連携。
-- 公開API・キーマップ・設定は README.md 参照。
--
-- 内部構成:
--   state.lua   未提出コメント（extmark追跡・永続化）
--   threads.lua 回答スレッド（.walkthroughs/comments.json の読み書き・監視）
--   sync.lua    walkthroughの「pi-comments」セッションへの同期
--   actions.lua ユーザー操作  prompt.lua 提出プロンプト  modal.lua 入力UI  util.lua 小道具

local actions = require("pi-nvim-comment.actions")
local prompt = require("pi-nvim-comment.prompt")
local state = require("pi-nvim-comment.state")
local sync = require("pi-nvim-comment.sync")
local threads = require("pi-nvim-comment.threads")
local util = require("pi-nvim-comment.util")

local M = {}

M.annotate = actions.annotate
M.submit = actions.submit
M.copy = actions.copy
M.clear = actions.clear
M.purge = actions.purge
M.reply = actions.reply

local default_keymaps = {
	-- 提出は <leader>px（,ps は他プラグイン使用済みのため）
	-- 表示系のキーは持たない: 見る・切替・巡回はすべてwalkthrough側（,wo / ]w 等）
	annotate = "<leader>pa",
	submit = "<leader>px",
	-- 提出内容のコピーは <leader>py（,pc は他プラグイン使用済みのため yank の y）
	copy = "<leader>py",
}

local commands = {
	{ "PiReviewAnnotate", function(args)
		M.annotate(args.line1, args.line2)
	end, { range = true, desc = "Piレビュー: 行/範囲にコメント追加" } },
	{ "PiReviewSubmit", M.submit, { desc = "Piレビュー: コメント提出" } },
	{ "PiReviewClear", M.clear, { desc = "Piレビュー: 未提出コメント破棄" } },
	{ "PiReviewCopy", M.copy, { desc = "Piレビュー: 提出内容をクリップボードにコピー" } },
}

local function apply_keymaps(keys)
	if keys.annotate then
		vim.keymap.set("n", keys.annotate, "<Cmd>PiReviewAnnotate<CR>", { desc = "[Pi] 行にレビューコメント" })
		vim.keymap.set(
			"x",
			keys.annotate,
			":<C-U>'<,'>PiReviewAnnotate<CR>",
			{ desc = "[Pi] 選択範囲にレビューコメント" }
		)
	end
	if keys.submit then
		vim.keymap.set("n", keys.submit, "<Cmd>PiReviewSubmit<CR>", { desc = "[Pi] レビュー提出" })
	end
	if keys.copy then
		vim.keymap.set("n", keys.copy, "<Cmd>PiReviewCopy<CR>", { desc = "[Pi] 提出内容をクリップボードにコピー" })
	end
end

local function create_autocmds()
	local group = vim.api.nvim_create_augroup("pi_nvim_comment", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			state.save()
			threads.stop_watch()
		end,
	})
	-- state復元時のバッファは未ロードでextmarkを張れない。開かれた時点で張り直して行追従を有効にする
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		callback = function(ev)
			state.attach_marks(ev.buf)
		end,
	})
end

-- piが回答を書き込んだときの反映。ベースライン取り込み（primed=false）では通知しない
local function on_answers(primed)
	local changed = sync.refresh()
	if primed and changed then
		util.notify("Pi回答を反映（フロート更新: r=返信 / q=閉じる）")
		sync.show(changed)
	end
end

local did_setup = false

function M.setup(opts)
	if did_setup then
		return
	end
	did_setup = true
	opts = opts or {}

	prompt.configure(opts)

	for _, command in ipairs(commands) do
		vim.api.nvim_create_user_command(command[1], command[2], command[3])
	end

	if opts.keymaps ~= false then
		local keys = vim.tbl_extend("force", {}, default_keymaps)
		if type(opts.keymaps) == "table" then
			for k, v in pairs(opts.keymaps) do
				keys[k] = v ~= false and v or nil
			end
		end
		apply_keymaps(keys)
	end

	create_autocmds()

	state.load()
	sync.refresh()

	-- thread付きステップのフロートで r=返信 を有効にする
	local ok, wt = pcall(require, "walkthrough")
	if ok and type(wt.set_reply_handler) == "function" then
		wt.set_reply_handler(M.reply)
	end

	-- 回答（.walkthroughs/comments.json）の変更を監視し、pi-commentsへ自動反映する
	threads.start_watch(on_answers)
end

return M
