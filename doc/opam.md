# opam package metadata

## Package version

All packages in this repository are published under the version
`v0.18~preview.130.100+614+reloaded`.

This follows the same `v0.18*` prefix used by upstream Jane Street opam
packages (e.g. `core.v0.18`, `base.v0.18.1`) so version ordering is
consistent.  The `+reloaded` build-metadata suffix makes these packages
distinct from any upstream version and prevents opam from treating them as
interchangeable — a consumer cannot accidentally satisfy a dependency on
`core.v0.18~preview.130.100+614+reloaded` with the upstream `core.v0.18`.

The version is derived from the sub-submodule branch name
`v0.18_preview.130.100+614+reloaded` by converting `_` back to `~`.  The branch
name uses `_` because `~` is reserved in git refs; the opam version uses `~`,
matching upstream Jane Street's `v0.18~preview…` naming.  (The `+reloaded`
suffix is appended to the Jane Street release branch name
`v0.18_preview.130.100+614`.)  Note the two forms are **not**
interchangeable: the opam `version:` field and repository directory names use
`~`, while the `url`/`dev-repo` git reference keeps the `_` branch name.

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

where `VERSION` is the `~` form (e.g. `v0.18~preview.130.100+614+reloaded`),
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
opam install base  # will find base.v0.18~preview.130.100+614+reloaded
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
| `ppxlib` | 0.38.0+reloaded | `{> "0.38.0"}` (see below) |
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
| `"ppxlib" {= "0.33.0+ox"}` | `"ppxlib" {> "0.38.0"}` |
| `"js_of_ocaml" {= "6.0.1+ox"}` | `"js_of_ocaml" {>= "6.3.0"}` |
| `"js_of_ocaml-ppx" {= "6.0.1+ox"}` | `"js_of_ocaml-ppx" {>= "6.3.0"}` |
| `"gen_js_api" {= "1.1.2+ox"}` | `"gen_js_api" {>= "1.1.7"}` |
| `"notty-community" {= "0.2.4+ox"}` | `"notty-community" {>= "0.2.4"}` |
| `"ocaml-compiler-libs" {= "v0.17.0+ox"}` | `"ocaml-compiler-libs" {>= "v0.17.0"}` |
| `"omd" {= "2.0.0~alpha4+ox"}` | `"omd" {>= "2.0.0~alpha4"}` |
| `"re" {= "1.14.0+ox"}` | `"re" {>= "1.14.0"}` |
| `"uutf" {= "1.0.4+ox"}` | `"uutf" {>= "1.0.4"}` |

### `ppxlib` requires a post-0.38.0 patch (`{> "0.38.0"}`)

The upstream sources constrained ppxlib to `{>= "0.33.0" & < "0.36.0"}` —
this reflected the version available in Jane Street's internal opam repository.
We vendor ppxlib, so that upper bound was wrong and was removed.

The workspace additionally requires a ppxlib patch (fixing exponential
behaviour in `migrate_504_503` — upstream #644) that landed **after** the
0.38.0 release and is not in any released version.  The vendored ppxlib carries
this patch (it tracks ppxlib `0.38.0-26-g…`, i.e. 26 commits past 0.38.0).  Its
version is set to **`0.38.0+reloaded`** — declared via `(version 0.38.0+reloaded)`
in `vendor/ppxlib/dune-project`, from which dune generates the `version:` field
in all three `vendor/ppxlib/*.opam` files (`ppxlib-bench` / `ppxlib-tools`
track it via `{= version}`).  opam sorts `0.38.0` < `0.38.0+reloaded`, so the
dependency constraint throughout `releases/` is **`{> "0.38.0"}`**, which the
released `0.38.0` does not satisfy but `0.38.0+reloaded` (and any future release
> 0.38.0) does.

Note: because the dune workspace builds the vendored ppxlib from source, this
constraint only matters for opam-level resolution (i.e. installs from a
published repository).

### vendor opam-repository

Vendored packages are published in a **separate** opam repository at
`vendor/opam-repository/` (submodule
`public-release-reloaded-vendored/opam-repository`), kept apart from the
`releases/`-generated `opam-repository/` at the workspace root.

The patched ppxlib is published there:

```
vendor/opam-repository/packages/ppxlib/ppxlib.0.38.0+reloaded/opam
```

The file is the source `vendor/ppxlib/ppxlib.opam` with a `url` block appended:

```
url {
  src: "git+https://github.com/public-release-reloaded-vendored/ppxlib.git#0.38.0+reloaded"
}
```

The `src` points at the **fork** (`public-release-reloaded-vendored/ppxlib`) on
the `0.38.0+reloaded` branch — *not* at the package's `dev-repo:`, which still
points upstream (`ocaml-ppx/ppxlib`) and does not carry the patch.  Only
`ppxlib` itself is published (nothing in the workspace depends on the sibling
`ppxlib-tools` / `ppxlib-bench` packages).

### Inter-package (releases/) constraints

Every dependency in a `releases/` opam file that refers to *another* `releases/`
package is pinned to the v0.18 major line:

```
"async_kernel" {>= "v0.18~" & < "v0.19~"}
```

This is generated by `reloaded-tools`:

```sh
_build/default/reloaded-tools/list_releases.exe constrain-deps [-dry-run]
```

The tool discovers the set of `releases/` packages (the `*.opam` basenames),
then adds the constraint to any `depends:` entry naming one of them, leaving
third-party dependencies (`ocaml`, `dune`, `ppxlib`, …) alone.  It uses
`opam-file-format`'s format-preserving printer, so only the `depends:` field of
each file is rewritten.  It is idempotent.

The `~` in both bounds is deliberate.  In opam version ordering `~` sorts
*before* the release, so the actual published versions
(`v0.18~preview.130.100+614+reloaded`) compare **less than** `v0.18`.  A plain
`{>= "v0.18"}` would therefore exclude our own packages and make the repository
uninstallable.  `{>= "v0.18~"}` admits them (and any future `v0.18.x`), while
`{< "v0.19~"}` excludes the entire v0.19 line including its previews.

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
