if empty(globpath(&rtp, 'autoload/copilot.vim'))
  finish
endif

let g:copilot_filetypes = { 'gitcommit': v:true }
