# ppx_conv_func

- `src/dune`: added `(flags (:standard -w -67))` to suppress warning 67
  (unused functor parameter).  OCaml 5.x promotes this warning to an error for
  functors whose parameter module is unused in the body; the existing code relies
  on the functor for its side-effecting registration, not the parameter's values.
