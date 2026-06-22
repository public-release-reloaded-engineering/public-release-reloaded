# ppx_with

- `src/ppx_with.ml` line 66: replaced `Ast_builder.Default.pexp_function cases ~loc`
  with `Ast_builder.Default.pexp_function_cases ~loc cases`.  ppxlib ≥ 0.38 changed
  `pexp_function` to take `function_param list * type_constraint option *
  function_body`; passing a `case list` now partially applies the function, yielding
  a non-expression type error at the call site.
