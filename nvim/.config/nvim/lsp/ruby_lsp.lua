return {
	-- プロジェクトの Ruby で動かす（mise がその Ruby に入っている gem の ruby-lsp を選ぶ）。
	-- mason の ruby-lsp は入れた時の Ruby に固定され、Ruby を上げたプロジェクトで落ちる
	cmd = { "mise", "x", "--", "ruby-lsp" },
	filetypes = { "ruby" },
	root_markers = { "Gemfile", ".git" },
}
