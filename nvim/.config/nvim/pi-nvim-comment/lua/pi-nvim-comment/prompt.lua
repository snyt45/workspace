-- pi-nvim-comment / prompt
-- 提出プロンプト（指示文 + コメント一覧 + ソース抜粋）の組み立て。提出とコピーで共用する。

local state = require("pi-nvim-comment.state")
local util = require("pi-nvim-comment.util")

local M = {}

M.MAX_SOURCE_LINES = 1000
local MAX_SOURCE_CHARS = 64 * 1024

-- 上流 pi-nvim-review の default review instructions と同じテキスト
local DEFAULT_INSTRUCTIONS = table.concat({
	"Process each review comment independently according to its requested outcome.",
	"",
	"- If a comment asks for an explanation or information, answer it directly. Do not modify files for that comment.",
	"- If a comment requests a code change, implement it.",
	"- If a comment contains both a question and a change request, answer the question and implement only the explicit change.",
	"- If the intent is ambiguous, explain the ambiguity and ask for clarification instead of making a speculative change.",
	'- Classify by meaning, not grammar or punctuation. For example, "Can you rename this?" is a change request, while "Can you explain this?" is a question.',
	"",
	"Inspect the current files before answering or editing. Source excerpts can contain unsaved or outdated buffer text.",
	"",
	"In the final response, use separate sections for changes made, questions answered, and comments that need clarification.",
}, "\n")

-- 環境固有の指示はプラグインに埋め込まず setup の opts で注入する
local instructions -- opts.instructions: 指示文の差し替え
local prompt_suffix -- opts.prompt_suffix: 指示文の後に付記する文

function M.configure(opts)
	if type(opts.instructions) == "string" then
		instructions = opts.instructions
	end
	if type(opts.prompt_suffix) == "string" then
		prompt_suffix = opts.prompt_suffix
	end
end

--- コメント範囲のソース行。バッファが開いていればその内容（未保存分を含む）、なければファイルから
local function source_lines(record, start_line, end_line)
	local lines
	if vim.api.nvim_buf_is_valid(record.bufnr) and vim.api.nvim_buf_is_loaded(record.bufnr) then
		local count = vim.api.nvim_buf_line_count(record.bufnr)
		if start_line <= count then
			local ok, got =
				pcall(vim.api.nvim_buf_get_lines, record.bufnr, start_line - 1, math.min(end_line, count), false)
			if ok then
				lines = got
			end
		end
	end
	if not lines then
		local ok, file_lines = pcall(vim.fn.readfile, record.absolute_path, "", end_line)
		if not ok then
			return nil, "ファイルを読み込めません: " .. record.absolute_path
		end
		lines = {}
		for line = start_line, end_line do
			lines[#lines + 1] = file_lines[line] or ""
		end
	end

	for _ = #lines, end_line - start_line do
		lines[#lines + 1] = ""
	end

	local chars = 0
	for _, line in ipairs(lines) do
		chars = chars + #line + 1
	end
	if chars > MAX_SOURCE_CHARS then
		return nil, string.format("ソース抜粋が64KiBを超えています: %s:%d-%d", record.absolute_path, start_line, end_line)
	end
	return lines
end

local function build_payload(root, list)
	local resolved = {}
	for _, record in ipairs(list) do
		local path = util.relative_path(root, record.absolute_path)
		if not path then
			return nil, "Piプロジェクトの外にあるコメントを中断しました: " .. record.absolute_path
		end
		local start_line, end_line = state.range_of(record)
		if end_line - start_line + 1 > M.MAX_SOURCE_LINES then
			return nil, string.format("注釈が %d 行を超えました: %s:%d", M.MAX_SOURCE_LINES, path, start_line)
		end
		local source, source_error = source_lines(record, start_line, end_line)
		if not source then
			return nil, source_error
		end
		resolved[#resolved + 1] = {
			order = record.id,
			path = path,
			startLine = start_line,
			endLine = end_line,
			comment = record.comment,
			source = source,
			reply = record.reply_to,
		}
	end

	table.sort(resolved, function(left, right)
		if left.path ~= right.path then
			return left.path < right.path
		end
		if left.startLine ~= right.startLine then
			return left.startLine < right.startLine
		end
		if left.endLine ~= right.endLine then
			return left.endLine < right.endLine
		end
		return left.order < right.order
	end)
	return resolved
end

local function format_prompt(root, payload)
	local parts = {}
	local function push(...)
		for _, line in ipairs({ ... }) do
			parts[#parts + 1] = line
		end
	end
	local function quote(text)
		for _, line in ipairs(util.split_lines(text)) do
			parts[#parts + 1] = "> " .. line
		end
	end

	local text = instructions or DEFAULT_INSTRUCTIONS
	if text ~= "" then
		push(text, "")
	end
	if prompt_suffix and prompt_suffix ~= "" then
		push(prompt_suffix, "")
	end
	push("Project root: " .. vim.json.encode(root), "")

	for index, annotation in ipairs(payload) do
		push(
			"## Comment " .. index,
			"File: " .. vim.json.encode(annotation.path),
			"Lines: " .. util.location(annotation.startLine, annotation.endLine)
		)
		if annotation.reply then
			local json_path = util.relative_path(root, annotation.reply.json) or annotation.reply.json
			push(
				string.format(
					"Reply to walkthrough thread: %s (step %d)",
					vim.json.encode(json_path),
					annotation.reply.step
				)
			)
			if annotation.reply.context and annotation.reply.context ~= "" then
				push("", "Thread so far:")
				quote(annotation.reply.context)
			end
		end
		push("", "Review comment:")
		quote(annotation.comment)
		push("", "Source excerpt:")
		local width = #tostring(annotation.endLine)
		for offset, source_line in ipairs(annotation.source) do
			push(string.format("    %" .. width .. "d | %s", annotation.startLine + offset - 1, source_line))
		end
		push("")
	end

	return (table.concat(parts, "\n"):gsub("%s+$", ""))
end

--- 提出内容を組み立てる。戻り値: message, 件数（失敗時は nil, エラーメッセージ）
function M.build(list)
	local root = util.project_root()
	local payload, err = build_payload(root, list)
	if not payload then
		return nil, err
	end
	return format_prompt(root, payload), #payload
end

return M
