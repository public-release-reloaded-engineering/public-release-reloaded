# base_yojson

- `src/yojson0.ml`: removed `` `Tuple of t list `` and `` `Variant of string * t option ``
  from the `Alternate_sexp.t` polymorphic variant type.  Yojson 3.0.0 dropped these
  two constructors from `Yojson.Safe.t`, so the `constraint t = Yojson.Safe.t`
  declaration became a type error.  Since Yojson 3.0.0 never produces these values
  at runtime, removing them from the sexp representation is safe.

## `yojson` opam constraint excluded 3.x

Several packages carried the upstream constraint

```
"yojson" {>= "1.7.0" & < "3.0.0"}
```

which caps below `3.0.0` and therefore excludes the yojson 3.x series this
workspace uses (the code is ported to yojson 3.0.0, above).  This only matters
for opam resolution — the dune build ignores opam constraints and uses the
installed yojson 3.0.0 — but it makes an opam install of these packages
unsatisfiable (or resolve an incompatible pre-3 yojson).

**Fix:** dropped the `< "3.0.0"` upper bound, relaxing the constraint to
`{>= "1.7.0"}`, in:

- `base_yojson`
- `lsp_rpc`
- `ppx_yojson_conv_lib`
