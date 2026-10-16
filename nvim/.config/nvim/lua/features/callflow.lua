-- カーソル下の関数に、入口からどう呼ばれてたどり着くかを調べる
-- 呼び出し元を裏でさかのぼって入口までの道筋を全部集め、ピッカーで絞り込む（右に木のプレビュー）
-- 呼び出し元は LSP の call hierarchy（TS など）、無ければ cymbal（名前で探す。Ruby など）で調べる
--
-- 道筋が少なければ全部まとめた木を開き、多ければ先にピッカーで絞り込む（右に木のプレビュー）
-- ピッカー: <CR> 選んだ道筋を木で開く / <C-t> 絞り込んだ道筋を全部まとめた木で開く
-- 木: <CR> その場所へ / zc・zo で畳む・開く / q で閉じる。M.reopen で直前の木を開き直す
local M = {}

local MAX_DEPTH = 8 -- さかのぼる段数
local MAX_PATHS = 300 -- 道筋の数の上限
local PICK_OVER = 30 -- 道筋がこれより多いときだけ、先にピッカーで絞り込む

-- 一番上で止まった理由。入口（呼び出し元が無い）なら付けない
local STOP_LABEL = {
	depth = "⚠ 段数の上限",
	ambiguous = "⚠ 同名が多く打ち切り",
	cycle = "↺ 再帰",
	body = "（メソッドの外: scope・コールバックなど）",
}

local function lsp_client(buf)
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		if c:supports_method("callHierarchy/incomingCalls") then
			return c
		end
	end
end

-- node: { name, path, lnum, item?, stop? }。path/lnum は「下の関数を呼んでいる場所」（起点は定義かカーソルの位置）
local function node_from_item(item, lnum)
	return { name = item.name, path = vim.uri_to_fname(item.uri), lnum = lnum or item.selectionRange.start.line + 1, item = item }
end

-- 以下は collect の coroutine の中で呼ぶ。完了を待つ間は yield する
local function await(fn)
	local co = coroutine.running()
	fn(function(...)
		local args = { ... }
		vim.schedule(function()
			-- coroutine 内のエラーは握りつぶされるので通知する
			local ok, err = coroutine.resume(co, unpack(args))
			if not ok then
				vim.notify("callflow: " .. tostring(err), vim.log.levels.ERROR)
			end
		end)
	end)
	return coroutine.yield()
end

local function cymbal(state, args)
	local res = await(function(cb)
		vim.system(vim.list_extend({ "cymbal" }, args), { cwd = state.root, text = true }, cb)
	end)
	local ok, data = pcall(vim.json.decode, res.stdout or "")
	return ok and data.results or {}
end

-- path の中で lnum を囲む一番内側のメソッド・関数（cymbal outline をファイルごとに覚えておく）
-- メソッドの外（scope の lambda やクラス直下）なら、囲んでいるクラス・モジュールを body = true で返す
local function enclosing(state, path, lnum)
	state.outlines[path] = state.outlines[path] or cymbal(state, { "outline", "--json", path })
	local best, owner
	for _, sym in ipairs(state.outlines[path]) do
		if sym.start_line <= lnum and lnum <= sym.end_line then
			local callable = sym.kind == "method" or sym.kind == "function"
			if callable and (not best or sym.start_line > best.start_line) then
				best = sym
			elseif (sym.kind == "class" or sym.kind == "module") and (not owner or sym.start_line > owner.start_line) then
				owner = sym
			end
		end
	end
	if best then
		return best
	end
	return owner and { name = owner.name, start_line = owner.start_line, body = true }
end

-- app/models/point_grant_receipt_builder.rb → PointGrantReceiptBuilder / point_grant_receipt_builder
local function names_of(path)
	local snake = vim.fn.fnamemodify(path, ":t:r")
	return (snake:gsub("^%l", string.upper):gsub("_(%w)", string.upper)), snake
end

-- 名前だけでは Hash#merge のような別物も拾うので、定義しているクラスへの呼び出しらしいものだけ残す
--   同じファイル内で受け手なし・self.merge（self への呼び出し） / User.merge / user.merge・current_user.merge・@user.merge
local function likely_call(row, name, def_path)
	local text = row.context and row.context[1] or ""
	if row.file == def_path then
		local pat = vim.pesc(name) .. "%f[^%w_?!]"
		-- 行頭か、. 以外の文字のあとに名前があれば受け手なしの呼び出し
		if text:find("^%s*" .. pat) or text:find("[^%.%w_@]" .. pat) or text:find("self%." .. pat) then
			return true
		end
	end
	local const, snake = names_of(def_path)
	if text:find(const .. "." .. name, 1, true) then
		return true
	end
	for recv in text:gmatch("([@%w_]+)%." .. vim.pesc(name) .. "%f[^%w_]") do
		recv = recv:gsub("^@+", "")
		if recv == snake or recv:sub(-#snake - 1) == "_" .. snake then
			return true
		end
	end
	return false
end

-- node の呼び出し元を返す。2つ目の返り値は打ち切った理由
local function callers(state, node)
	if state.client then
		local result = await(function(cb)
			state.client:request("callHierarchy/incomingCalls", { item = node.item }, function(_, r)
				cb(r)
			end)
		end)
		local list = {}
		for _, call in ipairs(result or {}) do
			-- 同じ関数から何度呼んでいても1つにする（最初の呼び出し位置）
			local r = call.fromRanges[1]
			table.insert(list, node_from_item(call.from, r and r.start.line + 1))
		end
		return list
	end
	-- impact は呼び出し元が同じ名前のメソッドだと再帰とみなして落とすので、refs から自分で呼び出し元を引く
	local rows = cymbal(state, { "refs", "--json", "--context", "0", "--limit", "500", node.name })
	local defs = cymbal(state, { "search", "--json", "--exact", "--limit", "50", node.name })
	-- 定義が複数あるか、参照が多い（Ruby 本体やライブラリと同名）なら呼び出し先を推測で絞る
	local ambiguous = #defs > 1 or #rows >= 30
	-- 定義が1つならそのファイルを定義元とする（カーソルが呼び出し側にあっても正しく絞れる）
	local def_path = #defs == 1 and defs[1].file or node.def_path
	local list, seen = {}, {}
	for _, row in ipairs(rows) do
		if not ambiguous or likely_call(row, node.name, def_path) then
			local sym = enclosing(state, row.file, row.line)
			local key = sym and sym.name .. "\0" .. row.file
			-- 定義の行そのものは呼び出しではない。同じ関数から何度呼んでいても1つにする
			if sym and not (sym.name == node.name and sym.start_line == row.line) and not seen[key] then
				seen[key] = true
				-- メソッドの外からの呼び出しは、それより上をたどれないのでそこで止める
				table.insert(list, { name = sym.name, path = row.file, lnum = row.line, def_path = row.file, stop = sym.body and "body" or nil })
			end
		end
	end
	local stop = #list == 0 and #rows > 0 and ambiguous and "ambiguous" or nil
	-- Rails のアクションとジョブの perform は外から呼ばれる入口なので、同名の打ち切りではなく入口として扱う
	if stop and (node.path:find("/app/controllers/", 1, true) or node.path:find("/app/jobs/", 1, true)) then
		stop = nil
	end
	return list, stop
end

-- 起点から呼び出し元を裏でさかのぼり、入口 → 起点 の道筋を全部集めて done(paths, truncated) を呼ぶ
local function collect(state, start, done)
	local paths, truncated, memo = {}, false, {}
	state.outlines = {}
	local function walk(chain)
		if #paths >= MAX_PATHS then
			truncated = true
			return
		end
		local top = chain[1]
		if top.stop == "body" then
			return table.insert(paths, chain)
		end
		local key = top.name .. "\0" .. top.path
		memo[key] = memo[key] or { callers(state, top) }
		local list, stop = unpack(memo[key])
		if #chain > MAX_DEPTH then
			-- 上限に達しても、呼び出し元が無ければ本当の入口なので印は付けない
			top.stop = #list > 0 and "depth" or stop
			return table.insert(paths, chain)
		end
		local grew = false
		for _, c in ipairs(list) do
			local seen = false
			for _, n in ipairs(chain) do
				seen = seen or (n.name == c.name and n.path == c.path)
			end
			if not seen then
				grew = true
				walk(vim.list_extend({ vim.deepcopy(c) }, chain))
			end
		end
		if not grew then
			top.stop = stop or (#list > 0 and "cycle" or nil)
			table.insert(paths, chain)
		end
	end
	local co = coroutine.create(function()
		walk({ start })
		done(paths, truncated)
	end)
	-- coroutine 内のエラーは握りつぶされるので通知する
	local ok, err = coroutine.resume(co)
	if not ok then
		vim.notify("callflow: " .. tostring(err), vim.log.levels.ERROR)
	end
end

local function rel(state, path)
	return vim.fs.relpath(state.root, path) or path
end

-- 道筋（入口 → 起点）を、共通の入口をまとめた木の行にする
--   registerEmailRoutes          src/registerEmailRoutes.tsx:12
--   ├─ SignInScreen              src/screens/SignInScreen.tsx:20
--   │  └─ useSignInScreen        src/hooks/useSignInScreen.ts:7
--   └─ SignUpScreen              ...
-- 返り値: lines, extmarks（preview 用の形）, nodes（行ごとの node）, levels（行ごとの深さ）
local function build_tree(state, chains)
	local root = { children = {}, order = {} }
	for _, chain in ipairs(chains) do
		local t = root
		for _, n in ipairs(chain) do
			local key = n.name .. "\0" .. n.path -- 同じ関数は呼んでいる行が違っても1つにまとめる
			if not t.children[key] then
				t.children[key] = { node = n, children = {}, order = {} }
				table.insert(t.order, key)
			end
			t = t.children[key]
		end
	end

	local rows = {}
	local function walk(t, prefix, depth)
		for i, key in ipairs(t.order) do
			local child, last = t.children[key], i == #t.order
			local branch = depth == 0 and "" or (last and "└─ " or "├─ ")
			local label = child.node.name .. (child.node.stop and "  " .. STOP_LABEL[child.node.stop] or "")
			table.insert(rows, { guide = prefix .. branch, label = label, node = child.node, depth = depth, leaf = #child.order == 0 })
			walk(child, depth == 0 and "" or prefix .. (last and "   " or "│  "), depth + 1)
		end
	end
	walk(root, "", 0)

	local width = 0
	for _, r in ipairs(rows) do
		width = math.max(width, vim.fn.strdisplaywidth(r.guide .. r.label))
	end
	local lines, extmarks, nodes, levels = {}, {}, {}, {}
	for i, r in ipairs(rows) do
		local head = r.guide .. r.label
		local loc = ("%s:%d"):format(rel(state, r.node.path), r.node.lnum)
		lines[i] = head .. string.rep(" ", width - vim.fn.strdisplaywidth(head) + 2) .. loc
		nodes[i], levels[i] = r.node, r.depth
		local name_end = #r.guide + #r.node.name
		table.insert(extmarks, { row = i, col = 0, end_col = #r.guide, hl_group = "NonText" })
		table.insert(extmarks, { row = i, col = #r.guide, end_col = name_end, hl_group = r.leaf and "Title" or "Function" })
		table.insert(extmarks, { row = i, col = name_end, end_col = #head, hl_group = "WarningMsg" })
		table.insert(extmarks, { row = i, col = #head, end_col = #lines[i], hl_group = "Comment" })
	end
	return lines, extmarks, nodes, levels
end

local ns = vim.api.nvim_create_namespace("callflow")

function M.foldexpr(lnum)
	local levels = vim.b.callflow_levels or {}
	local this, next = levels[lnum] or 0, levels[lnum + 1] or 0
	return next > this and ">" .. (this + 1) or tostring(this)
end

local last -- 直前に開いた木（開き直す用）

local function show(state, chains, title, cursor)
	last = { state = state, chains = chains, title = title, cursor = cursor or 1 }
	local lines, extmarks, nodes, levels = build_tree(state, chains)
	local win = Snacks.win({
		text = lines,
		title = title,
		width = 0.8,
		height = math.min(#lines + 2, math.floor(vim.o.lines * 0.7)),
		border = "rounded",
		wo = {
			wrap = false,
			cursorline = true,
			foldmethod = "expr",
			foldexpr = "v:lua.require'features.callflow'.foldexpr(v:lnum)",
			foldlevel = 99,
			foldtext = "",
		},
		keys = {
			q = "close",
			["<CR>"] = function(self)
				local row = vim.api.nvim_win_get_cursor(0)[1]
				local n = nodes[row]
				-- 開き直したとき同じ行に戻れるよう覚えておく
				last.cursor = row
				self:close()
				vim.cmd.edit(vim.fn.fnameescape(n.path))
				vim.api.nvim_win_set_cursor(0, { n.lnum, 0 })
				vim.cmd("normal! zz")
			end,
		},
	})
	vim.b[win.buf].callflow_levels = levels
	-- 窓を作った時点では深さが未設定なので、折りたたみを計算し直す
	vim.api.nvim_win_call(win.win, function()
		vim.cmd("normal! zx")
	end)
	for _, e in ipairs(extmarks) do
		vim.api.nvim_buf_set_extmark(win.buf, ns, e.row - 1, e.col, { end_col = e.end_col, hl_group = e.hl_group })
	end
	vim.api.nvim_win_set_cursor(win.win, { math.min(last.cursor, #lines), 0 })
end

function M.reopen()
	if not last then
		return vim.notify("まだ呼び出しの流れを開いていない", vim.log.levels.INFO)
	end
	show(last.state, last.chains, last.title, last.cursor)
end

local function pick(state, start)
	vim.notify(("%s の呼び出し元を調べています…"):format(start.name), vim.log.levels.INFO)
	collect(state, start, function(paths, truncated)
		if #paths == 1 and #paths[1] == 1 and not paths[1][1].stop then
			return vim.notify(("%s の呼び出し元は見つからない"):format(start.name), vim.log.levels.INFO)
		end
		local title = ("%s への道筋 %d 本%s"):format(start.name, #paths, truncated and "（上限で打ち切り）" or "")
		if #paths <= PICK_OVER then
			return show(state, paths, " " .. title .. " ")
		end
		local items = {}
		for i, chain in ipairs(paths) do
			local names = vim.tbl_map(function(n)
				return n.name
			end, chain)
			local lines, extmarks = build_tree(state, { chain })
			items[i] = {
				-- 入口のファイル名でも絞れるよう、入口の場所も並べる
				text = table.concat(names, " › ") .. "    " .. rel(state, chain[1].path),
				chain = chain,
				preview = { text = table.concat(lines, "\n"), extmarks = extmarks, loc = false },
			}
		end
		Snacks.picker.pick({
			title = title,
			items = items,
			format = "text",
			preview = "preview",
			confirm = function(picker, item)
				picker:close()
				if item then
					show(state, { item.chain }, " 呼び出しの流れ ")
				end
			end,
			actions = {
				callflow_tree = function(picker)
					local chains = vim.tbl_map(function(item)
						return item.chain
					end, picker:items())
					picker:close()
					show(state, chains, (" 呼び出しの流れ（%d 本） "):format(#chains))
				end,
			},
			win = { input = { keys = { ["<C-t>"] = { "callflow_tree", mode = { "i", "n" } } } } },
		})
	end)
end

-- cymbal で調べるときの起点。カーソルが定義ではなく呼び出し（user.merge）の上なら、
-- 受け手の名前（user / current_user / @user）から呼ばれる側の定義（user.rb の merge）を起点にする
local function start_node(state, buf, word, line)
	local path, lnum = vim.api.nvim_buf_get_name(buf), vim.fn.line(".")
	if line:match("^%s*def%s+[%w_.]*" .. vim.pesc(word) .. "%f[^%w_?!]") then
		return { name = word, path = path, lnum = lnum, def_path = path }
	end
	local res = vim.system({ "cymbal", "search", "--json", "--exact", "--limit", "50", word }, { cwd = state.root, text = true }):wait()
	local ok, data = pcall(vim.json.decode, res.stdout or "")
	local defs = ok and data.results or {}
	local recv = line:match("([@%w_]+)%." .. vim.pesc(word) .. "%f[^%w_?!]")
	recv = recv and recv:gsub("^@+", "")
	for _, d in ipairs(defs) do
		local snake = vim.fn.fnamemodify(d.file, ":t:r")
		if #defs == 1 or (recv and (recv == snake or recv:sub(-#snake - 1) == "_" .. snake)) then
			return { name = word, path = d.file, lnum = d.start_line, def_path = d.file }
		end
	end
	return { name = word, path = path, lnum = lnum, def_path = path }
end

function M.callers()
	local buf = vim.api.nvim_get_current_buf()
	local word = vim.fn.expand("<cword>")
	if word == "" then
		return
	end
	local state = { root = vim.fs.root(buf, ".git") or vim.fn.getcwd(), client = lsp_client(buf) }
	if not state.client then
		if vim.fn.executable("cymbal") == 0 then
			return vim.notify("cymbal が無い（brew install cymbal）", vim.log.levels.WARN)
		end
		-- Ruby の valid? / save! は <cword> に ? ! が入らないので、直後の1文字を足す
		local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
		local tail = line:sub(col):match("^[%w_]*([?!])")
		word = word .. (tail or "")
		return pick(state, start_node(state, buf, word, line))
	end
	local params = vim.lsp.util.make_position_params(0, state.client.offset_encoding)
	state.client:request("textDocument/prepareCallHierarchy", params, function(_, result)
		if not result or not result[1] then
			return vim.notify(("%s は LSP で関数として見つからない（オブジェクトのプロパティの関数などは非対応）。呼んでいる側の関数で試す"):format(word), vim.log.levels.INFO)
		end
		pick(state, node_from_item(result[1]))
	end, buf)
end

return M
