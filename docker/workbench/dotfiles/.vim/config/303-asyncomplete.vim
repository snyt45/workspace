if empty(globpath(&rtp, 'autoload/asyncomplete.vim'))
  finish
endif

let g:asyncomplete_popup_delay = 100
