# CLAUDE.md — guidance for LLM agents

## Build command

```sh
TMPDIR=$PWD/.dune-tmp \
  opam exec --switch=$PWD \
  -- dune build --root=. @install 2>&1
```

**Always pass `--root=.`** to dune — without it dune warns about home-directory
permissions and the output becomes noisy.  The `TMPDIR` override is required
because `/tmp` is restricted in the sandbox (`nono`): the sandbox only grants
write access to `/tmp`, not read, so shell heredocs and other temp-file
operations that open their own temp files will fail.

## Git commit messages

Do **not** use shell heredocs (`<<'EOF'`) for `git commit -m` — the shell
writes the heredoc to a temp file in `/tmp`, which the sandbox cannot read.
Instead write the commit message to a file in an allowed path first:

```sh
printf 'subject line\n\nbody\n' > .dune-tmp/commit_msg.txt
git commit -F .dune-tmp/commit_msg.txt
```

## Repository structure

This is a **nested submodule** repository:

```
public-release-reloaded/          ← main repo (this one)
  releases/                       ← submodule (releases repo)
    abstract_algebra/             ← sub-submodule
    async/
    ...                           ← ~310 Jane Street packages
  vendor/                         ← submodule (vendor repo)
    cohttp/                       ← sub-submodule
    ppxlib/
    ...                           ← 13 third-party packages
    opam-repository/              ← sub-submodule: published vendor packages
  opam-repository/                ← submodule: opam repo generated from releases/
  dependencies/                   ← submodule
    github/                       ← ocaml-github async-port branch
  reloaded-tools/                 ← submodule
```

### Branch conventions

The workspace is currently assembled at release `v0.18~preview.130.106+341`
(`~` becomes `_` in branch names, since `~` is reserved in git revision syntax):

- `releases/` repo itself: branch `v0.18_preview.130.106+341`
- `releases/` sub-submodules: branch `v0.18_preview.130.106+341+reloaded`,
  **or** `v0.18_preview.130.100+614+reloaded` — see "carry-forward" below
- `vendor/` sub-submodules: branch `v0.18_preview.130.100+614+reloaded-compat`
  (except `vendor/ppxlib`, now on `0.38.0+reloaded` — a package-versioned
  branch tracking 0.38.0 + the post-release exponential-blowup fix; and the
  packages pinned to an upstream tag/branch of their own, e.g.
  `vendor/js_of_ocaml` on `5.5`)
- `vendor/` repo: branch `master`
- Main repo: branch `main`

#### Carry-forward: a package without a new release stays on the old branch

Jane Street does not re-cut every package at every release.  A package belongs
to a release only if one of its commits carries that version string as its
message (this is what `list_releases list` records in `releases.sexp`).  When a
package has **no** commit stamped with the new version, there is nothing to
import — so it stays at the commit and on the branch of the **previous** release
it does appear in.  The release version therefore names the *workspace* as a
whole, not every branch in it.

Concretely, at `130.106+341`: of the 310 package submodules, **135 are on
`v0.18_preview.130.106+341+reloaded`** (re-cut upstream, re-ported) and **177 are
on `v0.18_preview.130.100+614+reloaded`** (not re-cut; left where they were).
`ocaml_intrinsics_kernel` is one of the latter — it carries a `130.100+614` stamp
and no `130.106+341` stamp, so changes to it are committed on its
`…100+614+reloaded` branch even though `releases/` is on `…106+341`.

Two practical consequences:

- **Never assume a sub-submodule's branch from the release name.** Read it:
  `git -C releases/<pkg> rev-parse --abbrev-ref HEAD`.  Commit on whatever
  branch is checked out rather than switching to the "current" release branch;
  creating a `…106+341+reloaded` branch for a package that was never re-cut at
  `106` would invent a release that does not exist upstream.
- A mixed set of branches across `releases/*` is the expected steady state, not
  a sign of an unfinished update.

See `doc/update-to-v0.18-preview.130.106+341.md` §0 for how the changed /
new / unchanged split was measured, and §0c for the 13 packages that were
*deliberately* left at `614` despite having been re-cut (OxCaml-only, excluded
from the build anyway).

When committing changes to subrepos, commit the subrepo first, then commit the
parent repo to update the submodule pointer.

## opam switch

A local opam switch is at `_opam/` (not committed, listed in `.gitignore`).
It is based on `ocaml-variants.5.5.0+options` with `ocaml-option-flambda`.
`bwrap` is disabled globally via `wrap-build-commands: []` in the opam config
(required by nono — user namespaces are unavailable inside the sandbox).

Always use `opam exec --switch=$PWD -- ...` to run commands in this switch.

## Dune workspace

`dune-workspace` at the repo root causes dune to treat the whole tree as a
single workspace.  Dune auto-discovers sub-projects by finding `dune-project`
files.  The workspace currently covers `releases/`, `vendor/`,
`reloaded-tools/`, and `dependencies/`.

The `releases/dune` file (top-level inside `releases/`) has an `(dirs ...)`
stanza that excludes a small set of packages that cannot be built (missing
deps or JST-fork-only).

## Key compatibility changes

All changes are documented in `doc/changes/` and `doc/changes-third-party/`.
The most important ones:

### `effect` keyword (OCaml 5.3+)
`effect` is a reserved keyword in OCaml 5.3+.  The bonsai ecosystem used it
as a variable name.  Bulk rename: `sed -i 's/\beffect\b/effect_/g'` on all
`.ml`/`.mli` files.

### `local_` / `@ local` annotations
JST-only syntax.  Removed by bulk sed: `s/ local_//g` and `s/ @ local//g`.
Must **not** be applied to `vendor/ppxlib/` or `vendor/js_of_ocaml/` (they
have their own handling).

### `include functor` (JST-only)
Replace with explicit `include F(struct type nonrec t = t [@@deriving ...] end)`.

### `Bigstring_unix` split
In core v0.17+, `Bigstring.read` and `Bigstring.read_assume_fd_is_nonblocking`
moved to `Bigstring_unix` (in the `core_unix` package).  Any code that calls
these via `Bigstring.*` needs updating and must add `core_unix` to its dune
`(libraries ...)` stanza.

### Cohttp 6 API
- `respond_with_file` and `respond_string` no longer accept `?flush`
- `Cohttp_async.Io` is now a container module; use `Cohttp_async.Io.IO` as a
  functor argument
- `IO.ic` is `Cohttp_async__Input_channel.t`, not `Async_unix.Reader.t`

### js_of_ocaml API
- `##.clipboardData` and `##.dataTransfer` return `Js.opt` — wrap with
  `Js.Opt.to_option` or `Js.Opt.iter`
- `composedPath()` elements are `Js.Unsafe.any` — use `Js.Unsafe.get element
  "propertyName"` instead of `element##.propertyName`
- `element##.dataset` on a coerced `Dom_html.element Js.t` works; on
  `Js.Unsafe.any` it does not — coerce first

### C stubs that a runtime may also define → `CAMLweakdef`

Several packages ship C stubs that exist only to satisfy the linker: the OCaml
`external` is marked `[@@builtin]`, so the symbol is never actually called, and
the body is `assert(…); abort();`.  If a runtime defines a real version of the
same symbol, a *strong* placeholder collides with it at link time.

Such placeholders must therefore be `CAMLweakdef`.  The OxCaml runtime has long
defined some of them, and **OCaml 5.6 defines `caml_int_clz`**, so this now bites
the upstream compiler too.  Applied in `releases/ocaml_intrinsics_kernel/src/runtime.c`
(see `doc/changes/ocaml_intrinsics_kernel.md`); `releases/ocaml_simd/sse/sse_stubs.c`
already had it.

Only unreachable placeholders get this treatment — a weak binding on a stub that
is a *real* implementation (e.g. `caml_csel_*`) would let a runtime silently
replace working code.

## sexplib0 two-provider problem

The workspace builds `sexplib0` from source.  Any opam-installed package that
was compiled against the opam `sexplib0` creates a conflict.  Resolution:
- `ppxlib` and `ppx_yojson_conv_lib` are **not** installed in the opam switch
  (vendored in `vendor/` instead)
- `basement` and `sexp_type` are pinned to workspace source

If you add a new opam dependency that transitively requires `sexplib0`, check
whether it creates a two-provider conflict before installing.

## Tools

Build with:
```sh
TMPDIR=$PWD/.dune-tmp opam exec --switch=$PWD -- dune build --root=. reloaded-tools/list_releases.exe
```

Binary is at `_build/default/reloaded-tools/list_releases.exe`.

Subcommands:
- `list` — fetch Jane Street org repos via GitHub API, record release versions
- `clone` — clone repos for a specific release version
- `fork fork` — fork all `releases/` and/or `vendor/` subrepos into
  `public-release-reloaded` / `public-release-reloaded-vendored` (idempotent)
- `fork set-remote` — update git remotes to point at the forks
- `constrain-deps` — rewrite `releases/*.opam` so that every dependency on
  another `releases/` package is constrained to the major line
  (`{>= "v0.18~" & < "v0.19~"}`); uses `opam-file-format` and preserves the
  layout of all other fields.  Idempotent; `-dry-run` previews.  The `~` bounds
  are deliberate — opam sorts `v0.18~preview…` *below* `v0.18`, so a plain
  `>= "v0.18"` would exclude our own packages.

The `fork` commands accept `-kind releases|vendor|both`, `-workspace DIR`,
`-dry-run`, and `-releases-org` / `-vendor-org` overrides.

## Open items

See `doc/todo.md` for:
1. **`ppxlib_jane` compatibility** — `ppxlib_jane` constrains ppxlib to
   `>= 0.33 & < 0.36` but we vendor 0.38; API incompatibilities need fixing
