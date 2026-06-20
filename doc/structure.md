# Repository Structure

## Top-level layout

```
public-release-reloaded/
├── doc/                   # Documentation (this folder)
├── releases/              # Subrepo: one branch per release version
│   └── <repo>/            # Each Jane Street source repo as a submodule
├── reloaded-tools/        # Subrepo: utilities for working with the release
│   ├── list_releases.ml   # Main tool source
│   ├── dune
│   └── dune-project
└── releases.sexp          # Version→repos mapping produced by `list`
```

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

## `doc/` folder

Houses project-level documentation.  Source-code documentation lives inside
the individual subrepos.
