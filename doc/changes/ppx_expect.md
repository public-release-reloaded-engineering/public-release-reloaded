# ppx_expect

## Corrected-file path dropped the library's subdirectory (nested libraries crashed)

At exit, the expect-test runtime writes a `.corrected` file for every source
file that registered a `let%expect_test` (pass or fail). When the inline-test
runner is given a source-tree root — which dune passes as
`-source-tree-root %{workspace_root}` (relative to the runner's cwd, i.e. the
library's build dir) — the runtime rebuilt the file path from the **basename**
only:

```ocaml
(* runtime/ppx_expect_runtime.ml, before *)
| Some source_tree_root ->
  Stdlib.Filename.concat source_tree_root (Stdlib.Filename.basename filename)
```

`filename` here is the results-table key, which is
`Current_file.absolute_path ~filename_rel_to_cwd:basename` (`test_block.ml`) —
already reduced to the basename. So for a library at `foo/bar/` the runtime
computed `<root>/baz.ml` instead of `<root>/foo/bar/baz.ml`, then
`Write_corrected_file.f` opened it and died:

```
Fatal error: exception Sys_error("../../baz.ml: No such file or directory")
```

Every library **not at the workspace root** that contained a `let%expect_test`
was affected (files with only `let%test`/`let%test_unit` register nothing, so
they were unaffected — which is why such libraries appeared green).

This is an upstream bug in the `v0.18~preview.130.100+614` import (commit
`d36acdd`), not introduced by the port.

**Fix:** thread the full `filename_rel_to_project_root` (which the ppx already
records correctly — verified via `dune describe pp`) through the results table
to the corrected-file evaluator, and use it instead of the basename when a
source-tree root is set:

```ocaml
| Some source_tree_root ->
  Stdlib.Filename.concat source_tree_root filename_rel_to_project_root
```

Files changed (all in `runtime/`):
- `test_node.ml` / `test_node.mli`: add `filename_rel_to_project_root` to the
  per-file table record; thread it through `initialize_and_register_tests` and
  `process_each_file`.
- `test_block.ml`: pass `~filename_rel_to_project_root` at registration.
- `ppx_expect_runtime.ml`: use it in the `source_tree_root` branch.

The `None` branch (no source-tree root; cwd is the library dir, so
`basename` resolves correctly) is unchanged.

Verified with a nested library containing a passing `let%expect_test`: it
crashed with `Sys_error("../../probe.ml: …")` before the fix and passes after.
