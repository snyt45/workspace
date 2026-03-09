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
vim.opt.cursorline = true       -- カーソル行をハイライト
vim.opt.termguicolors = true    -- 24bitカラー

-- 検索
vim.opt.incsearch = true        -- インクリメンタル検索
vim.opt.hlsearch = true         -- 検索結果ハイライト
vim.opt.ignorecase = true       -- 大文字小文字無視
vim.opt.smartcase = true        -- 大文字を含むときは区別

-- マウス
vim.opt.mouse = "a"

-- クリップボード (macOSのシステムクリップボードと共有)
vim.opt.clipboard = "unnamedplus"

-- ファイル管理
vim.opt.autoread = true         -- 外部変更を自動読み込み

-- ペイン切り替え時にファイル変更を検知してリロード
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
  command = "checktime",
})


vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true         -- undoを永続化

-- 折りたたみ
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99          -- デフォルトで全て展開

-- 行番号
vim.opt.number = true

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
map("n", "<leader>t", "<cmd>belowright split | terminal<cr>")

-- ターミナルモードからノーマルモードに戻る
map("t", "jj", "<C-\\><C-n>")

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
          filtered_items = {
            visible = true,       -- 隠しファイル表示
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
        window = {
          width = 30,
        },
      })
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>")
    end,
  },

  -- =============================================
  -- バッファタブ: bufferline.nvim
  -- 上部にバッファをタブ風に表示
  -- VSCodeのタブバーと同じ感覚
  -- =============================================
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          offsets = {
            { filetype = "neo-tree", text = "Explorer", text_align = "center" },
          },
          show_buffer_close_icons = false,
          show_close_icon = false,
        },
      })
      vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<cr>")
      vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<cr>")
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
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- C実装のソーター。検索が高速になる
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          layout_strategy = "vertical",
          layout_config = { height = 0.9, width = 0.9 },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      })
      telescope.load_extension("fzf")

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
      "hrsh7th/cmp-nvim-lsp",  -- LSPの補完ソース
      "hrsh7th/cmp-buffer",     -- バッファ内の単語
      "hrsh7th/cmp-path",       -- ファイルパス
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
  -- Copilot
  -- Vim時代と同じくGitHub Copilot
  -- =============================================
  {
    "github/copilot.vim",
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
  -- Markdownプレビュー: live-preview.nvim
  -- ブラウザでライブプレビュー（リロードしても維持）
  -- <leader>m でトグル
  -- =============================================
  {
    "brianhuster/live-preview.nvim",
    cmd = { "LivePreview", "StopPreview" },
    keys = {
      { "<leader>m", "<cmd>LivePreview start<cr>", desc = "Live Preview" },
    },
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
  end,
})
