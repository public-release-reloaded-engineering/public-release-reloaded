# ppx_yojson_conv

- `expander/ppx_yojson_conv_expander.ml`: replaced all `pexp_function ~loc cases`
  / `pexp_function ~loc matchings` calls with `pexp_function_cases ~loc …`
  (lines 965, 1608, 1854 and a global replacement).  ppxlib ≥ 0.38 changed
  `pexp_function` to take `function_param list * type_constraint option *
  function_body`; `pexp_function_cases` is the compatibility wrapper for `case list`.
