-- walkthrough.nvim
-- コード上のポイント列（ステップ）を順に辿るUIプラグイン。
-- 公開APIとスキーマは README.md を参照。利用者との接点は setup(opts) と公開APIのみ。
--
-- 内部構成:
--   session.lua レジストリ（データ層）  render.lua マーカー描画  float.lua noteフロート
--   nav.lua ジャンプ  picker.lua 一覧UI  ops.lua 破棄  util.lua 小道具

local float = require("walkthrough.float")
local nav = require("walkthrough.nav")
local ops = require("walkthrough.ops")
local picker = require("walkthrough.picker")
local render = require("walkthrough.render")
local session_mod = require("walkthrough.session")
local util = require("walkthrough.util")

local M = {}

local config = {
	-- スキルが生成したJSONの保存ディレクトリ名（対象リポジトリ直下からの相対）。<leader>wo で開く。
	-- 変更する場合はJSONを生成するスキル側の規約も合わせて変えること。
	dir = ".walkthroughs",
	-- true=デフォルトキーマップ / false=無効 / テーブル=個別上書き（false指定でそのキーだけ無効）
	keymaps = true,
}

local default_keymaps = {
	next = "]w",
	prev = "[w",
	steps = "<leader>wl",
	open = "<leader>wo",
	toggle_float = "<leader>wt",
	focus_float = "<leader>w<CR>",
	close = "<leader>wq",
	edit_at_cursor = "<leader>we",
	reload = "<leader>wR",
}

-- --------------------------------------------------------------------------
-- セッション
-- --------------------------------------------------------------------------

--- コアAPI: メモリ上のステップ列からセッションを作成しアクティブ化する
--- spec: { steps (必須), name?, root?, description?, commit?, json_path?, index?, hooks?, pin?, protect_json? }
--- 同名セッションが既にあれば置き換える
function M.start(spec)
	if type(spec) ~= "table" then
		util.notify("start()にはstepsの配列が必要です", vim.log.levels.ERROR)
		return
	end
	local name = spec.name
	if not name or name == "" then
		name = session_mod.next_unnamed()
	end

	local session = session_mod.build(spec, name)
	if not session then
		return
	end
	session_mod.upsert(session)
	session_mod.check_stale(session)
	nav.activate(session)
end

--- セッション更新API（連携用）: name で置き換え、カーソル移動なしで表示だけ差し替える
--- （例: pi-nvim-comment がコメント追加/編集/削除のたびに「pi-comments」を同期）
--- spec は start() と同じ。index 省略時は既存セッションの現在位置を維持。
--- フロートがそのセッションを表示中なら同じステップで再描画する（他セッションの表示は奪わない）
function M.update(spec)
	if type(spec) ~= "table" or type(spec.name) ~= "string" or spec.name == "" then
		util.notify("update()にはnameが必要です", vim.log.levels.ERROR)
		return
	end
	local session = session_mod.build(spec, spec.name)
	if not session then
		return
	end

	local prev = session_mod.upsert(session)
	if prev and spec.index == nil then
		session.index = math.max(1, math.min(prev.index, #session.steps))
	end
	-- アクティブ表示は奪わない: 更新対象が表示中（または何もアクティブでない）ときだけ引き継ぐ
	if (prev and session_mod.get_active() == prev) or session_mod.get_active() == nil then
		session_mod.set_active(session)
	end

	float.refresh_for(prev, session)
	render.refresh()
end

--- セッションを名前で削除する。JSON由来ならファイル自体も削除する
--- （protect_json のセッションはファイルを残す）。連携API
function M.remove(name)
	return ops.remove(name)
end

--- セッションを名前でアクティブ化（現在位置へジャンプ）。連携API
function M.activate(name)
	local session = session_mod.find(name)
	if not session then
		util.notify("セッションが見つかりません: " .. tostring(name), vim.log.levels.WARN)
		return false
	end
	nav.activate(session)
	return true
end

--- アクティブセッションを閉じる（pinセッションは非アクティブ化のみ）
function M.close()
	ops.close_active()
end

--- JSONラッパー: ファイルを読んで start() する
function M.start_file(json_path)
	local spec = session_mod.load_json(json_path)
	if spec then
		M.start(spec)
	end
end

--- アクティブセッションのJSONを再読み込み（現在位置は維持、範囲外ならクランプ）
function M.reload()
	local active = nav.require_active()
	if not active then
		return
	end
	if not active.json_path then
		util.notify("このセッションはファイル由来ではないため再読み込みできません", vim.log.levels.WARN)
		return
	end
	local spec = session_mod.load_json(active.json_path)
	if spec then
		spec.name = active.name
		spec.index = active.index
		M.start(spec)
	end
end

-- --------------------------------------------------------------------------
-- 移動・一覧
-- --------------------------------------------------------------------------
M.next = nav.next
M.prev = nav.prev
M.goto_step = nav.goto_step
M.steps = picker.steps

function M.open()
	local root = util.repo_root(vim.uv.cwd()) or vim.uv.cwd()
	picker.open(root .. "/" .. config.dir)
end

-- --------------------------------------------------------------------------
-- フロート
-- --------------------------------------------------------------------------
M.toggle_float = float.toggle

function M.focus_float()
	if not float.is_open() then
		local active = nav.require_active()
		if not active then
			return
		end
		float.show_active(active)
	end
	float.focus()
end

--- セッション名とステップ番号でnoteフロートを開く（カーソル移動なし・フォーカスもしない）。連携API
--- opts.if_free = true なら、既に何かを表示中のときは開かない（表示中の内容を奪わない）。
--- 表示中のステップの更新は update() が自動で反映するので、ここで呼ぶ必要はない
function M.show(name, idx, opts)
	local session = session_mod.find(name)
	if not session or type(idx) ~= "number" then
		return false
	end
	if opts and opts.if_free and float.is_open() then
		return false
	end
	return float.show(session, idx)
end

--- thread付きステップのフロートで r を押したときの返信ハンドラを登録する。連携API
--- fn(session, idx)。nil で解除
M.set_reply_handler = float.set_reply_handler

-- --------------------------------------------------------------------------
-- ステップアクション
-- --------------------------------------------------------------------------
--- カーソル下のステップ（アクティブ優先・ロード順）の編集アクションを呼ぶ。フロートを開かず hooks.actions.edit へ
function M.edit_at_cursor()
	local session, idx = session_mod.step_at_cursor()
	if not session then
		util.notify("カーソル上にステップがありません（,wtでnote表示はできます）", vim.log.levels.WARN)
		return
	end
	local fn = session_mod.action(session, "edit")
	if not fn then
		util.notify("このセッションに編集アクションがありません: " .. session.name, vim.log.levels.WARN)
		return
	end
	vim.schedule(function()
		fn(session, idx)
	end)
end

--- テスト・連携用の読み取り専用スナップショット
function M.get_state()
	local list = {}
	local active = session_mod.get_active()
	for _, s in ipairs(session_mod.list()) do
		list[#list + 1] = { name = s.name, index = s.index, total = #s.steps, active = s == active, pin = s.pin == true }
	end
	return list
end

-- --------------------------------------------------------------------------
-- setup
-- --------------------------------------------------------------------------
local function apply_keymaps(keys)
	local actions = {
		{ keys.next, M.next, "次のステップ" },
		{ keys.prev, M.prev, "前のステップ" },
		{ keys.steps, M.steps, "ステップ一覧から選んでジャンプ" },
		{ keys.open, M.open, "開く/切り替え（セッション+JSON）" },
		{ keys.toggle_float, M.toggle_float, "noteフロート表示/非表示" },
		{ keys.focus_float, M.focus_float, "noteフロートにフォーカス" },
		{ keys.close, M.close, "セッションを閉じる" },
		{ keys.edit_at_cursor, M.edit_at_cursor, "カーソル下のステップを編集（hooks.actions.edit）" },
		{ keys.reload, M.reload, "JSONを再読み込み" },
	}
	for _, a in ipairs(actions) do
		if a[1] then
			vim.keymap.set("n", a[1], a[2], { silent = true, desc = "[Walkthrough] " .. a[3] })
		end
	end
end

function M.setup(opts)
	opts = opts or {}
	if opts.dir ~= nil then
		config.dir = opts.dir
	end
	if opts.keymaps ~= nil then
		config.keymaps = opts.keymaps
	end

	if config.keymaps ~= false then
		local keys = vim.tbl_extend("force", {}, default_keymaps)
		if type(config.keymaps) == "table" then
			for k, v in pairs(config.keymaps) do
				keys[k] = v ~= false and v or nil
			end
		end
		apply_keymaps(keys)
	end

	vim.api.nvim_create_user_command("Walkthrough", function(args)
		if args.args ~= "" then
			M.start_file(args.args)
		else
			M.open()
		end
	end, { nargs = "?", complete = "file", desc = "[Walkthrough] JSONを指定して開く（無指定はpicker）" })

	-- 後から開いたバッファにもステップのサインを描画する（アクティブ + pinセッション）
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = vim.api.nvim_create_augroup("walkthrough_decorate", { clear = true }),
		callback = function(ev)
			render.decorate_buffer(ev.buf)
		end,
	})
end

return M
