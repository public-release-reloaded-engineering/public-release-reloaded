# ppx_tydi

- `src/ppx_tydi.ml`: preserve the value binding's type annotation.

  `ppx_tydi` rewrites `let%tydi PAT = EXPR in BODY` into
  `match EXPR with PAT -> BODY`, relying on type-directed disambiguation to
  resolve `PAT`'s record-field labels from the type of `EXPR`.

  The extension matched value bindings with `~constraint_:drop`, discarding the
  binding's type annotation. On OxCaml the annotation in `let PAT : TY = EXPR`
  was carried on the pattern, so dropping the (separate) `pvb_constraint` was
  harmless. On stock OCaml 5.x, `let PAT : TY = EXPR` stores the annotation
  **only** in `pvb_constraint` (the pattern itself is unannotated), so dropping
  it lost `TY` entirely. Any `let%tydi PAT : TY = EXPR` where `EXPR`'s type was
  not otherwise determined then failed to disambiguate — e.g.

  ```
  Error: Unbound record field item
  ```

  in `skyline`'s picker_v2 typeahead worker
  (`let%tydi { item; original_index; score = _ } : Scored_index.t = Iarray.unsafe_get input index`).

  Fix: capture `pvb_constraint` (via `pack3` + `~constraint_:__` instead of
  `~constraint_:drop`) and re-attach a plain type constraint to the pattern as
  `(PAT : TY)`, restoring disambiguation. `Pvc_coercion` and the unannotated
  case are passed through unchanged, so the common `let%tydi PAT = EXPR` form
  (which was already fine) is unaffected. `ppx_tydi`'s own tests still pass.

  Impact: `%tydi` is used in ~69 files across `releases/`; only the
  explicitly-annotated form was affected.
