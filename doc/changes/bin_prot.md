# bin_prot

- `src/dune`: added `(flags (:standard -w -32))` to suppress warning 32
  (unused value declaration) for `unbox_int32`, `unbox_int64`, `unbox_nativeint`
  in `read.ml`.  These values are defined for C-stub interop but are not referenced
  from OCaml code visible to the compiler; OCaml 5.x promotes warning 32 to an error.
