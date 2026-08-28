-- pi-nvim-comment / util
-- 他のpi-nvim-commentモジュールに依存しない小道具（通知・パス解決・入力検証）。

local M = {}

local MAX_COMMENT_BYTES = 16 * 1024

function M.notify(message, level)
	vim.notify("pi-nvim-comment: " .. message, level or vim.log.levels.INFO)
end

-- carderne/pi-nvim の自動発見(get_socket_path)と送信(send_raw)を再利用する:
--   pi を起動すると拡張が自動でソケットを開き、nvim は cwd 一致セッションを掴む。
function M.pi_nvim()
	return require("pi-nvim")
end

--- pi セッションのソケットパス（pi-nvim の自動発見: cwd一致→最新→latest symlink）
function M.socket_path()
	return M.pi_nvim().get_socket_path()
end

local function read_socket_cwd()
	local socket = M.socket_path()
	if not socket then
		return nil
	end
	local ok, lines = pcall(vim.fn.readfile, socket .. ".info")
	if not (ok and lines and lines[1]) then
		return nil
	end
	local decoded_ok, info = pcall(vim.json.decode, lines[1])
	if decoded_ok and type(info) == "table" and type(info.cwd) == "string" then
		return info.cwd
	end
	return nil
end

-- project_root は監視tickを含め高頻度で呼ばれるので短時間キャッシュする（socketの.info読みを毎回やらない）
local cached_root, cached_at = nil, nil
local ROOT_TTL_MS = 2000

--- pi セッションの project root: <socket>.info の cwd（読めなければ nvim cwd）
function M.project_root()
	local now = vim.uv.now()
	if cached_root and cached_at and (now - cached_at) < ROOT_TTL_MS then
		return cached_root
	end
	local dir = read_socket_cwd() or vim.uv.cwd()
	cached_root = vim.uv.fs_realpath(dir) or vim.fs.normalize(dir)
	cached_at = now
	return cached_root
end

--- root配下の相対パス。外なら nil
function M.relative_path(root, absolute)
	local rel = vim.fs.relpath(root, absolute)
	if not rel or rel == "" or rel:sub(1, 2) == ".." then
		return nil
	end
	return rel:gsub("\\", "/")
end

--- 表示用の "12" / "12-15"
function M.location(start_line, end_line)
	if start_line == end_line then
		return tostring(start_line)
	end
	return string.format("%d-%d", start_line, end_line)
end

function M.split_lines(text)
	local out = {}
	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		out[#out + 1] = line
	end
	while #out > 0 and out[#out] == "" do
		out[#out] = nil
	end
	return out
end

--- 入力コメントを検証して整形する。不正なら notify して nil
function M.validate_comment(text)
	text = vim.trim(text)
	if text == "" then
		M.notify("空のコメントは追加されませんでした", vim.log.levels.WARN)
		return nil
	end
	if #text > MAX_COMMENT_BYTES then
		M.notify("コメントが16KiBを超えています", vim.log.levels.WARN)
		return nil
	end
	return text
end

--- JSONをアトミックに書く（同じディレクトリの一時ファイル + rename）。
--- 監視側が書き込み途中のファイルを読まないようにするため、書き込みは必ずこれを通す
function M.write_json(path, data)
	local ok, encoded = pcall(vim.json.encode, data)
	if not ok then
		return false
	end
	local tmp = path .. ".tmp"
	local write_ok = pcall(vim.fn.writefile, { encoded }, tmp)
	if not write_ok then
		return false
	end
	if not vim.uv.fs_rename(tmp, path) then
		os.remove(tmp)
		return false
	end
	return true
end

return M
