# ppx_typerep_conv

- `src/ppx_typerep_conv.ml` line 811: replaced `pexp_function ~loc match_cases` with
  `pexp_function_cases ~loc match_cases`.  ppxlib ≥ 0.38 changed `pexp_function`
  to take `function_param list * type_constraint option * function_body` instead
  of a `case list`; `pexp_function_cases` is the compatibility wrapper.
