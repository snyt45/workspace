if empty(globpath(&rtp, 'autoload/lightline.vim'))
  finish
endif

if !has('gui_running')
  set t_Co=256
endif

let g:lightline = {
  \ 'colorscheme': 'gruvbox',
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ],
  \             [ 'gitbranch', 'readonly', 'filename', 'modified' ],
  \           ]
  \ },
  \ 'component_function': {
  \   'gitbranch': 'fugitive#head',
  \ },
  \ }
