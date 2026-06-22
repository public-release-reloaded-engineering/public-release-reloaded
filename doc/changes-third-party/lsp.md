# lsp (vendor)

The lsp library is vendored in `vendor/lsp/`.

## Disabled: ocamllsp executable

`ocaml-lsp-server/bin/main` depends on `stdune`, which is an internal dune
library not available outside the dune source tree.

- `ocaml-lsp-server/bin/dune`: added `(enabled_if false)` to the executable
  stanza to prevent it from being built; added an empty stub library so the
  package has at least one user-defined stanza (required by dune).

## Disabled: lev-fiber and lev-fiber-csexp

These sub-libraries also depend on `stdune`.

- `submodules/lev/lev-fiber/src/dune`: added `(enabled_if false)`.
- `submodules/lev/lev-fiber-csexp/src/dune`: added `(enabled_if false)`.
