# base

- `src/set.ml`: moved `[@alloc a]` from inside the `with type` constraint to the outer
  `Ptyp_package` core type in the `sexp_of_m__t` template, i.e.
  `((module Elt) : (module Sexp_of_m with type t = elt)[@alloc a])`.
  Previously `(module Elt : Sexp_of_m with type t = elt[@alloc a])` placed the
  attribute on the constraint type `elt`, which ppx_template cannot see when visiting
  the `Ptyp_package` node, so `Sexp_of_m` was never mangled to `Sexp_of_m__stack`
  and the generated `sexp_of_t__stack` function referred to the non-existent
  `Elt.sexp_of_t__stack`.

- `src/map.ml`: same fix as `set.ml` — moved `[@alloc a]` to the outer `Ptyp_package`
  for the `sexp_of_m__t` template (module `K` instead of `Elt`).
