local M = {}

function M.open()
	local items = {}
	local function collect(maps)
		for _, map in ipairs(maps) do
			if map.desc and map.desc:match("^%[") then
				local group = map.desc:match("^(%[%w+%])") or ""
				table.insert(items, {
					text = group .. " " .. map.lhs .. " " .. map.desc,
					lhs = map.lhs,
					desc = map.desc,
					sort = group .. " " .. map.lhs,
				})
			end
		end
	end

	collect(vim.api.nvim_get_keymap("n"))
	collect(vim.api.nvim_get_keymap("v"))
	collect(vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "n"))
	collect(vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "v"))

	table.sort(items, function(a, b)
		return a.sort < b.sort
	end)

	Snacks.picker.pick({
		title = "Keymaps",
		items = items,
		layout = { preset = "select" },
		format = function(item)
			return {
				{ string.format("%-12s ", item.lhs), "SnacksPickerLabel" },
				{ item.desc },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			local keys = vim.api.nvim_replace_termcodes(item.lhs, true, false, true)
			vim.api.nvim_feedkeys(keys, "m", false)
		end,
	})
end

return M
