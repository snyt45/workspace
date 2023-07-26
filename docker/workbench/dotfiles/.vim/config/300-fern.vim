if empty(globpath(&rtp, 'autoload/fern.vim'))
  finish
endif

let g:fern#default_hidden=1 " 隠しファイルを表示する
let g:fern#renderer='nerdfont'
let g:fern#renderer#nerdfont#indent_markers = 1
