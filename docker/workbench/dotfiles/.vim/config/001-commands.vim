" カレントバッファのファイルパスをクリップボードにコピー
command! CopyFilePath :echo "copied fullpath: " . expand('%:p') | let @"=expand('%:p') | call system('clip -i', @")

" fzfでカレントディレクトリ配下のgit管理ファイル検索
command! -bang -nargs=? GFilesCwd
  \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(<q-args> == '?' ? { 'dir': getcwd(), 'placeholder': '' } : { 'dir': getcwd() }), <bang>0)

" globを指定して、Rgコマンドを実行する
" graphqlを含むディレクトリに絞り込んで検索 :Rgglob '**/*graphql*/**'
" graphqlを含むファイルに絞り込んで検索 :Rgglob '*graphql*'
function! Rgglob(query, fullscreen)
  let glob_pattern = input("glob pattern? : ", "'**/*ptn*/**'")
  call fzf#vim#grep("rg --column --hidden --line-number --no-heading --color=always --ignore-case "."-g ".glob_pattern." -- ".shellescape(a:query), 1, fzf#vim#with_preview(), a:fullscreen)
endfunction

command! -nargs=* Rgglob call Rgglob("", 0)

" ref: https://zenn.dev/kato_k/articles/vim-tips-no004
command! Profile call s:command_profile()
function! s:command_profile() abort
  profile start ~/profile.txt
  profile func *
  profile file *
endfunction
