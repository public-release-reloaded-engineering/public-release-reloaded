# streamable

- `ppx/src/variant_clause.ml` line 125: replaced `pexp_function ~loc cases` with
  `pexp_function_cases ~loc cases`.  ppxlib ≥ 0.38 changed `pexp_function` to take
  `function_param list * type_constraint option * function_body`; `pexp_function_cases`
  is the compatibility wrapper for `case list`.

- `ppx/src/nested_variant.ml` lines 171 and 178: same fix — two calls to
  `pexp_function ~loc cases` replaced with `pexp_function_cases ~loc cases`.
