# netsnmp

- `src/raw/dune`: added `(flags (:standard -w -69))` to suppress warning 69
  (unused record fields) in `oid.ml` and `session.ml`.  The raw SNMP bindings
  declare record fields that mirror C structs and are populated for mutation
  or forwarding to C code; the compiler cannot see these uses, so OCaml 5.x
  promotes the warning to an error.
