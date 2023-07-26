augroup filepath_typescriptreact
  au!
  autocmd FileType typescriptreact :setl path+=**;/features/**
  autocmd FileType typescriptreact :setl includeexpr=substitute(v:fname,'^/','','')
augroup END
