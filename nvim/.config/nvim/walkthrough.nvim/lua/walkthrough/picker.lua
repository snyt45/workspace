-- walkthrough.nvim / picker
-- ステップ一覧（<leader>wl）と統合picker（<leader>wo）。snacksがあれば使い、なければ vim.ui.select。

local float = require("walkthrough.float")
local nav = require("walkthrough.nav")
local ops = require("walkthrough.ops")
local session_mod = require("walkthrough.session")
local util = require("walkthrough.util")

local M = {}

local function snacks_picker()
	local ok, snacks = pcall(require, "snacks")
	return ok and snacks.picker or nil
end

--- アクティブセッションのステップ一覧から選んでジャンプする（noteプレビュー付き）
function M.steps()
	local active = nav.require_active()
	if not active then
		return
	end

	local items = {}
	for i, step in ipairs(active.steps) do
		local text = step.note or ""
		if util.has_thread(step) then
			-- スレッドは最新の発言を要約に出す
			text = string.format("💬%d %s", #step.thread, step.thread[#step.thread].text or "")
		end
		local summary = text:gsub("%s+", " ")
		if vim.fn.strchars(summary) > 60 then
			summary = vim.fn.strcharpart(summary, 0, 60) .. "…"
		end
		items[#items + 1] = {
			idx = i,
			text = string.format("%s %d  %s:%d  %s", i == active.index and "●" or " ", i, step.file, step.line, summary),
			preview = { text = float.preview_text(step), ft = "markdown", loc = false },
		}
	end

	local picker = snacks_picker()
	if picker then
		picker.pick({
			title = "Walkthrough: " .. active.name,
			items = items,
			format = "text",
			preview = "preview",
			confirm = function(p, item)
				p:close()
				if item then
					vim.schedule(function()
						nav.jump_to(active, item.idx)
					end)
				end
			end,
		})
		return
	end

	vim.ui.select(items, {
		prompt = "ステップ一覧: " .. active.name,
		format_item = function(item)
			return item.text
		end,
	}, function(choice)
		if choice then
			nav.jump_to(active, choice.idx)
		end
	end)
end

-- ロード済みセッション（位置保持で切替）+ 保存ディレクトリの未ロードJSON（新規ロード）
local function collect(dir)
	local items = {}
	local loaded = {}
	local active = session_mod.get_active()
	for _, s in ipairs(session_mod.list()) do
		items[#items + 1] = {
			kind = "session",
			session = s,
			text = string.format("%s%s  [%d/%d]", s == active and "● " or "  ", s.name, s.index, #s.steps),
		}
		if s.json_path then
			loaded[s.json_path] = true
		end
	end

	local files = vim.fn.glob(dir .. "/*.json", false, true)
	table.sort(files, function(a, b)
		local sa, sb = vim.uv.fs_stat(a), vim.uv.fs_stat(b)
		return (sa and sa.mtime.sec or 0) > (sb and sb.mtime.sec or 0)
	end)
	for _, f in ipairs(files) do
		if not loaded[vim.fn.fnamemodify(f, ":p")] then
			local stat = vim.uv.fs_stat(f)
			items[#items + 1] = {
				kind = "file",
				path = f,
				text = string.format(
					"  %s  (%s · 未ロード)",
					vim.fn.fnamemodify(f, ":t:r"),
					stat and os.date("%m/%d %H:%M", stat.mtime.sec) or "?"
				),
			}
		end
	end
	return items
end

local function choose(item)
	if not item then
		return
	end
	if item.kind == "session" then
		nav.activate(item.session)
	else
		require("walkthrough").start_file(item.path)
	end
end

--- 選択項目を削除する（確認あり）。削除できたら true
local function delete(item)
	if item.kind == "session" then
		return ops.delete_session(item.session)
	end
	local name = vim.fn.fnamemodify(item.path, ":t:r")
	if vim.fn.confirm(("%s を削除します（JSONごと）。"):format(name), "&Yes\n&No", 2) ~= 1 then
		return false
	end
	os.remove(item.path)
	util.notify("削除しました: " .. name)
	return true
end

--- 統合picker: セッション切替 + 未ロードJSONのロード。<c-d>（一覧では d）で削除
function M.open(dir)
	local items = collect(dir)
	if #items == 0 then
		util.notify("walkthroughがありません: " .. dir, vim.log.levels.WARN)
		return
	end

	local picker = snacks_picker()
	if picker then
		picker.pick({
			title = "Walkthrough",
			items = items,
			format = "text",
			confirm = function(p, item)
				p:close()
				vim.schedule(function()
					choose(item)
				end)
			end,
			actions = {
				remove = function(p)
					local item = p:current()
					p:close()
					if item then
						vim.schedule(function()
							delete(item)
							M.open(dir) -- 一覧から消えた状態で開き直す
						end)
					end
				end,
			},
			win = {
				input = { keys = { ["<c-d>"] = { "remove", mode = { "n", "i" }, desc = "Walkthrough削除" } } },
				list = { keys = { ["d"] = { "remove", mode = "n", desc = "Walkthrough削除" } } },
			},
		})
		return
	end

	vim.ui.select(items, {
		prompt = "Walkthrough",
		format_item = function(item)
			return item.text
		end,
	}, choose)
end

return M
