# ppx_inline_test

- `src/ppx_inline_test.ml`: added `~constraint_:drop` to the `value_binding` pattern
  in `opt_name_and_expr`.  ppxlib ≥ 0.38 added a required `~constraint_` labeled
  parameter to `Ast_pattern.value_binding` to match the new `pvb_constraint` field
  in OCaml 5.x's `value_binding` AST node; omitting it left the pattern partially
  applied, producing a type error.
