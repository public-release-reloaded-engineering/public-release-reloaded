# ppx_bin_prot

- `src/ppx_bin_prot.ml`: replaced four calls `pexp_function ~loc cases` with
  `pexp_function_cases ~loc cases` (lines 546, 826, 943, 1255).  ppxlib ≥ 0.38
  changed `pexp_function` to take `function_param list * type_constraint option *
  function_body` instead of `case list`; `pexp_function_cases` is the compatibility
  wrapper that accepts a `case list` and wraps it in `Pfunction_cases`.
