# parsexp

- `src/dune`: added `(flags (:standard -w -67))` to suppress warning 67
  (unused functor parameter) in `conv_intf.ml`.  `Sexp_parser` and
  `Positions_parser` are functor parameters used only for their type constraints,
  not their values; OCaml 5.x promotes warning 67 to an error.
