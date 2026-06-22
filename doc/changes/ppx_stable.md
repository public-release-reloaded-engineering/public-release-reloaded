# ppx_stable

- `src/variants.ml` line 171: replaced `pexp_function ~loc cases` with
  `pexp_function_cases ~loc cases`.  ppxlib ≥ 0.38 changed `pexp_function`
  to take `function_param list * type_constraint option * function_body` instead
  of a `case list`; `pexp_function_cases` is the compatibility wrapper.
