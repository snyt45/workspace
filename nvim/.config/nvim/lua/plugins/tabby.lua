-- viktoraxen のミニマル設定 + spenserlee の modified indicator
-- https://github.com/nanozuki/tabby.nvim/discussions/197
-- https://github.com/nanozuki/tabby.nvim/discussions/172
return {
	"nanozuki/tabby.nvim",
	event = "VimEnter",
	config = function()
		local C = require("catppuccin.palettes").get_palette("mocha")

		-- incline.nvim と同じ配色で design 統一 (active = surface0, inactive = mantle)
		local set_hl = function()
			vim.api.nvim_set_hl(0, "TabLineSel", { bg = C.surface0, fg = C.text })
			vim.api.nvim_set_hl(0, "TabLine", { bg = C.mantle, fg = C.overlay1 })
			vim.api.nvim_set_hl(0, "TabLineFill", { bg = C.base })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

		-- tab 内のいずれかの window のバッファに未保存変更があるか
		local function has_modified_buffer(tabid)
			local wins = require("tabby.module.api").get_tab_wins(tabid)
			for _, winid in ipairs(wins) do
				local ok, bufid = pcall(vim.api.nvim_win_get_buf, winid)
				if ok and vim.bo[bufid].modified then
					return true
				end
			end
			return false
		end

		-- 通常ファイル: buftype 空のバッファから basename を返す
		-- (panel / help / quickfix / terminal 等は buftype が non-empty なので自動除外)
		local function file_tab_label(tabid)
			local wins = vim.api.nvim_tabpage_list_wins(tabid)
			for _, winid in ipairs(wins) do
				local bufid = vim.api.nvim_win_get_buf(winid)
				if vim.bo[bufid].buftype == "" then
					local name = vim.api.nvim_buf_get_name(bufid)
					if name ~= "" then
						return vim.fn.fnamemodify(name, ":t")
					end
				end
			end

			local winid = vim.api.nvim_tabpage_get_win(tabid)
			local bufid = vim.api.nvim_win_get_buf(winid)
			local name = vim.api.nvim_buf_get_name(bufid)
			return name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")
		end

		-- 特殊な mode のタブ: focus に依存しない安定した識別名を返す (flicker 抑制)
		-- 該当なしなら nil
		local function special_tab_label(tabid)
			local wins = vim.api.nvim_tabpage_list_wins(tabid)
			for _, winid in ipairs(wins) do
				local ft = vim.bo[vim.api.nvim_win_get_buf(winid)].filetype
				if ft == "DiffviewFiles" then
					return "DiffviewFiles"
				end
				if ft == "DiffviewFileHistory" then
					return "DiffviewFileHistory"
				end
			end
			return nil
		end

		-- ラベル解決 dispatcher: custom 名 → 特殊タブ名 → 通常ファイル名
		local function tab_label(tabid)
			local custom = require("tabby.feature.tab_name").get_raw(tabid)
			if custom ~= "" then
				return custom
			end
			return special_tab_label(tabid) or file_tab_label(tabid)
		end

		require("tabby").setup({
			line = function(line)
				return {
					line.spacer(),
					line.tabs().foreach(function(tab)
						local hl = tab.is_current() and "TabLineSel" or "TabLine"
						local modified = has_modified_buffer(tab.id) and "●" or ""
						local label = string.format("%d %s", tab.number(), tab_label(tab.id))
						return {
							line.sep(" ", hl, "TabLineFill"),
							label,
							modified,
							line.sep(" ", hl, "TabLineFill"),
							hl = hl,
							margin = "  ",
						}
					end),
					line.spacer(),
					hl = "TabLineFill",
				}
			end,
		})
	end,
}
