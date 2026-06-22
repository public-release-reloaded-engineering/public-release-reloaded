# ppx_variants_conv

- `src/ppx_variants_conv.ml`: replaced three calls `pexp_function ~loc cases` with
  `pexp_function_cases ~loc cases` (lines 615, 823, 835).  ppxlib ≥ 0.38 changed
  `pexp_function` to take `function_param list * type_constraint option *
  function_body`; `pexp_function_cases` is the compatibility wrapper for `case list`.
