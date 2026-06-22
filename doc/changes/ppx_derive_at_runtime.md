# ppx_derive_at_runtime

- `src/ppx_derive_at_runtime.ml`: replaced `Ocaml_common.Parse.simple_module_path
  (Lexing.from_string string)` with `Longident.parse string` in `parse_identifier`.
  In OCaml 5.5 / ppxlib 0.38+, `Ocaml_common.Longident.t` and ppxlib's `longident`
  type alias are no longer the same physical type from the compiler's perspective,
  causing a type error at the call site.  `Ppxlib.Longident.parse` returns the
  correct `longident` type.

- `src/ppx_derive_at_runtime.ml` line 414: replaced `pexp_function ~loc` with
  `pexp_function_cases ~loc` in the `convert_expr` fold.  Same ppxlib API change
  as other ppx packages: `pexp_function` no longer accepts a `case list` directly.
