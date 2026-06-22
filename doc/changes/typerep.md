# typerep

- `lib/dune`: added `(flags (:standard -w -69))` to suppress warning 69
  (unused record fields) for fields `a`, `b`, `c`, `d` in `typerep_obj.ml`.
  These fields are used for low-level `Obj` manipulation and are accessed via
  unsafe casts rather than normal field projections, so the compiler cannot see
  the reads; OCaml 5.x promotes warning 69 to an error.
