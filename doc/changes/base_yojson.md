# base_yojson

- `src/yojson0.ml`: removed `` `Tuple of t list `` and `` `Variant of string * t option ``
  from the `Alternate_sexp.t` polymorphic variant type.  Yojson 3.0.0 dropped these
  two constructors from `Yojson.Safe.t`, so the `constraint t = Yojson.Safe.t`
  declaration became a type error.  Since Yojson 3.0.0 never produces these values
  at runtime, removing them from the sexp representation is safe.
