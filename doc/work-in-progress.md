# Work in Progress

## Goal

Build all Jane Street public release repos (v0.18~preview.130.100+614) in a
single dune workspace on OCaml 5.5.0+flambda, producing installable artifacts
via `dune build @install`.

**Status: COMPLETE** — `dune build @install` exits 0 as of 2026-06-22.

---

## Build command

```
TMPDIR=/path/to/repo/.dune-tmp \
  opam exec --switch=/path/to/repo \
  -- dune build --root=. @install 2>&1
```

The `TMPDIR` override keeps dune's temporary files out of `/tmp` (required by
the sandbox environment).  `--root=.` suppresses the home-directory permission
warning.

---

## Completed

### Infrastructure

- **Local opam switch** created at `_opam/` based on `ocaml-variants.5.5.0+options`
  with `ocaml-option-flambda`. bwrap disabled via global `wrap-build-commands: []`
  (required by nono sandbox — user namespaces unavailable inside nono).
- **`.gitignore`** updated to exclude `_opam/`.
- **`dune-workspace`** at repo root, covering both `releases/` and `vendor/`.
- **`vendor/` git repo** with external packages as submodules (see `doc/structure.md`).

### Conflict resolution: sexplib0 two-provider problem

The workspace builds `sexplib0` from source; any opam package compiled against
the opam-installed `sexplib0` creates a two-provider conflict in dune.

Resolution:
- Pinned `basement` and `sexp_type` to workspace source.
- Uninstalled `ppxlib` and `ppx_yojson_conv_lib` from opam.
- Vendored `ppxlib 0.38.0` in `vendor/ppxlib/`.
- Vendored third-party ppxlib-dependent packages:
  `sedlex`, `gen_js_api`, `angstrom`, `cohttp`, `conduit`, `lsp`,
  `promise_jsoo`, `js_of_ocaml` (smuenzel/js_of_ocaml branch 5.5), `httpaf`.
- Kept `uri` at 3.1.0 (uri ≥ 4.0 pulls in angstrom).

### Source-level fixes

All source changes are documented in `doc/changes/`.  Summary by category:

- **OCaml 5.5 compatibility** (`doc/changes/ocaml55-compat.md`):
  - `effect` keyword: bulk rename to `effect_` across bonsai ecosystem
  - `local_` / `@ local` removal: bulk sed across all packages
  - `include functor`: replaced in 3 `bonsai_term_components` files
  - `stack` → `stack_local` in ppx_template annotations
  - `[@@@warning "-incompatible-with-upstream"]` removed from `core/validate`
  - 40+ dune files with warning/alert flag suppressions
  - 8 packages excluded (JST-fork-only or missing deps)

- **js_of_ocaml API** (`doc/changes/jsoo-api.md`):
  - `clipboardData` / `dataTransfer` now return `Js.opt`
  - `composedPath` elements typed as `Js.Unsafe.any`

- **Cohttp 6 API** (`doc/changes/cohttp6.md`):
  - `?flush` removed from `respond_with_file` / `respond_string`
  - `Cohttp_async.Io` restructured: use `Cohttp_async.Io.IO` as functor arg
  - `IO.ic` is `Input_channel.t`, not `Reader.t`

- **Per-package** (individual files in `doc/changes/`):
  - `async_js`: GADT match with open object type
  - `bigdecimal`: `Zarith_version` alias removed
  - `bonsai` ecosystem: see `doc/changes/bonsai.md`
  - `core`: `gc_stubs.c` for OCaml 5.5, `validate` JST warning attribute
  - `hardcaml_c` / `hardcaml_verilator`: `Ctypes_foreign_threaded_stubs` alias
  - `lsp_rpc`: `CustomNotification` constructor removed from LSP library

- **Third-party vendor changes** (files in `doc/changes-third-party/`):
  - `httpaf`: `Bigstring_unix` split, `core_unix` dep, `Ivar.fill` alert
  - `cohttp`: disabled eio and mirage backends (deps unavailable)
  - `conduit`: disabled mirage backend
  - `lsp`: disabled `ocamllsp` and lev-fiber (depend on dune internal `stdune`)
  - `ppxlib`: bug fix in `migrate_504_503.ml`; version field in `.opam` files

---

## Open items / future work

See `doc/todo.md` for:
- `notty-community`: investigation needed (may alias public `notty`)
- `ppxlib 0.38` compatibility with `ppxlib_jane` and `ppx_*` packages
