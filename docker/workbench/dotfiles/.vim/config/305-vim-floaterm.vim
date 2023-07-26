if empty(globpath(&rtp, 'autoload/floaterm.vim'))
  finish
endif

let g:floaterm_shell = 'bash'
let g:floaterm_height = 0.9
let g:floaterm_width = 0.9
let g:floaterm_autoclose = 2

let g:floaterm_keymap_new    = '<F7>'
let g:floaterm_keymap_prev   = '<F8>'
let g:floaterm_keymap_next   = '<F9>'
let g:floaterm_keymap_toggle = '<F12>'
