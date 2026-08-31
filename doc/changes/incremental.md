# incremental

## `incremental_debug` made a public, standalone package

`incremental_debug` (`src-debug/`) is a copy of the `incremental` library built
with internal debug assertions enabled (via `ppx_optcomp` + `debug.mlh`). It was
a **private** library (`(name incremental_debug)`, no `public_name`).

In the Jane Street monorepo the whole tree is a single dune-project, so a private
library is visible everywhere — and `incr_select/test` references
`incremental_debug`. In this release `incremental` and `incr_select` are separate
dune-projects (separate packages), and a private library is not visible across
projects, so building `incr_select/test` failed with:

```
Error: Library "incremental_debug" not found.
```

`@install` did not surface this because test-only libraries are not installed.

Changes (`incremental` repo):

- `src-debug/dune`: added `(public_name incremental_debug)` so the library is
  visible across projects.
- `src-debug/dune`: added `(flags (:standard -w -67))`, mirroring `src/dune`. The
  debug library is a generated copy of the same source, which triggers
  `unused-functor-parameter` (warning 67); this was latent because the private
  library was never built by `@install`.
- Added `incremental_debug.opam` — a **separate** opam package (rather than an
  `incremental.debug` sub-library) so the main `incremental` package does not have
  to build and install the assertion-heavy debug variant. It depends on
  `incremental` for the `incremental.incremental_step_function` sub-library it
  reuses.

`incr_select.opam` is intentionally left unchanged: `incremental_debug` is used
only by `incr_select/test`, and this tree does not record test-only dependencies
in opam files (e.g. `incr_select.opam` also omits `expect_test_helpers_core`,
which its test uses). The `public_name` alone fixes the workspace build.

Note: `incremental/test` and `incremental/test-debug` remain unbuildable for an
unrelated, pre-existing reason — they depend on `expect_test_sexp_diff` and
`expect_test_graphviz`, which are not present in the release.
