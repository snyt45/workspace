return {
	-- mise の shims が、プロジェクトの Ruby に入っている gem の ruby-lsp を選ぶ（config/runtime.lua）。
	-- mason では入れない。mason の ruby-lsp は入れた時の Ruby に固定され、Ruby を上げたプロジェクトで落ちる
	cmd = { "ruby-lsp" },
	filetypes = { "ruby" },
	root_markers = { "Gemfile", ".git" },
}
