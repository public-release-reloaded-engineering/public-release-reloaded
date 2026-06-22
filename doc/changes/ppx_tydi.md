# ppx_tydi

- `src/ppx_tydi.ml` line 12: added `~constraint_:drop` to the `value_binding`
  pattern inside `pack2 (value_binding ~pat:__ ~expr:__ ~constraint_:drop)`.
  ppxlib ≥ 0.38 added a required `~constraint_` labeled parameter to
  `Ast_pattern.value_binding` matching the new `pvb_constraint` field in OCaml 5.x.
  Without it the pattern is partially applied (still awaiting `~constraint_`), which
  causes a type error when `pack2` expects a fully saturated pattern.
