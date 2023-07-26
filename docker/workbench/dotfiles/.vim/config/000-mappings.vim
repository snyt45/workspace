let mapleader = "\<Space>"
let maplocalleader = ","

nmap j <Plug>(accelerated_jk_gj)
nmap k <Plug>(accelerated_jk_gk)
nmap <C-j> 5j
nmap <C-k> 5k
nmap <silent> <Esc><Esc> :<C-u>nohlsearch<CR><Esc> " 文字列検索のハイライトオフ
nmap PP "0p " ヤンクレジスタを使って貼り付け
map q <silent> " よくミスタイプするのでマクロ記録しないようにする

" ヤンクした内容をクリップボードにコピー
augroup Yank
  au!
  autocmd TextYankPost * :call system('clip -i', @")
augroup END

imap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
imap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
imap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"
