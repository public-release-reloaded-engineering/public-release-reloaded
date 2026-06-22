# shexp

- `process-lib/src/dune`: added `(flags (:standard -w -69))` to suppress warning 69
  (unused mutable record field).  OCaml 5.x promotes this warning to an error;
  the mutable fields exist for runtime mutation but are not written in every code
  path visible to the compiler's analysis.
