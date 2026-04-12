return {
	"nvim-telescope/telescope.nvim",
	keys = {
		{
			"<leader>ms",
			function()
				local output = vim.fn.system("tmux ls -F '#{session_name}'")
				if vim.v.shell_error ~= 0 then
					vim.notify("tmuxが起動していません", vim.log.levels.WARN)
					return
				end

				local sessions = vim.split(vim.trim(output), "\n", { trimempty = true })
				if #sessions == 0 then
					vim.notify("セッションがありません", vim.log.levels.INFO)
					return
				end

				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local conf = require("telescope.config").values
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				pickers
					.new(require("telescope.themes").get_dropdown({ previewer = false }), {
						prompt_title = "Tmux Sessions",
						finder = finders.new_table({ results = sessions }),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(prompt_bufnr)
							actions.select_default:replace(function()
								actions.close(prompt_bufnr)
								local selection = action_state.get_selected_entry()
								if selection then
									vim.fn.system("tmux switch-client -t " .. vim.fn.shellescape(selection[1]))
									if vim.v.shell_error ~= 0 then
										vim.notify("セッション切り替えに失敗しました", vim.log.levels.ERROR)
									end
								end
							end)
							return true
						end,
					})
					:find()
			end,
			desc = "[Tmux] セッション切り替え",
		},
	},
}
