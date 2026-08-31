# incremental

## Recompute-heap corruption from boxed `or_null` (stale values / silent bug)

`Recompute_heap.unlink` (`src/recompute_heap.ml`) decided whether a node was the
head of its height bucket with a physical-identity check on an `or_null` value:

```ocaml
if phys_same (This node) (Uniform_array.get t.nodes_by_height node.height_in_recompute_heap)
then Uniform_array.unsafe_set t.nodes_by_height node.height_in_recompute_heap next;
```

On OxCaml `or_null` is unboxed — `This node` is represented identically to
`node` — so this compares node pointers and correctly finds the head. This
release builds against base's **boxed** `or_null` shim (`Null | This of _`), so
`This node` allocates a fresh box on every evaluation that never physically
equals the box already stored in `nodes_by_height`. The head-check was therefore
**always false**: when the head node of a bucket was unlinked, the bucket head
was never repointed, corrupting the intrusive list and desynchronising the
heap's `length` counter.

Symptom: after a `stabilize` in which a `bind`'s left-hand side changes *and* a
node the newly-selected right-hand side depends on also changes, observed nodes
silently return **stale values**. (Bonsai keeps its whole model in one `Var`, so
a bind's lhs and its rhs's dependencies change together — this reaches Bonsai
apps.) The release build fails silently; the `incremental_debug` build's
`invariant` catches it immediately (`recompute_heap` `length` `2 vs 3`).

**Fix:** a node is the list head iff its `prev` link is `Null` — an invariant
the code already maintains and asserts in `Node.invariant`. Replaced the
`phys_same (This node) …` head-check with a representation-independent
`Or_null.is_null node.prev_in_recompute_heap`. This is the only
`phys_same`-on-raw-`or_null` in incremental (the others unwrap with `value_exn`
first).

Provenance: not caused by the port's incremental edits — `src/*.ml` is identical
to the upstream `v0.18~preview.130.106+341` import. The reliance on unboxed
`or_null` in this file entered upstream at `v0.18~preview.130.91+190`, which
switched `recompute_heap.ml` from `Uopt` (a library that is genuinely unboxed on
stock OCaml) to `or_null` (a compiler feature, unboxed only on OxCaml). The
underlying incompatibility is base's boxed `or_null` shim; any incremental at or
after that version, built against this base, is affected.

---

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
