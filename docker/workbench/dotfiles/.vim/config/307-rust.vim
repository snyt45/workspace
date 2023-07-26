if empty(globpath(&rtp, 'autoload/rust.vim'))
  finish
endif

" 保存時に自動でrustfmt
let g:rustfmt_autosave = 1
