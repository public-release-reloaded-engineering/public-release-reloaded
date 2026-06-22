# ppx_jsonaf_conv

- `expander/ppx_jsonaf_conv_expander.ml`: replaced all `pexp_function ~loc cases`
  calls with `pexp_function_cases ~loc cases`.  ppxlib ≥ 0.38 changed `pexp_function`
  to take `function_param list * type_constraint option * function_body`; the
  `pexp_function_cases` compatibility wrapper accepts a `case list` directly.

- `expander/ppx_jsonaf_conv_expander.ml` line 71: renamed `~loc` to `~loc:_` in
  `wrap_with_exclave`.  The function body `[%expr [%e expr]]` is a no-op identity
  (substitutes `expr` unchanged), so `loc` is unused; OCaml 5.x strict warning 27
  makes this an error.
