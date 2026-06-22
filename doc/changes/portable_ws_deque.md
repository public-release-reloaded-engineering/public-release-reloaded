# portable_ws_deque

- `src/dune`: added `(flags (:standard -w -69))` to suppress warning 69
  (unused record fields) for `portended`, `top`, `bottom`, `top_cache`, `tab`
  in `portable_ws_deque.ml`.  These fields are declared for the work-stealing
  deque data structure but are not read through paths visible to the compiler;
  OCaml 5.x promotes warning 69 to an error.
