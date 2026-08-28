-- walkthrough.nvim / util
-- どのモジュールにも依存しない小道具。ここから他のwalkthroughモジュールをrequireしないこと。

local M = {}

function M.notify(message, level)
	vim.notify("Walkthrough: " .. message, level or vim.log.levels.INFO)
end

function M.repo_root(dir)
	local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error == 0 and out[1] and #out[1] > 0 then
		return out[1]
	end
	return nil
end

--- ステップのファイルを実パスへ解決する（root相対 → cwd相対の順）
function M.resolve_path(root, file)
	if type(file) ~= "string" or file == "" then
		return nil
	end
	if root then
		local p = root .. "/" .. file
		if vim.fn.filereadable(p) == 1 then
			return p
		end
	end
	if vim.fn.filereadable(file) == 1 then
		return vim.fn.fnamemodify(file, ":p")
	end
	return nil
end

function M.has_thread(step)
	return type(step.thread) == "table" and #step.thread > 0
end

--- 表示幅 max_width で折り返した行の配列を返す（単語境界優先・長い単語は文字単位で分割）
function M.wrap_line(line, max_width)
	if line == "" or vim.fn.strdisplaywidth(line) <= max_width then
		return { line }
	end
	local out = {}
	local current = ""
	local function flush()
		if current ~= "" then
			table.insert(out, current)
			current = ""
		end
	end
	local function push_word(word)
		local candidate = current == "" and word or (current .. " " .. word)
		if vim.fn.strdisplaywidth(candidate) <= max_width then
			current = candidate
			return
		end
		flush()
		if vim.fn.strdisplaywidth(word) <= max_width then
			current = word
			return
		end
		local chunk = ""
		for ch in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			if vim.fn.strdisplaywidth(chunk .. ch) > max_width then
				table.insert(out, chunk)
				chunk = ch
			else
				chunk = chunk .. ch
			end
		end
		current = chunk
	end
	for word in line:gmatch("%S+") do
		push_word(word)
	end
	flush()
	if #out == 0 then
		table.insert(out, "")
	end
	return out
end

return M
