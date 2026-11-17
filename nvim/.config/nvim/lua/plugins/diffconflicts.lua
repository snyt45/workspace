return {
	-- jj resolve / git mergetool から開く、衝突解消の2面diff。左を直して :w で次へ進む
	"dont-be-evil-company/diffconflicts.nvim",
	cmd = { "DiffConflicts", "DiffConflictsShowHistory", "DiffConflictsWithHistory" },
	opts = {},
}
