# ppx_pattern_bind

- `src/ppx_pattern_bind.ml` lines 289 and 293: replaced `pexp_function ~loc [...]`
  with `pexp_function_cases ~loc [...]`.  ppxlib ≥ 0.38 changed `pexp_function`
  to require `function_param list * type_constraint option * function_body` instead
  of a `case list`; `pexp_function_cases` is the compatibility wrapper.
