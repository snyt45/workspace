-- ==========================================================================
-- パレット統合エントリ: <leader>? でコマンド/キーマップを選択
-- ==========================================================================

vim.keymap.set("n", "<leader>?", function()
	vim.ui.select({ "Commands", "Keymaps" }, { prompt = "Palette:" }, function(choice)
		if choice == "Commands" then
			require("features.command_palette").open()
		elseif choice == "Keymaps" then
			require("features.keymap_picker").open()
		end
	end)
end, { desc = "[Palette] コマンド/キーマップパレット" })
