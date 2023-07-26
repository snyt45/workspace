if empty(globpath(&rtp, 'plugin/fzf.vim'))
  finish
endif

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }

function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction
let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-e': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }
