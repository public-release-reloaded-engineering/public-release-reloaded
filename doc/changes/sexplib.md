# sexplib

- `src/dune`: added `(flags (:standard -w -67))` to suppress warning 67
  (unused functor parameter) for `Make_pretty_printing (Helpers : Pretty_printing_helpers)`
  in `sexp_intf.ml`.  The `Helpers` parameter is used only for its type constraints,
  not its values; OCaml 5.x promotes warning 67 to an error.
