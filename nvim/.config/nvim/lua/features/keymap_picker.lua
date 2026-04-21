local M = {}

function M.open()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local themes = require("telescope.themes")

	local results = {}
	local function collect(maps)
		for _, map in ipairs(maps) do
			if map.desc and map.desc:match("^%[") then
				local group = map.desc:match("^(%[%w+%])") or ""
				table.insert(results, {
					lhs = map.lhs,
					desc = map.desc,
					display = string.format("%-12s %s", map.lhs, map.desc),
					ordinal = group .. " " .. map.lhs,
				})
			end
		end
	end

	collect(vim.api.nvim_get_keymap("n"))
	collect(vim.api.nvim_get_keymap("v"))
	collect(vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "n"))
	collect(vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "v"))

	table.sort(results, function(a, b)
		return a.ordinal < b.ordinal
	end)

	pickers
	    .new(themes.get_dropdown({ previewer = false }), {
		    prompt_title = "Keymaps",
		    finder = finders.new_table({
			    results = results,
			    entry_maker = function(entry)
				    return {
					    value = entry,
					    display = entry.display,
					    ordinal = entry.ordinal,
				    }
			    end,
		    }),
		    sorter = conf.generic_sorter({}),
		    attach_mappings = function(prompt_bufnr)
			    actions.select_default:replace(function()
				    local selection = action_state.get_selected_entry()
				    actions.close(prompt_bufnr)
				    local keys = vim.api.nvim_replace_termcodes(selection.value.lhs, true, false, true)
				    vim.api.nvim_feedkeys(keys, "m", false)
			    end)
			    return true
		    end,
	    })
	    :find()
end

return M
