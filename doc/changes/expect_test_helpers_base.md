# expect_test_helpers_base

- `src/expect_test_helpers_base.ml` lines 382 and 411: moved `[@mode m]` from
  the `type t = a[@mode m]` constraint inside the `Ptyp_package` to the outer
  `Ptyp_package` node:
  `(module M : With_equal with type t = a[@mode m])`
  → `((module M) : (module With_equal with type t = a)[@mode m])`.
  When `[@mode m]` is inside the `with type` constraint, ppx_template's
  `visit_mono Core_type` cannot see it on the `Ptyp_package` and so never
  mangles `With_equal` → `With_equal__local`; the generated code then calls
  `M.equal__local` on a module that only provides `M.equal`.
