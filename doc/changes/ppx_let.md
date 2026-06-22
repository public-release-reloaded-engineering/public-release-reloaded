# ppx_let

- `expander/ppx_let_expander.ml` line 558: replaced `pexp_function ~loc cases` with
  `pexp_function_cases ~loc cases`.  ppxlib ≥ 0.38 changed the `pexp_function`
  signature; `pexp_function_cases` is the compatibility wrapper for `case list`.

- `expander/ppx_let_expander.ml` lines 125 and 133: renamed `~loc` to `~loc:_` in
  `wrap_exclave` and `maybe_wrap_local`.  Their bodies are `[%expr [%e expr]]` / 
  `[%expr [%e func]]`, which are identity substitutions — no new AST node is created
  so `loc` is never referenced; OCaml 5.x strict warning 27 is an error.
