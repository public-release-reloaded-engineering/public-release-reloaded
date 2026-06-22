# TODO

## notty-community: investigate relation to public notty

Several workspace packages (`bonsai_term`, `notty_async`, `hardcaml_waveterm`,
`strace_ui`, `bonsai_term_test`) depend on `notty-community` and
`notty-community.unix`.  These library names are not available on opam.

Hypothesis: `notty-community` may simply be the public `notty` library
re-packaged under a different name, possibly because Jane Street has an internal
variant (`notty-js`?) and wanted a stable name for the public/community version.

To investigate:
1. Check whether `notty-community` is just the public `notty` opam package under
   a different library name (compare module signatures).
2. If yes, create a thin shim in `vendor/` that re-exports `notty` as
   `notty-community` (a library with `(name notty_community)` that just includes
   `notty` modules).
3. If there are additions beyond plain notty, identify them and stub or
   implement them.

Until resolved: the affected packages have `(enabled_if false)` in their dune
files — see `doc/changes/` for the list.

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
