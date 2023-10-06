if empty(globpath(&rtp, 'autoload/quickrun.vim'))
  finish
endif

let g:quickrun_config = {}
let g:quickrun_config.rust = {'exec' : 'cargo run'}
