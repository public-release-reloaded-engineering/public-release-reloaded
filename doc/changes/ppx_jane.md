# ppx_jane

## `ppx_module_timer` made an optional ("incorporate if installed") dependency

`ppx_jane` linked `ppx_module_timer` unconditionally, so its whole-program
module-timing instrumentation was injected into every module preprocessed with
`ppx_jane` (the runtime recording is gated by the `PPX_MODULE_TIMER`
environment variable, but the wrapper code and the runtime-library link were
always present).

`ppx_module_timer` is now an **optional** dependency: it is incorporated when
its library is installed, and omitted otherwise. A consumer who does not want
module timing simply does not install the `ppx_module_timer` package.

Two coordinated changes are needed, because opam's `depopts` and dune's
link-time library resolution are separate concerns:

- `ppx_jane.opam`: moved `ppx_module_timer` from `depends` to `depopts`, so opam
  no longer requires it to install `ppx_jane`.
- `src/dune`: replaced the plain `ppx_module_timer` entry in `(libraries)` with a
  `(select)` on the `ppx_module_timer` library:

  ```
  (select ppx_module_timer_select.ml from
    (ppx_module_timer -> ppx_module_timer_select.enabled.ml)
    (-> ppx_module_timer_select.disabled.ml))
  ```

  A ppxlib transformation runs as a side effect of its library being linked, so
  "optional" must be expressed at the link level, not merely in opam. When the
  `ppx_module_timer` library is available, `(select)` adds it to `ppx_jane`'s
  link dependencies (its `Driver.register_transformation` then runs, exactly as
  the previous direct listing did); when it is absent, the fallback branch links
  nothing extra and `ppx_jane` builds without module timing. The two
  `ppx_module_timer_select.{enabled,disabled}.ml` files are empty stubs — they
  exist only to drive the `select`.

Notes:
- The `ppx_module_timer` opam package also provides the `ppx_module_timer.runtime`
  and `ppx_module_timer.helpers` libraries. There are two, quite different, ways
  the rest of the release pulls the package in:

  1. **Transitively, via the ppx (the common case).** `ppx_module_timer/src/dune`
     declares `(ppx_runtime_libraries ppx_module_timer.runtime)`, so dune
     automatically adds `ppx_module_timer.runtime` to the link of *any* library
     preprocessed with a driver that includes the ppx. That is how every
     `ppx_jane` consumer — `core`, `bonsai`, essentially all ~300 packages —
     resolves the injected `Ppx_module_timer_runtime.record_start`/`record_until`
     calls (e.g. `core/core/src/time_ns.ml`'s `open Ppx_module_timer_runtime`,
     `bonsai`'s `startup_timing_protocol`). None of them list it in their own
     `(libraries)`. This dependency now tracks the `select`: present when the ppx
     is linked, gone when it isn't — self-consistent, since without the ppx no
     such calls are generated.

  2. **Explicitly, in `(libraries)` (a handful of packages).** These reference a
     `ppx_module_timer` library directly, independent of `ppx_jane`, so they keep
     a hard dependency on the package regardless of this change:
     - `ppx_module_timer.helpers`: `ppx_css/src`, `ppx_demo/src`.
     - `ppx_module_timer.runtime`: `bin_prot/bench`, `ocaml_intrinsics_kernel/{bench,test}`,
       `roundtrippable_command_param/ppx_or_default/src`,
       `bonsai_web_components/bonsai_codemirror/lib/bindings`.

  Originally these three libraries were one opam package, so any consumer of the
  runtime or helpers (e.g. `core`, `ppx_css`) pulled the whole package in,
  including the ppx — which made the `depopts` here ineffective: the ppx was
  always installed, so `(select)` always enabled timing. To make the optionality
  real, the package was split into `ppx_module_timer` (ppx),
  `ppx_module_timer_runtime`, and `ppx_module_timer_helpers`
  (see `doc/changes/ppx_module_timer.md`), and each consumer now depends on the
  specific library it uses. With that split, the `ppx_module_timer` *ppx* package
  is pulled in only by things that actually want instrumentation — so this
  `depopts` genuinely gates whether module timing is incorporated.
- Verified in-workspace: with the library available, `select` picks the enabled
  branch and a module preprocessed with `ppx_jane` still contains the injected
  `Ppx_module_timer_runtime.record_start` / `record_until` calls.
