# opam package metadata

## Package version

All packages in this repository are published under the version
`v0.18_preview.130.100+614+reloaded`.

This follows the same `v0.18*` prefix used by upstream Jane Street opam
packages (e.g. `core.v0.18`, `base.v0.18.1`) so version ordering is
consistent.  The `+reloaded` build-metadata suffix makes these packages
distinct from any upstream version and prevents opam from treating them as
interchangeable — a consumer cannot accidentally satisfy a dependency on
`core.v0.18_preview.130.100+614+reloaded` with the upstream `core.v0.18`.

The version is derived from the sub-submodule branch name
`v0.18_preview.130.100+614+reloaded` (the `+reloaded` suffix is appended to
the Jane Street release branch name `v0.18_preview.130.100+614`).

### opam-repository

The `opam-repository/` directory is a standard opam repository.  Run

```sh
scripts/populate-opam-repo.sh
```

to (re-)populate `opam-repository/packages/` from the current state of
`releases/`.  The script is idempotent.  Each `.opam` file from `releases/`
is placed at

```
opam-repository/packages/PKGNAME/PKGNAME.VERSION/opam
```

with a `version: "VERSION"` line prepended (the source files omit this field
because dune derives it from the git tag at build time) and a `url` block
appended so that `opam install` can fetch the source:

```
url {
  src: "git+https://github.com/public-release-reloaded/PKGNAME.git#v0.18_preview.130.100+614+reloaded"
}
```

The `src:` URL is extracted from each package's `dev-repo:` field; no separate
checksum is required for git sources.  Tarball-based sources would require
publishing a GitHub release and computing checksums — git sources work without
that step.

To use the repository locally:

```sh
opam repo add reloaded /path/to/opam-repository --rank=1
opam install base  # will find base.v0.18_preview.130.100+614+reloaded
```

---

## Version constraints

All `.opam` files in `releases/` have been updated to reflect the actual
versions required by this workspace.

### OCaml compiler

Every package requires `"ocaml" {>= "5.5.0"}`.  The workspace is built with
`ocaml-variants.5.5.0+options` + `ocaml-option-flambda`; nothing in the tree
builds with an older compiler.

### Vendored third-party packages

These packages live in `vendor/` and their lower bounds in `releases/` opam
files have been pinned to the vendored version:

| opam package | vendored version | constraint used |
|---|---|---|
| `ppxlib` | 0.38.0 | `{>= "0.38.0"}` |
| `cohttp` / `cohttp-*` | 6.2.1 | `{>= "6.2.1"}` |
| `js_of_ocaml` / `js_of_ocaml-ppx` | dev (post-6.3.2) | `{>= "6.3.0"}` |
| `lsp` / `jsonrpc` | dev (post-1.25.0) | `{>= "1.25.0"}` |
| `angstrom` | 0.16.1 | `{>= "0.16.1"}` |
| `faraday` | 0.8.2 | `{>= "0.8.2"}` |
| `gen_js_api` | 1.1.7 | `{>= "1.1.7"}` |
| `sedlex` | 3.7 | `{>= "3.7"}` |
| `uri` / `uri-re` | 4.4.0 | `{>= "4.4.0"}` |
| `httpaf` | 0.7.1 | `{>= "0.7.1"}` (unchanged) |
| `promise_jsoo` | 0.4.3 | `{= "0.4.3"}` (unchanged) |
| `conduit` / `conduit-async` | 8.0.0 | (no constraint in releases) |
| `ipaddr` | 5.6.2 | (no constraint in releases) |

### JST-internal `+ox` version pins removed

The upstream Jane Street sources used internal opam package variants suffixed
with `+ox` (Jane Street's internal OCaml fork tag).  These do not exist in the
public opam repository.  All such pins have been replaced with standard
upstream constraints:

| Original constraint | Replacement |
|---|---|
| `"ppxlib" {= "0.33.0+ox"}` | `"ppxlib" {>= "0.38.0"}` |
| `"js_of_ocaml" {= "6.0.1+ox"}` | `"js_of_ocaml" {>= "6.3.0"}` |
| `"js_of_ocaml-ppx" {= "6.0.1+ox"}` | `"js_of_ocaml-ppx" {>= "6.3.0"}` |
| `"gen_js_api" {= "1.1.2+ox"}` | `"gen_js_api" {>= "1.1.7"}` |
| `"notty-community" {= "0.2.4+ox"}` | `"notty-community" {>= "0.2.4"}` |
| `"ocaml-compiler-libs" {= "v0.17.0+ox"}` | `"ocaml-compiler-libs" {>= "v0.17.0"}` |
| `"omd" {= "2.0.0~alpha4+ox"}` | `"omd" {>= "2.0.0~alpha4"}` |
| `"re" {= "1.14.0+ox"}` | `"re" {>= "1.14.0"}` |
| `"uutf" {= "1.0.4+ox"}` | `"uutf" {>= "1.0.4"}` |

### `ppxlib` upper bound removed

The upstream sources constrained ppxlib to `{>= "0.33.0" & < "0.36.0"}` —
this reflected the version available in Jane Street's internal opam repository.
We vendor ppxlib 0.38.0, so the upper bound was wrong and has been removed.
The constraint is now `{>= "0.38.0"}` throughout.

## opam switch

A local opam switch at `_opam/` (not committed) provides the non-vendored
dependencies.  It is based on `ocaml-variants.5.5.0+options` with
`ocaml-option-flambda`.  `bwrap` is disabled globally
(`wrap-build-commands: []`) because user namespaces are unavailable in the
build sandbox.

Key installed packages that are **not** vendored:

| Package | Installed version |
|---|---|
| `re` | 1.14.0 |
| `uutf` | 1.0.4 |
| `omd` | 2.0.0~alpha4 |
| `ocaml-compiler-libs` | v0.17.0 |
| `notty-community` | 0.2.4 |

See `CLAUDE.md` for the `opam exec` invocation pattern and the sexplib0
two-provider problem.
