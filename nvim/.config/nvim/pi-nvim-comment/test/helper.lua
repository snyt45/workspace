-- テスト共通ヘルパ。run.sh が各テストより先に luafile し、グローバル H を用意する。
-- rtp は自分の位置から解決するので、~/.config へリンクしていなくても dotfiles 上で直接実行できる。
local H = {}

local here = debug.getinfo(1, "S").source:sub(2)
H.plugin = vim.fn.fnamemodify(here, ":h:h") -- .../pi-nvim-comment
H.nvim_dir = vim.fn.fnamemodify(H.plugin, ":h") -- .../nvim
vim.opt.rtp:prepend(H.plugin)
vim.opt.rtp:prepend(H.nvim_dir .. "/walkthrough.nvim")

H.tmp = assert(vim.env.PI_TEST_DIR, "PI_TEST_DIR missing")
assert(vim.fn.isdirectory(H.tmp) == 1, "PI_TEST_DIR is not a directory: " .. H.tmp)
H.json = H.tmp .. "/.walkthroughs/comments.json"
H.state_file = vim.fn.stdpath("state") .. "/pi_review.json"

-- piセッションは使わない（socketなし = 提出はできないが、注釈と同期は動く）
package.preload["pi-nvim"] = function()
	return {
		get_socket_path = function()
			return nil
		end,
	}
end

function H.setup(opts)
	local pc = require("pi-nvim-comment")
	pc.setup(vim.tbl_extend("force", { keymaps = false, prompt_suffix = "" }, opts or {}))
	return pc
end

--- pi-comments セッションの {total, pin, index}。なければ nil
function H.session(name)
	for _, s in ipairs(require("walkthrough").get_state()) do
		if s.name == (name or "pi-comments") then
			return s
		end
	end
	return nil
end

function H.total(name)
	local s = H.session(name)
	return s and s.total or 0
end

--- 表示中のnoteフロートの中身（なければ nil）
function H.float_text()
	for _, w in ipairs(vim.api.nvim_list_wins()) do
		local b = vim.api.nvim_win_get_buf(w)
		if vim.bo[b].filetype == "markdown" then
			return table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n"), w
		end
	end
	return nil
end

function H.read()
	local f = io.open(H.json, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	local ok, data = pcall(vim.json.decode, content)
	return ok and data or nil
end

function H.write(data)
	local out = assert(io.open(H.json, "w"))
	out:write(vim.json.encode(data))
	out:close()
end

--- ファイルをカレントバッファとして開く（BufReadPost を発火させる）
function H.open(file, line)
	vim.cmd.edit(H.tmp .. "/" .. file)
	if line then
		vim.api.nvim_win_set_cursor(0, { line, 0 })
	end
	return vim.api.nvim_get_current_buf()
end

--- 監視の起動時ベースライン取り込みを待つ（これ以降の変更だけが「回答」として扱われる）
function H.wait_baseline()
	vim.wait(4000, function()
		return false
	end)
end

function H.run(fn)
	local ok, err = pcall(fn)
	print("RESULT: " .. (ok and "OK" or ("ERR: " .. tostring(err))))
	vim.cmd("qa!")
end

_G.H = H
return H
