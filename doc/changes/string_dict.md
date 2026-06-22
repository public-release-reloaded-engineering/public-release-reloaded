# string_dict

- `src/dune`: added `(flags (:standard -w -69))` to suppress warning 69
  (unused record field).  OCaml 5.x promotes this warning to an error for record
  fields that are declared but never read by any code path the compiler can see.
