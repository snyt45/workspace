; treesitter-context が上に残す行。クラス・メソッド・関数だけにする
; （プラグイン同梱のクエリは if・オブジェクト・JSX なども残す。この同名ファイルがそれを置き換える）

[
  (class_declaration)
  (method_definition)
] @context

(function_declaration
  body: (_
    (_) @context.end)) @context

(generator_function_declaration
  body: (_
    (_) @context.end)) @context

; const Foo = () => { ... } の形だけ。引数に渡すコールバックは残さない
(lexical_declaration
  (variable_declarator
    value: (arrow_function
      body: (_
        (_) @context.end)))) @context
