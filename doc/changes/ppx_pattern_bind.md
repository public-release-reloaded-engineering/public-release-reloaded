# ppx_pattern_bind

- `src/ppx_pattern_bind.ml` lines 289 and 293: replaced `pexp_function ~loc [...]`
  with `pexp_function_cases ~loc [...]`.  ppxlib ≥ 0.38 changed `pexp_function`
  to require `function_param list * type_constraint option * function_body` instead
  of a `case list`; `pexp_function_cases` is the compatibility wrapper.

## ppxlib 0.38 labeled-tuple encoding in `variables_of` and `replace_variable`

ppxlib 0.38 encodes OCaml 5.5 labeled-tuple patterns as extension nodes
(`ppxlib.migration.ppat_labeled_tuple_5_4`).  The encoding uses `Ppat_var`
nodes for label names and for the open/closed flag (`"closed_"`).

`Ast_traverse.map`/`fold` descend into extension payloads, so the two
traversal objects in `src/ppx_pattern_bind.ml` were treating label names and
the `closed_` flag as user-bound variables, causing phantom variables in the
generated code.

**Fixes in `src/ppx_pattern_bind.ml`:**

- `variables_of`: override `method! pattern` to detect the labeled-tuple
  extension, decode it with
  `Astlib__Encoding_504.To_502.decode_ppat_labeled_tuple`, and recurse only
  on the value patterns (second element of each `(label, pattern)` pair),
  skipping label `Ppat_var` nodes and the `closed_` flag entirely.

- `replace_variable`: same detection and decode; recurse with `self#pattern`
  on value patterns only, then re-encode the result so the extension node
  structure is preserved.

See also `doc/changes/ocaml55-compat.md` §9 for the ppxlib 0.38 context and
the same fix applied to `bonsai/ppx_bonsai/src/expander/ppx_bonsai_expander.ml`.
