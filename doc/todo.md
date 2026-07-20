# TODO

## Update opam version constraints

The workspace targets **OCaml 5.5.0** (`ocaml-variants.5.5.0+options` with
`ocaml-option-flambda`).  Before these packages can be published or used as a
proper opam repository, all opam files need updated version constraints:

1. **Compiler lower bound**: add `"ocaml" {>= "5.5.0"}` (or
   `"ocaml-variants" {>= "5.5.0+options"}`) to every `.opam` file that does not
   already have it.  The current upstream releases ship constraints like
   `{>= "5.1"}` which are too loose.

2. **Third-party dependency lower bounds**: for each package in `vendor/`
   (cohttp, conduit, ppxlib, httpaf, lsp, js_of_ocaml, …) and `dependencies/`
   (github), pin the lower bound in opam files to the version actually vendored
   here.  This ensures any consumer of these opam files cannot accidentally
   resolve an older incompatible version.

Note: **labeled tuples** (`type t = label:string * other:int`) are supported
natively in OCaml 5.5 and do **not** need to be removed when porting JST
packages.  Only the following JST-only syntax still requires removal:
- `local_` / `@ local` / `(local_ …)` annotations
- `include functor` syntax
- `effect` as a variable/value name (reserved keyword since OCaml 5.3)
- `[::] ` empty-list patterns
- JST-specific ppx attributes not available in upstream ppxlib

## ppxlib version compatibility

`ppxlib_jane` (workspace source) requires `ppxlib >= 0.33.0 & < 0.36.0`.
However, all ppxlib versions < 0.36 also require `ocaml < 5.4.0`, making them
unbuildable on our OCaml 5.5.0 switch.

We are vendoring ppxlib 0.38.0 in `vendor/ppxlib/` (the only version that
builds on OCaml 5.5).  This means the `ppxlib_jane` opam constraint is
violated and there are likely API incompatibilities between ppxlib 0.38 and
what `ppxlib_jane` and the `ppx_*` workspace packages expect.

To resolve:

1. ~~Update the `"ppxlib" {>= "0.33.0" & < "0.36.0"}` constraint in
   `ppxlib_jane/ppxlib_jane.opam` (and similar constraints in other ppx_*
   packages) to accept 0.38+.~~ **Done** — the 73 `releases/*.opam` files that
   still carried `{>= "0.33.0" & < "0.36.0"}` were bumped to `{>= "0.38.0"}`,
   matching the packages already using that bound (`ppx_here`, `ppx_tydi`,
   `ppxlib_jane`, …). This is opam metadata only and does not affect the dune
   build. (`vendor/` lower bounds — `js_of_ocaml` `>= 0.33`, `gen_js_api`
   `>= 0.37`, `ppx_deriving` `>= 0.36`, `sedlex` `>= 0.26` — are all already
   satisfied by 0.38 and left untouched.)
2. Fix any ppxlib 0.38 API incompatibilities in `ppxlib_jane` and dependent
   packages (expect changes around `Ppxlib.Ast_helper`, `Ppxlib.Ast_pattern`,
   context-free rules, and driver registration).
3. Once clean, remove or update `vendor/ppxlib/`.
