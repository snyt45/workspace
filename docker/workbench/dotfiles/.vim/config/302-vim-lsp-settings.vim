if empty(globpath(&rtp, 'autoload/lsp_settings.vim'))
  finish
endif

let g:lsp_settings_servers_dir='~/.shared_cache/.vim/servers'
let g:lsp_settings_filetype_ruby = ['solargraph']
