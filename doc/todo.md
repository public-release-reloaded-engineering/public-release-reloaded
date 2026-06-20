# TODO

## ppxlib version compatibility

`ppxlib_jane` (workspace source) requires `ppxlib >= 0.33.0 & < 0.36.0`.
However, all ppxlib versions < 0.36 also require `ocaml < 5.4.0`, making them
unbuildable on our OCaml 5.5.0 switch.

We are vendoring ppxlib 0.38.0 in `vendor/ppxlib/` (the only version that
builds on OCaml 5.5).  This means the `ppxlib_jane` opam constraint is
violated and there are likely API incompatibilities between ppxlib 0.38 and
what `ppxlib_jane` and the `ppx_*` workspace packages expect.

To resolve:

1. Update the `"ppxlib" {>= "0.33.0" & < "0.36.0"}` constraint in
   `ppxlib_jane/ppxlib_jane.opam` (and similar constraints in other ppx_*
   packages) to accept 0.38+.
2. Fix any ppxlib 0.38 API incompatibilities in `ppxlib_jane` and dependent
   packages (expect changes around `Ppxlib.Ast_helper`, `Ppxlib.Ast_pattern`,
   context-free rules, and driver registration).
3. Once clean, remove or update `vendor/ppxlib/`.
