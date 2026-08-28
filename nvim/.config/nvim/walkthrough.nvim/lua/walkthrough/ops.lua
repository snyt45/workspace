-- walkthrough.nvim / ops
-- セッションの破棄。JSONファイルや連携先の実データを消すため、経路は必ずここに集約する。

local float = require("walkthrough.float")
local render = require("walkthrough.render")
local session_mod = require("walkthrough.session")
local util = require("walkthrough.util")

local M = {}

local function forget(session)
	local shown = float.showing()
	if not session_mod.unregister(session) then
		return false
	end
	if shown == session then
		float.close()
	end
	render.refresh()
	return true
end

--- セッションを名前で削除する。JSON由来ならファイル自体も削除する
--- （protect_json のセッションはファイルを残す。実データの削除は purge アクションの担当）
function M.remove(name)
	local session = type(name) == "string" and session_mod.find(name) or nil
	if not session then
		return false
	end
	if session.json_path and not session.protect_json then
		os.remove(session.json_path)
	end
	return forget(session)
end

--- picker から選ばれたセッションを削除する（確認あり）。
--- protect_json の連携セッション（pi-comments等）は purge アクションに実データの削除を委ねる
function M.delete_session(session)
	local purge = session_mod.action(session, "purge")
	if session.protect_json and not purge then
		util.notify("このセッションは削除できません（purgeアクションなし）", vim.log.levels.WARN)
		return false
	end

	local prompt = purge
			and ("%s の内容（コメント・返信・スレッド）をすべて削除します。元に戻せません。"):format(session.name)
		or ("%s を削除します（JSONごと）。"):format(session.name)
	if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
		return false
	end

	if purge then
		pcall(purge, session, session.index)
	else
		M.remove(session.name)
	end
	util.notify("削除しました: " .. session.name)
	return true
end

--- アクティブセッションを閉じる（pinセッションは非アクティブ化のみ）
function M.close_active()
	local active = session_mod.get_active()
	if not active then
		float.close()
		render.refresh()
		return
	end
	local name = active.name
	if active.pin then
		-- pinセッションはレジストリに残す（マークも表示されたまま）。,wo で戻れる
		session_mod.set_active(nil)
		float.close()
		render.refresh()
		util.notify(("セッションを非アクティブ化しました: %s（,woで戻れます）"):format(name))
		return
	end
	forget(active)
	util.notify(("セッションを閉じました: %s（残り%d）"):format(name, #session_mod.list()))
end

return M
