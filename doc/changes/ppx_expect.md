# ppx_expect

- `src/ppx_expect.ml` lines 365–371: added `~constraint_:drop` to the
  `value_binding` pattern in the `uncaught_exn` attribute handler.  ppxlib ≥ 0.38
  added a required `~constraint_` labeled parameter to `Ast_pattern.value_binding`
  matching the new `pvb_constraint` field in OCaml 5.x; omitting it leaves the
  pattern partially applied, causing a type error.
