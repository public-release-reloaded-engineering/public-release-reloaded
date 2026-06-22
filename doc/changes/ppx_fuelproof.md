# ppx_fuelproof

- `src/ppx_fuelproof.ml` line 348: renamed `~loc` to `~loc:_` in
  `rewrite_tydecls`.  The `loc` parameter is accepted for API symmetry but the
  function body delegates entirely to sub-functions that receive `loc` via other
  means; OCaml 5.x strict warning 27 promotes unused labeled parameters to errors.
