# Repository Structure

## Top-level layout

```
public-release-reloaded/
├── doc/                   # Documentation (this folder)
├── dune-workspace         # Workspace root covering releases/ and vendor/
├── releases/              # Subrepo: one branch per release version
│   └── <repo>/            # Each Jane Street source repo as a submodule
├── reloaded-tools/        # Subrepo: utilities for working with the release
│   ├── list_releases.ml   # Main tool source
│   ├── dune
│   └── dune-project
├── vendor/                # Subrepo: vendored third-party packages
│   ├── ppxlib/            # ppxlib (built from source to avoid sexplib0 conflict)
│   ├── sedlex/            # depends on ppxlib
│   ├── js_of_ocaml/       # depends on ppxlib (smuenzel fork, branch 5.5)
│   ├── gen_js_api/        # depends on ppxlib
│   ├── angstrom/          # provides angstrom-async
│   ├── cohttp/            # provides cohttp-async
│   ├── conduit/           # provides conduit-async
│   ├── lsp/               # depends on workspace ppx_yojson_conv_lib
│   ├── promise_jsoo/      # depends on js_of_ocaml
│   └── opam-repository/   # published vendor packages (e.g. patched ppxlib)
├── opam-repository/       # opam repo generated from releases/ (see doc/opam.md)
└── releases.sexp          # Version→repos mapping produced by `list`
```

There are two opam repositories: the top-level `opam-repository/` is generated
from `releases/` by `scripts/populate-opam-repo.sh`, while
`vendor/opam-repository/` hosts hand-published vendored packages.  Both are
documented in `doc/opam.md`.

## `releases/` subrepo

Each release version is a separate branch in this subrepo.  Branch names
are the version strings with `~` replaced by `_`, since `~` is reserved in
git revision syntax.

| Branch name                    | Release version                  |
|-------------------------------|----------------------------------|
| `v0.18_preview.130.100+614`   | `v0.18~preview.130.100+614`      |

Every branch contains all source repos that belong to that version as git
submodules, pointing at the corresponding commits on GitHub.  Not every repo
appears in every release.

## `reloaded-tools/` subrepo

An OCaml command-line tool with two subcommands:

- **`list`** — queries the GitHub API for every repo in the `janestreet`
  organisation, scans recent commits for version-string messages, and writes
  a `releases.sexp` file mapping each version to the repos it contains.

- **`clone`** — reads `releases.sexp`, looks up a requested version, and
  clones all its repos into a local directory.

Build with:

```
TMPDIR=/tmp/claude-1000 dune build
GITHUB_TOKEN=<token> dune exec ./list_releases.exe -- list -output releases.sexp
```

## `vendor/` subrepo

Contains third-party packages that must be built from source alongside the
Jane Street releases rather than installed via opam.  The primary reason for
vendoring is that the Jane Street workspace builds `sexplib0` from source, but
the opam-installed `ppxlib` was compiled against the opam-installed `sexplib0`,
creating a two-provider conflict in dune.  Building ppxlib from source
eliminates this conflict since all packages then share a single `sexplib0`
compilation.

All ppxlib-dependent packages that also depend on workspace packages (async,
core, ppx_yojson_conv_lib, etc.) are vendored for the same reason: they must
build against the workspace versions of those libraries.

Each package inside `vendor/` is a git submodule pinned to a specific tag or
branch.  To add a new package:

```
git -C vendor/ submodule add <url> <name>
git -C vendor/<name> checkout <tag>
git -C vendor/ add <name>
git -C vendor/ commit -m "Add <name> at <version>"
```

Then register `vendor/` in the parent repo:
```
git add vendor
git commit -m "Update vendor submodule"
```

### Versioning a vendored package

Some vendored packages generate their `.opam` files from `dune-project`
(`generate_opam_files true`) — editing the `.opam` directly is overwritten on
the next `dune build`.  Set the version in `dune-project` instead, e.g.
`vendor/ppxlib/dune-project`:

```
(version 0.38.0+reloaded)
```

Use a `+reloaded` build-metadata suffix so the version sorts *above* the
upstream release it is based on (opam: `0.38.0` < `0.38.0+reloaded`), which lets
`releases/` depend on it with `{> "0.38.0"}`.

### Publishing a vendored package

To make a vendored package installable via opam, publish it into
`vendor/opam-repository/` (see `doc/opam.md` § "vendor opam-repository"):

```
vendor/opam-repository/packages/<pkg>/<pkg>.<version>/opam
```

The file is the source `.opam` plus a `url { src: "git+<fork-url>#<branch>" }`
block pointing at the fork/branch that carries the vendored changes — **not** at
`dev-repo:`, which for vendored packages usually still points upstream.

See `doc/todo.md` for known issues with vendored package versions (in
particular the ppxlib 0.38 / ppxlib_jane compatibility issue).

## `dune-workspace`

Sits at the repo root and covers both `releases/` and `vendor/`.  Build the
entire workspace from the repo root:

```
eval $(opam env --switch=/path/to/public-release-reloaded)
TMPDIR=/tmp/claude-1000 dune build @install
```

## `doc/` folder

Houses project-level documentation.  Source-code documentation lives inside
the individual subrepos.
