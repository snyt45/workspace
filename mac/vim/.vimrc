vim9script

# ==============================================================================
# Editor Settings
# ==============================================================================

# Display
set cursorline

# Search
set incsearch
set hlsearch
set ignorecase
set smartcase

# Mouse Support
set mouse=a

# Clipboard
set clipboard=unnamed

# ==============================================================================
# File Settings
# ==============================================================================

# File Management
set autoread
set noswapfile
set nobackup
set noundofile

# Auto reload file when changed externally
augroup AutoReload
  autocmd!
  autocmd FocusGained,BufEnter * checktime
  
  autocmd WinLeave * if &buftype == 'terminal' | 
    \ silent! GitGutterAll | 
    \ endif
augroup END

# File Search Configuration
set path=**
set wildignore+=**/node_modules/**
set wildignore+=**/.git/**
set wildignore+=**/vendor/**
set wildignore+=**/coverage/**
set wildignore+=**/.next/**
set wildignore+=**/dist/**
set wildignore+=**/build/**
set wildignore+=**/Pods/**

# Enable auto completion menu after pressing TAB
set wildmenu
set wildoptions=pum

# ==============================================================================
# UI Settings
# ==============================================================================

# Folding
set foldmethod=indent
set foldlevel=99

# Tab Management
set showtabline=0
set showtabpanel=2
set tabpanelopt=align:right,vert
set tabpanel=%t

# ==============================================================================
# Plugin Manager
# ==============================================================================

call plug#begin('~/.vim/plugged')
Plug 'vim-jp/vimdoc-ja'
Plug 'morhetz/gruvbox'
Plug 'github/copilot.vim'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'tyru/caw.vim'
Plug 'iberianpig/tig-explorer.vim'
Plug 'snyt45/vim-help-popup'
call plug#end()

# ==============================================================================
# Color Scheme & Theme
# ==============================================================================

# Enable true color support if available
if has('termguicolors')
  set termguicolors
endif

# Set gruvbox color scheme
colorscheme gruvbox
set background=dark

# Make background transparent
highlight Normal guibg=NONE ctermbg=NONE
highlight NonText guibg=NONE ctermbg=NONE
highlight LineNr guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
highlight EndOfBuffer guibg=NONE ctermbg=NONE

# Make tabpanel transparent
highlight TabPanel guibg=NONE ctermbg=NONE
highlight TabPanelSel guibg=NONE ctermbg=NONE
highlight TabPanelFill guibg=NONE ctermbg=NONE
highlight VertSplit guibg=NONE ctermbg=NONE

# Customize tab panel colors
highlight TabPanelSel guifg=#ebdbb2 guibg=#504945 ctermbg=237
highlight TabPanel guifg=#928374 guibg=NONE ctermbg=NONE

# Terminal Color
g:terminal_ansi_colors = [
    \ '#282828', '#cc241d', '#98971a', '#d79921',
    \ '#458588', '#b16286', '#689d6a', '#d65d0e',
    \ '#fb4934', '#b8bb26', '#fabd2f', '#83a598',
    \ '#d3869b', '#8ec07c', '#fe8019', '#fbf1c7'
    \ ]

highlight Terminal guibg=NONE ctermbg=NONE guifg=#ebdbb2

# ==============================================================================
# Plugin Configuration
# ==============================================================================

# GitGutter
set updatetime=100
g:gitgutter_map_keys = 0
g:gitgutter_preview_win_floating = 1
g:gitgutter_sign_added = '+'
g:gitgutter_sign_modified = '>'
g:gitgutter_sign_removed = '-'
g:gitgutter_sign_removed_first_line = '^'
g:gitgutter_sign_modified_removed = '<'

# Highlight GitGutter signs with transparent background
highlight GitGutterAdd guibg=NONE ctermbg=NONE
highlight GitGutterChange guibg=NONE ctermbg=NONE
highlight GitGutterDelete guibg=NONE ctermbg=NONE

# ==============================================================================
# Helper Functions
# ==============================================================================

# UI Functions
def TabPanelToggle()
    if &showtabpanel == 0
        set showtabpanel=2
    else
        set showtabpanel=0
    endif
enddef

def WindowMaximizeToggle()
    var is_terminal = &buftype == 'terminal'
    
    if g:window_maximized
        wincmd =
        g:window_maximized = false
    else
        wincmd _
        wincmd |
        g:window_maximized = true
    endif
    
    if is_terminal
        normal! i
    endif
enddef

# Quickfix Functions
def OpenQuickfixVertical()
    if len(getqflist()) > 0
        vert copen
        setlocal nowrap
        vertical resize 40
    endif
enddef

def QuickfixToggle()
    if empty(filter(getwininfo(), (_, val) => val.quickfix))
        OpenQuickfixVertical()
    else
        cclose
    endif
enddef

# File Functions
def UpdateCurrentFileInOldfiles()
    var current = expand('%:p')
    if !empty(current) && filereadable(current)
        var idx = index(v:oldfiles, current)
        if idx >= 0
            remove(v:oldfiles, idx)
        endif
        insert(v:oldfiles, current, 0)
    endif
enddef

def CopyFilePath()
    @* = expand('%:.')
    echo 'Copied: ' .. expand('%:.')
enddef

# Git Functions
def GetParentBranchDiffFiles(): list<string>
    const current_branch = trim(system('git rev-parse --abbrev-ref HEAD'))
    
    # 現在のブランチがmainまたはmasterの場合は空を返す
    if current_branch == 'main' || current_branch == 'master'
        return []
    endif
    
    # git show-branchで派生元ブランチを取得
    var parent_branch = trim(system("git show-branch 2>/dev/null | grep '*' | grep -v '" .. current_branch .. "' | head -1 | awk -F'[]~^[]' '{print $2}'"))
    
    # 派生元が見つからない場合、フォールバック
    if parent_branch == ''
        # mainまたはmasterをデフォルトとして使用
        if trim(system('git show-ref --verify --quiet refs/heads/main && echo "exists"')) == 'exists'
            parent_branch = 'main'
        elseif trim(system('git show-ref --verify --quiet refs/heads/master && echo "exists"')) == 'exists'
            parent_branch = 'master'
        else
            return []
        endif
    endif
    
    # 現在のブランチと親ブランチが同じ場合は空を返す
    if current_branch == parent_branch
        return []
    endif
    
    # merge-baseを使って分岐点を見つける
    const merge_base = trim(system('git merge-base HEAD ' .. parent_branch .. ' 2>/dev/null'))
    
    if merge_base == ''
        return []
    endif
    
    # 差分ファイルを取得
    return systemlist('git diff --name-only ' .. merge_base .. '..HEAD')
enddef

def GetRecentGitFiles(oldfiles_limit: number = 50, result_limit: number = 10): list<string>
    UpdateCurrentFileInOldfiles()
    
    var gitfiles = systemlist('git ls-files')
    var gitset = {}
    for f in gitfiles
        gitset[fnamemodify(f, ':p')] = f
    endfor

    var recent_files = []
    
    for f in v:oldfiles[0 : oldfiles_limit]
        var fullpath = fnamemodify(f, ':p')
        if has_key(gitset, fullpath)
            var relative = gitset[fullpath]
            add(recent_files, relative)
            if len(recent_files) >= result_limit
                break
            endif
        endif
    endfor
    
    return recent_files
enddef

def GetProjectRecentFiles(): list<string>
    var gitfiles = systemlist('git ls-files')
    var recent_files = GetRecentGitFiles(50, 10)
    var recent_set = {}
    for f in recent_files
        recent_set[f] = 1
    endfor
    
    var result = []
    var added_files = {}
    
    # 派生元ブランチとの差分ファイルを先頭に追加（明るい緑色）
    const diff_files = GetParentBranchDiffFiles()
    for f in diff_files
        if filereadable(f)
            add(result, "\x1b[92m" .. f .. "\x1b[0m")
            added_files[f] = 1
        endif
    endfor
    
    for f in recent_files
        if !has_key(added_files, f)
            add(result, "\x1b[36m" .. f .. "\x1b[0m")
            added_files[f] = 1
        endif
    endfor
    
    for f in gitfiles
        if !has_key(added_files, f)
            add(result, f)
        endif
    endfor
    
    return result
enddef

# FZF Functions
def GrepSink(line: string)
    var parts = split(line, ':')
    if len(parts) >= 2
        execute 'e ' .. parts[0]
        execute ':' .. parts[1]
    endif
enddef

# ==============================================================================
# Autocmds
# ==============================================================================

# Quickfix
augroup AutoOpenQuickfix
  autocmd!
  autocmd QuickFixCmdPost * OpenQuickfixVertical()
augroup END

# ==============================================================================
# Key Mappings - General
# ==============================================================================

g:mapleader = ","
g:window_maximized = false

# Disable recording
nnoremap q <Nop>

# Disable F1 help
map <F1> <Nop>
imap <F1> <Nop>

# Clear search highlight
nnoremap <Esc><Esc> :nohlsearch<CR>

# ==============================================================================
# Key Mappings - Buffer Management
# ==============================================================================

nnoremap <leader>b :ls<CR>:b<Space>

# ==============================================================================
# Key Mappings - Tab Management
# ==============================================================================

nnoremap <leader>tt <scriptcmd>TabPanelToggle()<CR>
nnoremap tj :tabmove +1<CR>
nnoremap tk :tabmove -1<CR>

# ==============================================================================
# Key Mappings - Window Management
# ==============================================================================

nnoremap <C-h> :vertical resize -10<CR>
nnoremap <C-l> :vertical resize +10<CR>
nnoremap <C-k> :resize -5<CR>
nnoremap <C-j> :resize +5<CR>

nnoremap <leader>mm <scriptcmd>WindowMaximizeToggle()<CR>
tnoremap <leader>mm <C-\><C-n><scriptcmd>WindowMaximizeToggle()<CR>

# ==============================================================================
# Key Mappings - Terminal
# ==============================================================================

tnoremap <ESC> <C-\><C-n>

# ==============================================================================
# Key Mappings - File Operations
# ==============================================================================

nnoremap <leader>c <scriptcmd>CopyFilePath()<CR>

# ==============================================================================
# Key Mappings - Quickfix
# ==============================================================================

nnoremap <leader>qq <scriptcmd>QuickfixToggle()<CR>

# ==============================================================================
# Key Mappings - Git Integration
# ==============================================================================

# GitGutter
nmap gn <Plug>(GitGutterNextHunk)
nmap gp <Plug>(GitGutterPrevHunk)
nmap gha <Plug>(GitGutterStageHunk)
nmap ghu <Plug>(GitGutterUndoHunk)
nmap ghp <Plug>(GitGutterPreviewHunk)
nmap ghf <Plug>(GitGutterFold)

# Git Jump
command! -bar -nargs=* Jump cexpr system('git jump --stdout ' .. <q-args>)
nnoremap gD :Jump diff<CR>
nnoremap gM :Jump merge<CR>
nnoremap gG :Jump grep<Space>

# ==============================================================================
# Key Mappings - FZF Integration
# ==============================================================================

# Files
nnoremap <leader><leader> <scriptcmd>fzf#run({
    \ 'source': GetProjectRecentFiles(),
    \ 'sink': 'e',
    \ 'options': ['--prompt', 'Files> ', '--tiebreak=index'],
    \ 'window': {'width': 0.9, 'height': 0.6}
    \ })<CR>

# Rg
nnoremap <leader>r <scriptcmd>fzf#run({
    \ 'source': 'rg --line-number --no-heading --color=always --smart-case ""',
    \ 'sink': funcref('GrepSink'),
    \ 'options': ['--prompt', 'Rg> ', '--ansi', '--delimiter', ':'],
    \ 'window': {'width': 0.9, 'height': 0.6}
    \ })<CR>

# Diff Files (from parent branch)
nnoremap <leader>d <scriptcmd>fzf#run({
    \ 'source': GetParentBranchDiffFiles(),
    \ 'sink': 'e',
    \ 'options': ['--prompt', 'Diff> ', '--preview', 'bat --color=always --style=header,grid --line-range :300 {}'],
    \ 'window': {'width': 0.9, 'height': 0.6}
    \ })<CR>

# Recent Files
nnoremap <leader>o <scriptcmd>fzf#run({
    \ 'source': GetRecentGitFiles(100, 50),
    \ 'sink': 'e',
    \ 'options': ['--prompt', 'Recent> ', '--preview', 'bat --color=always --style=header,grid --line-range :300 {}'],
    \ 'window': {'width': 0.9, 'height': 0.6}
    \ })<CR>

# ==============================================================================
# Key Mappings - Function Keys
# ==============================================================================

# Tig Explorer
nnoremap <F1> :TigStatus<CR>
nnoremap <F2> :Tig<CR>
nnoremap <F3> :TigOpenCurrentFile<CR>
nnoremap <F4> :TigBlame<CR>

# Quickfix Navigation
nnoremap <F9> :cprev<CR>zz
nnoremap <F10> :cnext<CR>zz

# Help Popup
nnoremap <F11> :HelpPopup<CR>

# ==============================================================================
# Help Configuration
# ==============================================================================

g:help_popup_content = {
  \ 'file': {
  \   'title': 'ファイル操作',
  \   'items': [
  \     {
  \       'command': ':e **/foo<Tab>',
  \       'description': 'ファイルを開く',
  \       'notes': 'ファイル名の一部を入力して補完'
  \     },
  \     {
  \       'command': ':fin foo<Tab>',
  \       'description': 'ファイルを検索して開く',
  \       'notes': 'pathオプションで検索パスを指定可能'
  \     },
  \     {
  \       'command': '<leader>c',
  \       'description': 'ファイルパスをコピー',
  \       'notes': 'カレントファイルの相対パスをクリップボードにコピー'
  \     },
  \   ]
  \ },
  \ 'fzf': {
  \   'title': 'FZF操作',
  \   'items': [
  \     {
  \       'command': '<leader><leader>',
  \       'description': 'プロジェクトのファイル名検索',
  \       'notes': 'プロジェクト内の最近使ったファイル + Git管理ファイルを表示'
  \     },
  \     {
  \       'command': '<leader>r',
  \       'description': 'プロジェクト内のgrep検索',
  \       'notes': '検索結果をファイルと行番号で表示'
  \     },
  \     {
  \       'command': '<leader>d',
  \       'description': '差分ファイル検索',
  \       'notes': '親ブランチとの差分ファイルを表示'
  \     },
  \     {
  \       'command': '<leader>o',
  \       'description': '最近使ったファイル検索',
  \       'notes': 'Git管理下の最近使ったファイルを表示'
  \     },
  \   ]
  \ },
  \ 'buffer': {
  \   'title': 'バッファ操作',
  \   'items': [
  \     {
  \       'command': '<leader>b',
  \       'description': 'バッファ一覧を表示',
  \       'notes': 'バッファ番号を入力して切り替え'
  \     }
  \   ]
  \ },
  \ 'tab': {
  \   'title': 'タブ操作',
  \   'items': [
  \     {
  \       'command': '<leader>tt',
  \       'description': 'タブパネルの表示/非表示を切り替え',
  \       'notes': '右側の垂直タブパネルの表示を切り替え'
  \     },
  \     {
  \       'command': 'tj',
  \       'description': 'タブを下に移動',
  \       'notes': '現在のタブを次の位置に移動'
  \     },
  \     {
  \       'command': 'tk',
  \       'description': 'タブを上に移動',
  \       'notes': '現在のタブを前の位置に移動'
  \     },
  \   ]
  \ },
  \ 'window': {
  \   'title': 'ウィンドウ操作',
  \   'items': [
  \     {
  \       'command': '<C-h>',
  \       'description': 'ウィンドウ幅を左に縮小',
  \       'notes': '10文字分縮小'
  \     },
  \     {
  \       'command': '<C-l>',
  \       'description': 'ウィンドウ幅を右に拡大',
  \       'notes': '10文字分拡大'
  \     },
  \     {
  \       'command': '<C-k>',
  \       'description': 'ウィンドウの高さを縮小',
  \       'notes': '5行分縮小'
  \     },
  \     {
  \       'command': '<C-j>',
  \       'description': 'ウィンドウの高さを拡大',
  \       'notes': '5行分拡大'
  \     },
  \     {
  \       'command': '<leader>mm',
  \       'description': 'ウィンドウの最大化/均等化',
  \       'notes': '現在のウィンドウを最大化または元に戻す（ターミナルでも使用可能）'
  \     },
  \   ]
  \ },
  \ 'git': {
  \   'title': 'Git操作',
  \   'items': [
  \     {
  \       'command': 'gn',
  \       'description': '次の変更箇所へジャンプ',
  \       'notes': 'GitGutterの次のハンクへ移動'
  \     },
  \     {
  \       'command': 'gp',
  \       'description': '前の変更箇所へジャンプ',
  \       'notes': 'GitGutterの前のハンクへ移動'
  \     },
  \     {
  \       'command': 'gha',
  \       'description': '変更をステージング',
  \       'notes': '現在のハンクをgit addする'
  \     },
  \     {
  \       'command': 'ghu',
  \       'description': '変更を取り消し',
  \       'notes': '現在のハンクの変更を元に戻す'
  \     },
  \     {
  \       'command': 'ghp',
  \       'description': '変更内容をプレビュー',
  \       'notes': 'フローティングウィンドウで差分を表示'
  \     },
  \     {
  \       'command': 'ghf',
  \       'description': '変更されていない部分を折りたたみ',
  \       'notes': 'GitGutterFoldで差分のみ表示'
  \     },
  \     {
  \       'command': 'gD / :Jump diff',
  \       'description': 'git diffの結果をQuickfixに表示',
  \       'notes': 'Git Jumpでdiffを実行'
  \     },
  \     {
  \       'command': 'gM / :Jump merge',
  \       'description': 'マージコンフリクトをQuickfixに表示',
  \       'notes': 'Git Jumpでmerge状態を確認'
  \     },
  \     {
  \       'command': 'gG / :Jump grep',
  \       'description': 'git grepの結果をQuickfixに表示',
  \       'notes': 'Git Jumpでgrep検索を実行'
  \     },
  \   ]
  \ },
  \ 'quickfix': {
  \   'title': 'Quickfix操作',
  \   'items': [
  \     {
  \       'command': '<leader>qq',
  \       'description': 'Quickfixウィンドウの表示/非表示',
  \       'notes': '右側に垂直分割で表示'
  \     },
  \     {
  \       'command': ':cprev / F9',
  \       'description': '前のエラー/検索結果へジャンプ',
  \       'notes': 'Quickfixリストの前の項目へ'
  \     },
  \     {
  \       'command': ':cnext / F10',
  \       'description': '次のエラー/検索結果へジャンプ',
  \       'notes': 'Quickfixリストの次の項目へ'
  \     },
  \   ]
  \ },
  \ 'folding': {
  \   'title': '折りたたみ操作',
  \   'items': [
  \     {
  \       'command': 'zc',
  \       'description': '折りたたみを閉じる',
  \       'notes': 'カーソル位置の折りたたみをトグル'
  \     },
  \     {
  \       'command': 'zo',
  \       'description': '折りたたみを開く',
  \       'notes': 'カーソル位置の折りたたみをトグル'
  \     },
  \     {
  \       'command': 'zR',
  \       'description': 'すべての折りたたみを開く',
  \       'notes': 'ファイル全体の折りたたみを展開'
  \     },
  \     {
  \       'command': 'zM',
  \       'description': 'すべての折りたたみを閉じる',
  \       'notes': 'ファイル全体を折りたたむ'
  \     },
  \   ]
  \ },
  \ 'comment': {
  \   'title': 'コメント操作',
  \   'items': [
  \     {
  \       'command': 'gcc',
  \       'description': '現在行をコメント/アンコメント',
  \       'notes': 'caw.vimによるコメントトグル'
  \     },
  \     {
  \       'command': 'gc{motion}',
  \       'description': '指定範囲をコメント/アンコメント',
  \       'notes': '例: gcap でパラグラフをコメント'
  \     },
  \     {
  \       'command': 'gcw',
  \       'description': '単語をコメント',
  \       'notes': 'カーソル下の単語をコメント'
  \     },
  \   ]
  \ },
  \ 'terminal': {
  \   'title': 'ターミナル操作',
  \   'items': [
  \     {
  \       'command': '<Esc>',
  \       'description': 'ターミナルモードからノーマルモードへ',
  \       'notes': 'ターミナル内でEscapeキーを押してノーマルモードに移行'
  \     },
  \     {
  \       'command': 'a / i',
  \       'description': 'ターミナルモードで挿入モード',
  \       'notes': 'ターミナル内で挿入モードに切り替え'
  \     },
  \     {
  \       'command': ':term +curwin',
  \       'description': '現在のウィンドウでターミナルを開く',
  \       'notes': 'カレントウィンドウをターミナルに置き換え'
  \     },
  \     {
  \       'command': ':bo term',
  \       'description': '水平分割して最下部にターミナルを起動',
  \       'notes': '画面下部に新しいターミナルウィンドウを開く'
  \     },
  \     {
  \       'command': ':vert term',
  \       'description': '垂直分割してターミナルを起動',
  \       'notes': '画面右側に新しいターミナルウィンドウを開く'
  \     },
  \     {
  \       'command': 'C-z (デタッチ)',
  \       'description': 'Vimをバックグラウンドに送る',
  \       'notes': 'シェルに戻る。fgコマンドで復帰'
  \     },
  \   ]
  \ },
  \ 'function': {
  \   'title': 'ファンクションキー操作',
  \   'items': [
  \     {
  \       'command': 'F1',
  \       'description': 'Tigステータス表示',
  \       'notes': 'Tig Explorer - ステータス画面'
  \     },
  \     {
  \       'command': 'F2',
  \       'description': 'Tigログ表示',
  \       'notes': 'Tig Explorer - コミット履歴'
  \     },
  \     {
  \       'command': 'F3',
  \       'description': '現在のファイルをTigで開く',
  \       'notes': 'Tig Explorer - ファイル履歴'
  \     },
  \     {
  \       'command': 'F4',
  \       'description': '現在のファイルのBlameをTigで表示',
  \       'notes': 'Tig Explorer - 行ごとの変更履歴'
  \     },
  \     {
  \       'command': 'F9',
  \       'description': '前のQuickfix項目へ',
  \       'notes': ':cprev'
  \     },
  \     {
  \       'command': 'F10',
  \       'description': '次のQuickfix項目へ',
  \       'notes': ':cnext'
  \     },
  \     {
  \       'command': 'F11',
  \       'description': 'ヘルプポップアップを表示',
  \       'notes': 'このヘルプを表示'
  \     },
  \   ]
  \ },
  \ 'mru': {
  \   'title': 'MRU (最近使ったファイル)',
  \   'items': [
  \     {
  \       'command': ':bro old',
  \       'description': '最近開いたファイルを開く',
  \       'notes': '番号を選択してファイルを開く'
  \     },
  \     {
  \       'command': ':bro filter /keyword/ old',
  \       'description': '最近開いたファイルをキーワードでフィルタ',
  \       'notes': 'キーワードにマッチするファイルのみ表示'
  \     },
  \   ]
  \ },
  \ 'jump': {
  \   'title': 'ジャンプ・移動履歴',
  \   'items': [
  \     {
  \       'command': ':jumps',
  \       'description': 'ジャンプリストを表示',
  \       'notes': '移動履歴の一覧を表示'
  \     },
  \     {
  \       'command': 'C-i',
  \       'description': '次のジャンプ箇所へ移動',
  \       'notes': 'ジャンプリストの新しい箇所へ'
  \     },
  \     {
  \       'command': 'C-o',
  \       'description': '前のジャンプ箇所へ移動',
  \       'notes': 'ジャンプリストの古い箇所へ'
  \     },
  \   ]
  \ },
  \ 'changes': {
  \   'title': '変更履歴',
  \   'items': [
  \     {
  \       'command': ':changes',
  \       'description': '変更リストを表示',
  \       'notes': 'ファイル内の変更履歴一覧'
  \     },
  \     {
  \       'command': 'g,',
  \       'description': '次の変更箇所へ移動',
  \       'notes': '変更リストの新しい変更箇所へ'
  \     },
  \     {
  \       'command': 'g;',
  \       'description': '前の変更箇所へ移動',
  \       'notes': '変更リストの古い変更箇所へ'
  \     },
  \   ]
  \ },
  \ 'netrw': {
  \   'title': 'ファイルエクスプローラー (netrw)',
  \   'items': [
  \     {
  \       'command': ':Ex',
  \       'description': '現在のファイルのディレクトリでエクスプローラーを開く',
  \       'notes': 'カレントファイルと同じディレクトリを表示'
  \     },
  \     {
  \       'command': ':Vex',
  \       'description': 'エクスプローラーを垂直分割で開く',
  \       'notes': '画面を分割してファイル一覧を表示'
  \     },
  \   ]
  \ }
  \}
