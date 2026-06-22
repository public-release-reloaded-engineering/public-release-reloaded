# public-release-reloaded

A workspace for building the Jane Street public release packages
(v0.18\~preview.130.100+614) on **OCaml 5.5.0+flambda**.

The upstream packages target Jane Street's internal OCaml fork.  This repo
contains the source-level patches and build infrastructure needed to compile
them with the standard OCaml 5.5 toolchain.

## Repository layout

| Path | Contents |
|------|----------|
| `releases/` | Sub-submodule for each of the ~310 Jane Street release packages |
| `vendor/` | Third-party packages vendored to resolve dependency conflicts |
| `dependencies/` | Build dependencies (currently: `ocaml-github` async port) |
| `reloaded-tools/` | CLI tools for managing this workspace |
| `doc/` | Documentation of all source changes and open items |
| `dune-workspace` | Dune workspace root; covers all subdirectories |
| `_opam/` | Local opam switch (OCaml 5.5.0+flambda, not committed) |

### Vendored third-party packages (`vendor/`)

`angstrom`, `cohttp`, `conduit`, `faraday`, `gen_js_api`, `httpaf`, `ipaddr`,
`js_of_ocaml`, `lsp`, `ppxlib`, `promise_jsoo`, `sedlex`, `uri`

These are vendored to avoid `sexplib0` two-provider conflicts with packages
that ship their own ppxlib-dependent ppx drivers.

## Building

```sh
TMPDIR=$PWD/.dune-tmp \
  opam exec --switch=$PWD \
  -- dune build --root=. @install 2>&1
```

The `TMPDIR` override is required in sandboxed environments where `/tmp` is
restricted.  `--root=.` suppresses a spurious home-directory permission
warning from dune.

## Source changes

All patches to upstream source are documented in `doc/changes/` (Jane Street
packages) and `doc/changes-third-party/` (vendored packages).  See
`doc/work-in-progress.md` for a full summary and `doc/todo.md` for open items.

The main categories of change:

- **`effect` keyword** — bulk rename `effect` → `effect_` across the bonsai
  ecosystem (OCaml 5.3+ reserved keyword)
- **`local_` / `@ local` removal** — JST-only mode annotations stripped by sed
- **`include functor` removal** — JST-only syntax replaced with explicit
  functor applications
- **Warning/alert suppressions** — ~40 dune files updated
- **js_of_ocaml API** — `clipboardData`, `dataTransfer`, `composedPath` type
  changes
- **Cohttp 6 API** — `?flush` removed, `Io` module restructured
- **`Bigstring_unix` split** — Unix I/O functions moved out of `Bigstring`
- **8 packages excluded** — JST-fork-only packages or missing dependencies

## Tools (`reloaded-tools/`)

```
list_releases.exe list          # find Jane Street release repos via GitHub API
list_releases.exe clone         # clone repos for a given release version
list_releases.exe fork fork     # fork all subrepos into GitHub orgs (idempotent)
list_releases.exe fork set-remote  # point subrepo remotes at the forks
```

The fork target organisations are `public-release-reloaded` (releases) and
`public-release-reloaded-vendored` (vendor).
