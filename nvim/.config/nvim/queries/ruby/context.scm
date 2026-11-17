; treesitter-context が上に残す行。クラス・モジュール・メソッドと、RSpec のブロックだけにする
; （プラグイン同梱のクエリは if・case・do ブロックなども残す。この同名ファイルがそれを置き換える）

(class
  (body_statement) @context.end) @context

(singleton_class
  (body_statement) @context.end) @context

(module
  (body_statement) @context.end) @context

(method
  (body_statement) @context.end) @context

(singleton_method
  (body_statement) @context.end) @context

(call
  method: (identifier) @_identifier
  block: (do_block
    body: (body_statement) @context.end)
  (#any-of? @_identifier
    "it" "it_behaves_like" "include_examples" "include_context" "context" "describe"
    "shared_context" "shared_examples")) @context
