# hardcaml_step_testbench

- `digital_components/src/step_core_intf.ml` and `step_core.ml`: renamed the
  type parameter `'effect` to `'effect_` throughout.  OCaml 5.3 made `effect`
  a hard keyword; the lexer now tokenises `'effect` as the quote character `'`
  followed by the keyword `effect`, causing a syntax error in type parameter
  positions.

---

## Current status: excluded from build

Despite the above fix, `hardcaml_step_testbench` is not built by the
workspace.  The package's directory is a git repository (sub-submodule) and
dune's git-source tracking interacts poorly with deeply nested git repos in
the workspace tree.  The package is excluded via `(dirs ())` in its top-level
dune file.  See `doc/changes/ocaml55-compat.md` §10.
