-- nvim が外のツール（node・ruby など）を見つける方法。規則は1つ: mise の shims で見つける
--
-- shims は、実行された場所（LSP ならプロジェクトのルート）の .tool-versions / mise.toml に合う版を選ぶ。
-- シェルから起動した nvim には .zshrc 経由で入っているが、herdr-app のようにシェルを通さず起動された nvim には無い。
--
-- これに頼っているもの:
--   ts_ls      mason の typescript-language-server が node で動く
--   ruby_lsp   各 Ruby に入れた gem の ruby-lsp（lsp/ruby_lsp.lua。~/.default-gems で自動で入る）
--   conform    prettier / prettierd
--
-- LSP が「command not found」「node: No such file」で落ちたら、まずここを疑う
local shims = vim.env.HOME .. "/.local/share/mise/shims"
if not vim.env.PATH:find(shims, 1, true) then
	vim.env.PATH = shims .. ":" .. vim.env.PATH
end
