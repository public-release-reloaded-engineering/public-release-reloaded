# ppx_module_timer

## Split into three opam packages

The repo previously shipped a single opam package, `ppx_module_timer`, providing
three libraries: the ppx rewriter (`ppx_module_timer`), its runtime
(`ppx_module_timer.runtime`), and ppxlib helpers (`ppx_module_timer.helpers`).

Because they were one package, anything that needed *only* the runtime or the
helpers still pulled in the whole package — including the ppx rewriter. In
particular `core` (via `time_ns.ml`, which registers a `Time_ns.Span`-based
`Duration.format` into the runtime) needs the runtime, and `ppx_css` needs the
helpers; since essentially everything depends on `core`/`ppx_css`, the ppx was
always installed, and `ppx_jane`'s `(select)` therefore always enabled module
timing (see `doc/changes/ppx_jane.md`). Making the ppx a `depopts` of `ppx_jane`
had no real effect while the runtime and helpers lived in the same package.

The three libraries have no inter-library link dependencies (the ppx only
*generates* references to the runtime, declared via `(ppx_runtime_libraries)`),
so they were split into three opam packages:

- `ppx_module_timer` — the ppx rewriter. Depends on `ppx_module_timer_runtime`
  (its generated code references the runtime).
- `ppx_module_timer_runtime` — the runtime library (was `ppx_module_timer.runtime`).
- `ppx_module_timer_helpers` — the ppxlib helpers (was `ppx_module_timer.helpers`).

A dotted public name (`ppx_module_timer.runtime`) must belong to the package
named by its first component, so the split required renaming the public names to
top-level `ppx_module_timer_runtime` / `ppx_module_timer_helpers`. Changes in
this repo (no `.ml`/`.mli` changes):

- `runtime/dune`, `helpers/dune`: `public_name` renamed.
- `src/dune`: `(ppx_runtime_libraries ppx_module_timer.runtime)` →
  `ppx_module_timer_runtime`.
- `ppx_module_timer.opam` split into three `.opam` files.

Consumers were updated to depend on the specific library they use rather than the
whole package (see the per-package change docs): `core`, `bonsai`, `bonsai_web`,
`bonsai_web_components`, `roundtrippable_command_param` on
`ppx_module_timer_runtime`; `ppx_css`, `ppx_demo` on `ppx_module_timer_helpers`.
`core`, `bonsai`, and `bonsai_web` previously used the runtime but did not declare
it (they free-rode on `ppx_jane`'s formerly-unconditional dependency); they now
declare it explicitly.
