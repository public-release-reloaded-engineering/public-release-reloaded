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
  and `ppx_module_timer.helpers` libraries, which several packages (`core`,
  `bonsai`, `ppx_css`, `bin_prot`, …) depend on directly. Those dependencies are
  unaffected; in a full release install the package is present anyway, so
  `ppx_jane` still incorporates timing there. The `depopts` only matters for a
  minimal install that pulls in `ppx_jane` without any of those packages.
- Verified in-workspace: with the library available, `select` picks the enabled
  branch and a module preprocessed with `ppx_jane` still contains the injected
  `Ppx_module_timer_runtime.record_start` / `record_until` calls.
