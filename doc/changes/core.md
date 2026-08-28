# core

- `base_for_tests/src/dune`: added `(flags (:standard -w -67))` to suppress
  warning 67 (unused functor parameter) in `test_binary_searchable_intf.ml` and
  `test_blit_intf.ml`.  These interface files define functor signatures whose
  parameter modules are unused in the body (the functor is applied for its type
  constraints only); OCaml 5.x promotes warning 67 to an error.

- `core/src/gc_stubs.c`: fixed `core_gc_run_memprof_callbacks` for OCaml 5.5+.
  `caml_memprof_run_callbacks_res()` changed its return type from `value` to
  `caml_result` (a struct) in OCaml 5.5.0, so the old code `value res = ...`
  failed with an incompatible-types error.  Replaced with
  `caml_get_value_or_raise(caml_memprof_run_callbacks_res())`, which is the
  idiomatic API for handling `caml_result` and re-raising any exception.

- `validate/src/validate.ml` and `validate/src/validate.mli`: removed
  `[@@@warning "-incompatible-with-upstream"]` attribute.  This is a
  Jane-Street-fork-only named warning that standard OCaml 5.5 rejects with
  `Error: Uninterpreted extension "warning"` (or similar).  The attribute was
  used as a file-level marker and had no functional effect on the build.

- `core/src/comparator_intf.ml` and `core/src/comparator.ml`: repeated
  `Base.Comparator.t`'s `private` record manifest

  ```ocaml
  type ('a, 'witness) t = ('a, 'witness) Base.Comparator.t = private
    { compare : 'a -> 'a -> int
    ; sexp_of_t : 'a -> Base.Sexp.t
    }
  ```

  Mechanical follow-through to base re-exposing `Comparator.t` as a private record
  (see `doc/changes/base.md`).  Both files re-export base via
  `include module type of Base.Comparator with type t := t`, and OCaml forbids
  destructive substitution (`:=`) on a type whose declaration is a bare
  record/variant — so the substituted type needs a manifest.  This does not widen
  core's API: `Core.Comparator.t` already equalled `Base.Comparator.t`.
