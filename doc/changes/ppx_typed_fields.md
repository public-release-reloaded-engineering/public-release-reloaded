# ppx_typed_fields

- `src/product_kind_generator.ml`: replaced all four `pexp_function cases` calls with
  `pexp_function_cases cases`.  ppxlib ≥ 0.38 changed `pexp_function` to take
  `function_param list * type_constraint option * function_body`; the modules open
  `Syntax.builder loc` which includes ppxlib's `pexp_function_cases` compatibility
  wrapper for `case list`.

- `src/variant_generator.ml`: same fix — replaced all five `pexp_function cases`
  with `pexp_function_cases cases`.

- `src/subset_of.ml`: replaced `pexp_function (List.map ...)` with
  `pexp_function_cases (List.map ...)` for the same reason.

- `src/type_kind.ml` lines 173 and 179: renamed `~loc` to `~loc:_` in
  `exclave_if_local` and `exclave_if_stack`.  Their bodies are identity
  expressions `[%expr [%e exp]]` so `loc` is unreferenced; OCaml 5.x strict
  warning 27 is an error.

- `src/ppx_typed_fields.ml` line 338: replaced `Ptyp_tuple labeled_types` with
  `Ptyp_tuple _` in a match arm guarded by `when true`.  `labeled_types` was
  extracted but never used in the arm body; OCaml 5.x strict warning 27 is an error.
