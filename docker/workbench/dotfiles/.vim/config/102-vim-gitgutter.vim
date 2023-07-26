if empty(globpath(&rtp, 'autoload/gitgutter.vim'))
  finish
endif

let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '>'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '<'

" ref: https://teratail.com/questions/29844#reply-46767
augroup vimrc_vim_gitgutter
  autocmd!
  " colorscheme読み込み後、サイン列の背景色をNONEにする ※Windows Terminal側の色を使いたいため
  autocmd VimEnter,ColorScheme * highlight SignColumn guibg=NONE ctermbg=NONE

  " colorscheme読み込み後、サイン列の記号の色を設定
  autocmd VimEnter,ColorScheme * highlight GitGutterAdd guibg=NONE ctermbg=NONE guifg=#000900 ctermfg=2
  autocmd VimEnter,ColorScheme * highlight GitGutterChange guibg=NONE ctermbg=NONE guifg=#bbbb00 ctermfg=3
  autocmd VimEnter,ColorScheme * highlight GitGutterDelete guibg=NONE ctermbg=NONE guifg=#ff2222 ctermfg=1
augroup END
