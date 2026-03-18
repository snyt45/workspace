-- ==========================================================================
-- Bootstrap: lazy.nvim (プラグインマネージャ)
-- 初回起動時に自動でダウンロードされる
-- ==========================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 基本設定
-- ==========================================================================

-- リーダーキー
vim.g.mapleader = ","

-- 表示
vim.opt.cursorline = true    -- カーソル行をハイライト
vim.opt.termguicolors = true -- 24bitカラー

-- 検索
vim.opt.incsearch = true  -- インクリメンタル検索
vim.opt.hlsearch = true   -- 検索結果ハイライト
vim.opt.ignorecase = true -- 大文字小文字無視
vim.opt.smartcase = true  -- 大文字を含むときは区別

-- マウス
vim.opt.mouse = "a"

-- クリップボード (macOSのシステムクリップボードと共有)
vim.opt.clipboard = "unnamedplus"

-- ファイル管理
vim.opt.autoread = true -- 外部変更を自動読み込み

-- ペイン切り替え時にファイル変更を検知してリロード
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
	command = "checktime",
})


vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true -- undoを永続化

-- 折りたたみ
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99 -- デフォルトで全て展開

-- 行番号
vim.opt.number = true

-- ウィンドウ分割方向
vim.opt.splitright = true -- 縦分割は右に開く
vim.opt.splitbelow = true -- 横分割は下に開く

-- ==========================================================================
-- キーマップ (プラグイン非依存)
-- ==========================================================================

local map = vim.keymap.set

-- レコーディング無効化
map("n", "q", "<Nop>")

-- F1ヘルプ無効化
map({ "n", "i" }, "<F1>", "<Nop>")

-- 検索ハイライト解除
map("n", "<Esc><Esc>", ":nohlsearch<CR>")

-- インサートモード: Karabiner英数+a/eに対応
-- 英数+a → Ctrl+A → 行頭移動
map("i", "<C-a>", "<Home>")
-- 英数+e → Ctrl+E → 行末移動
map("i", "<C-e>", "<End>")

-- C-h/j/k/l でウィンドウ間を直接移動（C-w 不要）
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- バッファを閉じる（ウィンドウレイアウトを維持）
map("n", "<leader>x", function()
	local buf = vim.api.nvim_get_current_buf()
	local listed = vim.fn.getbufinfo({ buflisted = 1 })
	-- 他にリスト済みバッファがあれば切り替えてから削除
	if #listed > 1 then
		vim.cmd("bprevious")
	end
	-- 元のバッファがまだ存在していれば削除
	if vim.api.nvim_buf_is_valid(buf) then
		vim.cmd("bdelete " .. buf)
	end
end)

-- quickfix操作
map("n", "]q", "<cmd>cnext<cr>")
map("n", "[q", "<cmd>cprev<cr>")
map("n", "<leader>q", function()
	local wins = vim.fn.getqflist({ winid = 0 }).winid
	if wins ~= 0 then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end)

-- ターミナルを下に分割して開く
map("n", "<leader>t", "<cmd>split | terminal<cr>")

-- ターミナルモードからノーマルモードに戻る
map("t", "jj", "<C-\\><C-n>")

-- Markdownプレビュー (mo) - ブラウザ自動起動
map("n", "<leader>m", function()
	local file = vim.fn.shellescape(vim.fn.expand("%"))
	local output = vim.fn.system("mo " .. file .. " 2>&1")
	local url = output:match("(http://[^%s]+)")
	if url then
		vim.fn.jobstart({ "open", url })
	end
end)

-- キーマップヘルプ (g?) - Telescopeでファジー検索・実行
map("n", "g?", function()
	local items = {
		-- ファイル
		{ cmd = "Neotree toggle", label = ",e   ファイルツリー" },
		{ cmd = "Telescope find_files", label = ",,   ファイル検索" },
		{ cmd = "Telescope live_grep", label = ",r   grep検索" },
		{ cmd = "Telescope buffers", label = ",b   バッファ一覧" },
		{ cmd = "Telescope oldfiles", label = ",o   最近のファイル" },
		{ label = ",x   バッファを閉じる" },
		{ label = ",c   ファイルパスコピー" },
		{ label = ",m   Markdownプレビュー" },
		-- Harpoon
		{ label = ",a   Harpoon追加" },
		{ label = ",h   Harpoonメニュー" },
		{ label = ",1-4 Harpoonジャンプ" },
		-- Git
		{ cmd = "CodeDiff", label = ",gg  CodeDiff" },
		{ cmd = "Telescope git_status", label = ",gs  git status" },
		{ label = "gn   次のhunk" },
		{ label = "gp   前のhunk" },
		{ label = "gha  hunkをstage" },
		{ label = "ghu  hunkをreset" },
		{ label = "ghp  hunkをプレビュー" },
		-- LSP
		{ label = "gd   定義ジャンプ" },
		{ label = "gr   参照一覧" },
		{ label = "K    ホバー" },
		{ label = ",rn  リネーム" },
		{ label = ",ca  コードアクション" },
		{ label = "gy   型定義" },
		{ label = "gl   diagnostic" },
		-- AI
		{ cmd = "CodeCompanionChat Toggle", label = ",cc  AIチャット" },
		{ cmd = "CodeCompanionActions", label = ",ccp AIアクション" },
		{ label = "ga   チャットに追加 (visual)" },
		-- その他
		{ label = "gcc  コメントトグル" },
		{ label = ",t   ターミナル" },
		{ label = ",q   quickfixトグル" },
		{ label = "]q   次のquickfix" },
		{ label = "[q   前のquickfix" },
	}
	vim.ui.select(items, {
		prompt = "キーマップ",
		format_item = function(item) return item.label end,
	}, function(choice)
		if choice and choice.cmd then
			vim.cmd(choice.cmd)
		end
	end)
end)

-- ファイルパスコピー
map("n", "<leader>c", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	print("Copied: " .. path)
end)

-- ==========================================================================
-- プラグイン
-- ==========================================================================

require("lazy").setup({

	-- =============================================
	-- テーマ: gruvbox
	-- =============================================
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			require("gruvbox").setup({
				transparent_mode = true,
				overrides = {
					NormalFloat = { bg = "#3c3836" },
					FloatBorder = { fg = "#a89984", bg = "#3c3836" },
				},
			})
			vim.cmd.colorscheme("gruvbox")
		end,
	},

	-- =============================================
	-- ファイルツリー: neo-tree.nvim
	-- VSCodeライクな固定サイドバー
	-- <leader>e でトグル
	-- =============================================
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup({
				filesystem = {
					follow_current_file = {
						enabled = true, -- バッファ切替時にツリーを自動追従
					},
					filtered_items = {
						visible = true, -- 隠しファイル表示
						hide_dotfiles = false,
						hide_gitignored = false,
					},
					window = {
						mappings = {
							["/"] = function(state)
								local node = state.tree:get_node()
								local path = node.type == "directory" and node:get_id() or
								    vim.fn.fnamemodify(node:get_id(), ":h")
								require("telescope.builtin").live_grep({
									search_dirs = { path },
									additional_args = { "--hidden" },
								})
							end,
						},
					},
				},
				window = {
					width = 30,
					mappings = {
						["gf"] = function() vim.cmd("Neotree focus filesystem left") end,
						["gs"] = function() vim.cmd("Neotree focus git_status left") end,
					},
				},
			})
			vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>")
		end,
	},

	-- =============================================
	-- harpoon2: 作業中ファイルへの高速ジャンプ
	-- <leader>a で登録、<leader>1-4 で一発ジャンプ
	-- =============================================
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup({
				settings = {
					save_on_toggle = true,
					sync_on_ui_close = true,
				},
			})

			vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
			vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

			vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
			vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
			vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
			vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
		end,
	},

	-- =============================================
	-- ファジーファインダー: telescope.nvim
	-- Vim時代のfzf連携の代替
	-- <leader><leader> でファイル検索
	-- <leader>r でgrep検索
	-- <leader>b でバッファ一覧
	-- =============================================
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- C実装のソーター。検索が高速になる
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			-- vim.ui.selectをTelescopeで表示
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			telescope.setup({
				defaults = {
					layout_strategy = "vertical",
					layout_config = { height = 0.9, width = 0.9 },
					mappings = {
						i = { ["<Esc>"] = actions.close },
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			})
			telescope.load_extension("fzf")
			telescope.load_extension("ui-select")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader><leader>", builtin.find_files)
			vim.keymap.set("n", "<leader>r", builtin.live_grep)
			vim.keymap.set("n", "<leader>b", builtin.buffers)
			vim.keymap.set("n", "<leader>o", builtin.oldfiles)
			vim.keymap.set("n", "<leader>gs", builtin.git_status)
		end,
	},

	-- =============================================
	-- 補完: nvim-cmp
	-- LSPの補完候補をポップアップ表示
	-- Tab/S-Tabで選択、Enterで確定
	-- =============================================
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSPの補完ソース
			"hrsh7th/cmp-buffer", -- バッファ内の単語
			"hrsh7th/cmp-path", -- ファイルパス
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},

	-- =============================================
	-- Git: gitsigns.nvim
	-- Vim時代のGitGutterの代替
	-- 変更行の左側にサイン表示、hunk単位の操作
	-- =============================================
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				signs = {
					add          = { text = "+" },
					change       = { text = ">" },
					delete       = { text = "-" },
					topdelete    = { text = "^" },
					changedelete = { text = "<" },
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns
					local opts = { buffer = bufnr }

					-- Vim時代と同じキーマップ
					vim.keymap.set("n", "gn", gs.next_hunk, opts)
					vim.keymap.set("n", "gp", gs.prev_hunk, opts)
					vim.keymap.set("n", "gha", gs.stage_hunk, opts)
					vim.keymap.set("n", "ghu", gs.reset_hunk, opts)
					vim.keymap.set("n", "ghp", gs.preview_hunk, opts)
				end,
			})
		end,
	},

	-- =============================================
	-- Git: codediff.nvim
	-- VSCode風のdiff表示（行+文字レベルの2段ハイライト）
	-- <leader>gg でdiffビュー
	-- =============================================
	{
		"esmuellert/codediff.nvim",
		cmd = "CodeDiff",
		keys = {
			{ "<leader>gg", "<cmd>CodeDiff<cr>", desc = "CodeDiff" },
		},
	},

	-- =============================================
	-- コメント: Comment.nvim
	-- Vim時代のcaw.vimの代替
	-- gcc で行コメントトグル、gc + モーションで範囲コメント
	-- =============================================
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- =============================================
	-- Copilot: copilot.lua
	-- インライン補完（バッファ上にゴースト表示）
	-- =============================================
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				copilot_node_command = vim.fn.expand("~/.local/share/mise/installs/node/22.22.1/bin/node"),
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<Right>",
						accept_word = "<M-Right>",
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-]>",
					},
				},
				panel = { enabled = false },
				filetypes = { ["*"] = true },
			})
		end,
	},

	-- =============================================
	-- codecompanion.nvim: AIアシスト (Chat + Inline編集)
	-- ,cc でチャット、,ccp でアクション選択
	-- ビジュアル選択 → :CodeCompanion <指示> でインライン編集
	-- =============================================
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("codecompanion").setup({
				language = "Japanese",
				interactions = {
					chat = { adapter = "copilot" },
					inline = { adapter = "copilot" },
					cmd = { adapter = "copilot" },
				},
				display = {
					action_palette = {
						opts = {
							show_preset_prompts = false,
						},
					},
					chat = {
						window = {
							layout = "vertical",
							width = 0.4,
						},
					},
				},
			})
			vim.keymap.set({ "n", "v" }, "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>")
			vim.keymap.set({ "n", "v" }, "<leader>ccp", "<cmd>CodeCompanionActions<cr>")
			vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>")
		end,
	},

	-- =============================================
	-- Mason: 言語サーバーのインストール管理
	-- :Mason でUI表示
	-- =============================================
	{
		"williamboman/mason.nvim",
		dependencies = { "williamboman/mason-lspconfig.nvim" },
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "ts_ls", "ruby_lsp", "lua_ls" },
			})
		end,
	},

	-- =============================================
	-- フォーマッター: conform.nvim
	-- 保存時に自動フォーマット
	-- プロジェクトの node_modules/prettier を優先、なければ mason のフォールバック
	-- =============================================
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					javascript = { "prettierd", "prettier", stop_after_first = true },
					javascriptreact = { "prettierd", "prettier", stop_after_first = true },
					typescript = { "prettierd", "prettier", stop_after_first = true },
					typescriptreact = { "prettierd", "prettier", stop_after_first = true },
					json = { "prettierd", "prettier", stop_after_first = true },
					markdown = { "prettierd", "prettier", stop_after_first = true },
				},
				format_on_save = {
					timeout_ms = 2000,
					lsp_format = "fallback",
				},
			})
		end,
	},

})

-- ==========================================================================
-- LSP設定 (Neovim 0.11+ 組み込み API)
-- mason-lspconfigでインストール、vim.lsp.config/enableで設定
-- gd: 定義ジャンプ, K: ホバー, <leader>rn: リネーム
-- ==========================================================================

-- TypeScript
vim.lsp.config.ts_ls = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	root_markers = { "tsconfig.json", "package.json" },
}
vim.lsp.enable("ts_ls")

-- Ruby
vim.lsp.config.ruby_lsp = {
	cmd = { "ruby-lsp" },
	filetypes = { "ruby" },
	root_markers = { "Gemfile", ".ruby-version" },
}
vim.lsp.enable("ruby_lsp")

-- Lua (Neovim設定ファイル用)
vim.lsp.config.lua_ls = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc" },
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = { library = { vim.env.VIMRUNTIME } },
		},
	},
}
vim.lsp.enable("lua_ls")

-- LSP共通キーマップ (LSPがアタッチされたバッファでのみ有効)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
	end,
})
