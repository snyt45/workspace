vim9script

# ==============================================================================
# Display
# ==============================================================================

# Show line numbers
# set number

# Highlight current line
set cursorline

# ==============================================================================
# Clipboard
# ==============================================================================

# Use system clipboard
set clipboard=unnamed

# ==============================================================================
# Search
# ==============================================================================

# Enable incremental search
set incsearch

# Highlight all matches
set hlsearch

# Ignore case in search patterns
set ignorecase

# Enable smart case search
set smartcase

# ==============================================================================
# Mouse Support
# ==============================================================================

# Enable mouse in all modes
set mouse=a

# ==============================================================================
# File Management
# ==============================================================================

# Auto reload file when changed externally
set autoread

# Check for file changes when focus returns
augroup AutoReload
  autocmd!
  autocmd FocusGained,BufEnter * checktime
  
  autocmd WinLeave * if &buftype == 'terminal' | 
    \ silent! GitGutterAll | 
    \ endif
augroup END

set noswapfile  # Disable swap files
set nobackup    # Disable backup files
set noundofile  # Disable undo files

# ==============================================================================
# File Search Configuration
# ==============================================================================

# Search path - current directory and subdirectories
set path=**

# Ignore patterns for file search
set wildignore+=**/node_modules/**
set wildignore+=**/.git/**
set wildignore+=**/vendor/**
set wildignore+=**/coverage/**
set wildignore+=**/.next/**
set wildignore+=**/dist/**
set wildignore+=**/build/**
set wildignore+=**/Pods/**

# Enable auto completion menu after pressing TAB.
set wildmenu
# Enable popup menu for command-line completion
set wildoptions=pum

# ===============================================================================
# Folding
# ==============================================================================

# Enable folding
set foldmethod=indent

# Set fold level to 99 to open all folds by default
set foldlevel=99

# ==============================================================================
# Tab Management
# ==============================================================================

# Disable horizontal tab line
set showtabline=0

# Always show tabpanel
set showtabpanel=2

# Display tab panel on the right side with vertical separator
set tabpanelopt=align:right,vert

# Customize tab panel to show only filename
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
# vim-plug enables: filetype plugin indent on, syntax enable
call plug#end()

# ==============================================================================
# Color Scheme
# ==============================================================================

# Enable true color support if available
if has('termguicolors')
  set termguicolors
endif

# Set gruvbox color scheme
colorscheme gruvbox

# Optional: set dark or light background
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

# ==============================================================================
# Configuration - GitGutter
# ==============================================================================

# Update sign column every quarter second
set updatetime=100

g:gitgutter_map_keys = 0
g:gitgutter_preview_win_floating = 1

g:gitgutter_sign_added = '+'
g:gitgutter_sign_modified = '>'
g:gitgutter_sign_removed = '-'
g:gitgutter_sign_removed_first_line = '^'
g:gitgutter_sign_modified_removed = '<'

# Highlight GitGutter signs with transparent background
highlight SignColumn guibg=NONE ctermbg=NONE
highlight GitGutterAdd guibg=NONE ctermbg=NONE
highlight GitGutterChange guibg=NONE ctermbg=NONE
highlight GitGutterDelete guibg=NONE ctermbg=NONE

# ==============================================================================
# Key mapping - General
#
# - map leader is ,
# ==============================================================================

g:mapleader = ","

# Disable recording
nnoremap q <Nop>

# Clear search highlight
nnoremap <Esc><Esc> :nohlsearch<CR>

# ===============================================================================
# Key mapping - Buffers
# ==============================================================================

nnoremap <leader>b :ls<CR>:b<Space>

# ===============================================================================
# Key mapping - Tabs
# ==============================================================================

def TabPanelToggle()
    if &showtabpanel == 0
        set showtabpanel=2  # never hide
    else
        set showtabpanel=0  # hide tab panel
    endif
enddef

command! Ttoggle TabPanelToggle()
nnoremap <leader>tt :Ttoggle<CR>

nnoremap tj :tabmove +1<CR>
nnoremap tk :tabmove -1<CR>

# ==============================================================================
# Key mapping - Quickfix
# ==============================================================================

def QuickfixToggle()
    if empty(filter(getwininfo(), (_, val) => val.quickfix))
        vert copen
        setlocal nowrap
        vertical resize 40
    else
        cclose
    endif
enddef

command! Qtoggle QuickfixToggle()
nnoremap <leader>qq :Qtoggle<CR>

# ==============================================================================
# Key mapping - Window
# ==============================================================================

nnoremap <C-h> :vertical resize -10<CR>
nnoremap <C-l> :vertical resize +10<CR>
nnoremap <C-k> :resize -5<CR>
nnoremap <C-j> :resize +5<CR>

# ==============================================================================
# Key mapping - Copy File Path
# ==============================================================================

def CopyFilePath()
    @* = expand('%:.')
    echo 'Copied: ' .. expand('%:.')
enddef

nnoremap <leader>cp <scriptcmd>CopyFilePath()<CR>

# ==============================================================================
# Key mapping - GitGutter
# =============================================================================

# Jump between hunks
nmap gn <Plug>(GitGutterNextHunk)
nmap gp <Plug>(GitGutterPrevHunk)

# Hunk-add and hunk-revert for chunk staging
nmap gha <Plug>(GitGutterStageHunk)
nmap ghu <Plug>(GitGutterUndoHunk)
nmap ghp <Plug>(GitGutterPreviewHunk)

# ==============================================================================
# Git Jump integration
#
# Usage:
#   :Jump diff
#   :Jump merge
#   :Jump grep foo
# ==============================================================================

command! -bar -nargs=* Jump cexpr system('git jump --stdout ' .. <q-args>)

nnoremap <leader>gj :Jump diff<CR>
nnoremap <leader>gm :Jump merge<CR>
nnoremap <leader>gg :Jump grep<Space>

# ==============================================================================
# FZF Integration
# ==============================================================================

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

def GetProjectRecentFiles(): list<string>
    UpdateCurrentFileInOldfiles()
    
    var gitfiles = systemlist('git ls-files')
    var gitset = {}
    for f in gitfiles
        gitset[fnamemodify(f, ':p')] = f
    endfor

    var recent_set = {}
    var recent_files = []
    
    for f in v:oldfiles[0 : 50]
        var fullpath = fnamemodify(f, ':p')
        if has_key(gitset, fullpath)
            var relative = gitset[fullpath]
            recent_set[relative] = 1
            add(recent_files, relative)
            if len(recent_files) >= 10
                break
            endif
        endif
    endfor
    
    var result = []
    for f in recent_files
        add(result, "\x1b[32m" .. f .. "\x1b[0m")  # 緑色
    endfor
    
    for f in gitfiles
        if !has_key(recent_set, f)
            add(result, f)
        endif
    endfor
    
    return result
enddef

def GrepSink(line: string)
    var parts = split(line, ':')
    if len(parts) >= 2
        execute 'e ' .. parts[0]
        execute ':' .. parts[1]
    endif
enddef

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
    \ 'options': ['--prompt', 'Rg> ', '--ansi', '--delimiter', ':', '--nth', '3..'],
    \ 'window': {'width': 0.9, 'height': 0.6}
    \ })<CR>
