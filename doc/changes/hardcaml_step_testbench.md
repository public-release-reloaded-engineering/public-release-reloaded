# hardcaml_step_testbench

- `digital_components/src/step_core_intf.ml` and `step_core.ml`: renamed the
  type parameter `'effect` to `'effect_` throughout.  OCaml 5.3 made `effect`
  a hard keyword; the lexer now tokenises `'effect` as the quote character `'`
  followed by the keyword `effect`, causing a syntax error in type parameter
  positions.

---

## Current status: excluded from build

`hardcaml_step_testbench` is not built because it depends on
`Handled_effect.S2`, a module type defined in
`handled_effect/raises_in_jsoo/handled_effect_intf.ml` using OxCaml-only
syntax:

- `module type%template` (JST `ppx_template` syntax)
- `@@ portable` modal annotations on module types

In this workspace, `handled_effect_raises_in_jsoo` is built with
`(modules)` (empty module list) because its source cannot be compiled with
standard OCaml.  `handled_effect` re-exports it but exposes no types, so
`Handled_effect.S2` is unbound when `step_core_intf.ml` references it.

This is the same category of OxCaml dependency as `await`, `concurrent`, and
`parallel`.  The package is excluded via `(dirs ())` in its top-level dune
file.  See `doc/changes/ocaml55-compat.md` §10.
