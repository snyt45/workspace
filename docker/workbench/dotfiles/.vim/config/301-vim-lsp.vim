if empty(globpath(&rtp, 'autoload/lsp.vim'))
  finish
endif

" hover scroll
nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
nnoremap <buffer> <expr><c-b> lsp#scroll(-4)

let g:lsp_diagnostics_enabled = 1       " Diagnosticsを有効にする
let g:lsp_diagnostics_echo_cursor = 1   " カーソル下のエラー、警告、情報、ヒントを画面下部のコマンドラインに表示
let g:lsp_diagnostics_echo_delay = 50
let g:lsp_diagnostics_float_cursor = 1  " カーソル下のエラー、警告、情報、ヒントをフロート表示
let g:lsp_diagnostics_signs_enabled = 1 " 画面左端のサイン列にエラー、警告、情報、ヒントのアイコンを表示
let g:lsp_diagnostics_signs_delay = 50
let g:lsp_diagnostics_signs_insert_mode_enabled = 0
" let g:lsp_diagnostics_signs_error = {'text': '👾'}
" let g:lsp_diagnostics_signs_warning = {'text': '💣️'}
" let g:lsp_diagnostics_signs_hint = {'text': '💡'}
" let g:lsp_diagnostics_signs_information = {'text': 'ℹ️'}
let g:lsp_diagnostics_highlights_delay = 50
let g:lsp_diagnostics_highlights_insert_mode_enabled = 0
let g:lsp_document_code_action_signs_enabled = 0 " 画面左端のサイン列にコードアクションのアイコン非表示

" vim-lsp がバッファで有効になったときに実行される関数
" バッファローカルなキーバインドやオプションを指定
" See: https://mattn.kaoriya.net/software/vim/20191231213507.htm
function! s:on_lsp_buffer_enabled() abort
  let g:lsp_format_sync_timeout = 1000

  " golang
  " バッファ保存時に毎回「import補完」と「コードフォーマット」を実行
  autocmd BufWritePre *.go call execute(['LspCodeActionSync source.organizeImports', 'LspDocumentFormatSync'])
endfunction

augroup lsp_install
  au!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" debug
" let g:lsp_log_verbose = 1 " ログを有効にする
" let g:lsp_log_file = expand('~/.shared_cache/.vim/vim-lsp.log') " ログの出力先
