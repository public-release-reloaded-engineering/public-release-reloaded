# Updating to `v0.18~preview.130.106+341`

Scope study: what it would take to move this workspace from the current
release **`v0.18~preview.130.100+614`** to **`v0.18~preview.130.106+341`**.

This document is an analysis / plan, not a change log. It surveys the current
layout, explains the version scheme, and lays out the concrete steps, risks,
and open questions involved in a version bump.

---

## 1. Where we are today

| Layer | Branch / pin | Notes |
|-------|--------------|-------|
| Main repo (`public-release-reloaded`) | `main` | Workspace root, docs, tools |
| `releases/` submodule | `v0.18_preview.130.100+614` | One branch per release |
| `releases/<pkg>` sub-submodules (×310) | `v0.18_preview.130.100+614+reloaded` | Ported package forks |
| `vendor/` submodule | `master` | 14 third-party packages |
| `vendor/<pkg>` sub-submodules | `…+reloaded-compat` | e.g. ppxlib 0.38, cohttp 6 |
| `dependencies/github` | `async-port` | ocaml-github fork |
| `reloaded-tools/` | `master` | `list_releases.exe` |
| `opam-repository/` | tracked | pinned opam metadata |

Key facts established while surveying:

- **310 package submodules** are registered in `releases/.gitmodules`, each
  pointing at a fork under the `github.com/public-release-reloaded` org (not at
  `janestreet` directly). The forks carry the ported code on a
  `…+reloaded` branch.
- The `releases/` repo history shows the porting model clearly:

  ```
  80ef83d v0.18~preview.130.100+614: add all release repos as submodules   ← base import
  6973cf0 compat: OCaml 5.5.0+flambda / JS library updates
  f3b90b6 compat: OCaml 5.5 / upstream ppxlib compat
  3090ca0 compat: subrepo pointers (opam version constraints)
  4a5969e compat: subrepo pointers (URL / dev-repo branch updates)
  …
  ```

  i.e. **one clean import commit** of upstream, followed by a stack of
  `compat:` commits that advance the sub-submodule pointers as each package is
  ported. This is the shape any new-version import must reproduce.
- `dune build @install` currently exits 0 (see `doc/work-in-progress.md`).
- Every source change is documented under `doc/changes/` (47 files) and
  `doc/changes-third-party/` (5 files). This corpus is the *specification* of
  the port and is what makes a re-port tractable.

The `releases/` repo has **no git tags** and only the single
`v0.18_preview.130.100+614` branch on its remote. There is no
`130.106+341` branch anywhere yet — it does not exist in the forks, in the
`releases` repo, or in `releases.sexp`. Everything for the new version has to
be created.

---

## 2. Understanding the version scheme

Jane Street tags each public release with an opam-style version string that
appears as the **first line of a git commit message** in every repo belonging
to that release. The `list_releases` tool keys entirely off this convention
(`is_version_string`: `v` followed by a digit).

```
v0.18 ~ preview . 130 . 100 + 614
└─┬─┘   └──┬──┘   └┬┘   └┬┘   └┬┘
release  channel  series minor build
```

Going from `130.100+614` → `130.106+341`:

- Same major line (`v0.18`) and same `preview.130` series.
- Minor `.100` → `.106`: **6 upstream release drops** of churn to absorb.
- Build counter `+614` → `+341`: the counter *resets per minor*, so a smaller
  number does **not** mean older — `130.106` is strictly newer than `130.100`.

Practical consequence: this is not a rebase of one commit. It is 6 upstream
minor bumps of accumulated Jane Street changes across ~310 packages, on top of
which our ~50 documented compatibility patches must be re-applied.

Branch-naming convention (from `CLAUDE.md`) that the new version must follow —
`~` becomes `_` in branch names:

| Layer | New branch to create |
|-------|----------------------|
| `releases/` repo | `v0.18_preview.130.106+341` |
| `releases/<pkg>` forks | `v0.18_preview.130.106+341+reloaded` |
| `vendor/<pkg>` forks | `v0.18_preview.130.106+341+reloaded-compat` (if versioned) |

---

## 3. What "update" actually touches

Because of the nested-submodule design, a version bump is a bottom-up cascade:

```
for each package:  new upstream commit  →  re-apply compat  →  push +reloaded branch
        ↓
update releases/<pkg> submodule pointer  →  commit releases/ on new branch
        ↓
point releases submodule at new branch   →  commit main repo
        ↓
rebuild whole workspace, fix new breakage
```

Nothing about the update is "just bump a pointer" — the pointer moves are the
*last* step of each layer, gated on the port actually compiling.

---

## 4. Step-by-step plan

### Step 0 — Refresh the release manifest

The `list` subcommand crawls the `janestreet` org via the GitHub API and
records, for each version string, the set of repos carrying it:

```sh
TMPDIR=$PWD/.dune-tmp opam exec --switch=$PWD -- \
  dune build --root=. reloaded-tools/list_releases.exe
GITHUB_TOKEN=… _build/default/reloaded-tools/list_releases.exe \
  list -output releases.sexp
```

Caveat worth noting before relying on the result: `find_version_commits` only
walks **`max_commits = 30`** commits per repo. If a package has had more than
30 commits since it last shipped `130.106+341`, that version will be missed for
that package. For a 6-minor jump this limit is likely too low and should be
raised (or the crawl re-run) before trusting the package set.

### Step 1 — Determine the new package set (and the diff)

From the refreshed `releases.sexp`, extract the repo list for
`v0.18~preview.130.106+341` and diff it against the current set:

- **New packages** — present in `130.106+341` but not in `130.100+614`. These
  are net-new work: fork, import, port from scratch, add as submodules, add to
  the workspace. **This is the item the request specifically flags**, and it is
  the least predictable part of the estimate (see §5).
- **Removed packages** — present now, gone in the new release. Remove the
  submodule, drop any `doc/changes/*.md` that referenced it, and remove it from
  any exclusion lists.
- **Retained packages (the ~310)** — the bulk; each needs its pointer advanced
  to the new upstream commit and its compat patches re-applied.

### Step 2 — Fork any new upstream repos

`list_releases fork` is idempotent and already knows how to fork every repo in
a `.gitmodules` into the `public-release-reloaded` / `-vendored` orgs:

```sh
… list_releases.exe fork fork -kind both            # create forks
… list_releases.exe fork set-remote -kind both      # point origins at forks
… list_releases.exe fork set-default-branch -kind both
```

For genuinely new packages the `.gitmodules` has to gain their entries first
(or fork them directly), then re-run.

### Step 3 — Re-import upstream at the new version

For each package, bring the fork's `…+reloaded` branch up to the new upstream
commit. The base-import commit `80ef83d` is the template: import the pristine
`130.106+341` tree, then layer compat on top. Two viable strategies:

- **Re-port (recommended).** Start from pristine upstream `130.106+341` and
  replay the documented transforms. The bulk transforms are deterministic and
  scriptable straight from `doc/changes/ocaml55-compat.md`:
  - `effect` → `effect_` (bonsai ecosystem, listed dirs)
  - strip `local_` / `@ local` (all non-excluded packages; **not** ppxlib /
    js_of_ocaml)
  - `stack` → `stack_local` in ppx_template alloc-mode contexts
  - `include functor` rewrites (3 known files)
  - `[%call_pos]` → `Source_code_position.t`
  - remove `[@@@warning "-incompatible-with-upstream"]`
  - the 40+ dune warning/alert suppressions
  Then re-apply the targeted, per-package fixes.
- **Rebase.** Rebase the existing `…+reloaded` commits onto the new upstream.
  Faster when upstream barely moved a file, but conflict-prone across a 6-minor
  jump; the transforms are easier to re-run than to merge.

Either way, `doc/changes/` is the checklist. Each file names the exact files
and edits, so re-verification is mechanical even when line numbers drift.

### Step 4 — Advance pointers, bottom-up

1. Commit each ported package fork; push its `…+reloaded` branch.
2. In `releases/` (on a new `v0.18_preview.130.106+341` branch) advance every
   sub-submodule pointer and update `.gitmodules` branch fields.
3. In the main repo, point the `releases` submodule at the new branch (update
   `.gitmodules` line 8) and commit.

Order matters: commit the child before the parent that references it.

### Step 5 — Vendor & dependencies review

The `vendor/` packages (ppxlib 0.38, cohttp 6, js_of_ocaml fork, lsp, …) are
pinned for reasons independent of the JST release (the sexplib0 two-provider
problem). They do **not** move with the JST version, but the new JST code may
demand newer APIs:

- **cohttp 6 / ppxlib 0.38 API drift** — if `130.106+341` touches HTTP or ppx
  call sites, the fixes in `doc/changes/cohttp6.md`, `jsoo-api.md`, and the
  ppxlib-0.38 labeled-tuple handling (`ocaml55-compat.md` §9) may need
  extending.
- **`ppxlib_jane` constraint** — still the standing risk in `doc/todo.md`
  (constrains ppxlib `>= 0.33 & < 0.36`, we vendor 0.38). A newer bonsai/ppx
  drop is exactly where fresh incompatibilities tend to surface.
- **`Bigstring_unix` split, `core_unix` deps** — re-check that any new call
  sites using `Bigstring.read*` still carry the `core_unix` dep.

### Step 6 — Rebuild and fix fallout

```sh
TMPDIR=$PWD/.dune-tmp opam exec --switch=$PWD -- dune build --root=. @install 2>&1
```

Expect a new round of: JST-only syntax that slipped past the bulk seds, new
`include functor` / `[%call_pos]` / `local_` occurrences in newly-added code,
new warning-as-error promotions, and API drift in core/async/bonsai. Each new
fix should be captured as (or appended to) a file under `doc/changes/`.

### Step 7 — Update docs & the switch, if needed

- `doc/structure.md` version table — add the `130.106+341` row.
- `doc/work-in-progress.md` — bump the "Goal" version line.
- `CLAUDE.md` — update the four branch-convention lines.
- opam switch: only if the new release requires a newer compiler than
  `ocaml-variants.5.5.0+options`; `130.106` within the same `v0.18` line most
  likely does not.

---

## 5. New packages — the flagged unknown

The request specifically calls out that the new release may contain packages
not present today. Handling them is the highest-variance part of the estimate,
because each new package can independently:

- pull in an **uninstalled dependency**, forcing either an opam install (watch
  for the **sexplib0 two-provider conflict** — see `CLAUDE.md`) or a new
  `vendor/` entry;
- use **OxCaml-only syntax** (`@kind`, `#(...)` unboxed products,
  `float32`, SIMD intrinsics, `unboxed_datatypes`, `portable_*`). Per
  `doc/changes/ocaml55-compat.md §10`, packages of this kind (`await`,
  `parallel`, `bonsai_term*`, `unboxed`, `ocaml_simd`, …) are currently
  **excluded** via `(enabled_if false)` / empty `(dirs ())` stanzas. New
  packages in these families would join the exclusion list rather than build;
- need a fresh `doc/changes/<pkg>.md` and a workspace registration.

**Action:** once §1's diff is known, triage new packages into
{builds clean, needs compat, exclude (OxCaml/missing dep)} before committing to
an effort number. Until that diff exists, the new-package cost is unbounded.

---

## 6. Risk assessment & effort shape

| Area | Risk | Why |
|------|------|-----|
| Bulk syntax transforms | **Low** | Deterministic, scripted, documented |
| Retained-package pointer churn | **Medium** | 310 packages × 6 minors of drift; mechanical but voluminous |
| core / async / bonsai API drift | **Medium–High** | `Comparable.Make*` sexp reqs, GADT matches, etc. already bit us once |
| ppxlib 0.38 / `ppxlib_jane` | **High** | Pre-existing unresolved item (`doc/todo.md`); new ppx code aggravates it |
| New packages | **High / unbounded** | Depends entirely on §1 diff; may need vendoring or exclusion |
| Vendor API drift (cohttp/jsoo/lsp) | **Medium** | Fixed at their own versions; new JST call sites may not match |
| opam switch / compiler | **Low** | Same `v0.18` line; 5.5.0 likely sufficient |

The dominant cost is **re-applying and extending the compat corpus across the
churn of 6 upstream minors**, plus **triaging new packages**. The infrastructure
(fork tooling, workspace, documented transforms, green baseline build) already
exists, which is what keeps this a bounded engineering task rather than a
from-scratch port — *modulo* the new-package unknown.

---

## 7. Execution checklist

- [ ] Raise `max_commits` in `list_releases`, re-run `list`, refresh `releases.sexp`.
- [ ] Diff package sets: enumerate **new**, **removed**, **retained**.
- [ ] Triage new packages (build / compat / exclude).
- [ ] `fork fork` + `set-remote` + `set-default-branch` for any new repos.
- [ ] Create `v0.18_preview.130.106+341+reloaded` branches; re-apply compat.
- [ ] Re-verify each `doc/changes/*.md` transform against the new tree.
- [ ] Extend `vendor/` compat if cohttp/ppxlib/jsoo APIs drift.
- [ ] Advance sub-submodule pointers; commit `releases/` on new branch.
- [ ] Point main-repo `releases` submodule at new branch; update `.gitmodules`.
- [ ] `dune build --root=. @install` green; capture new fixes as `doc/changes/`.
- [ ] Update `doc/structure.md`, `doc/work-in-progress.md`, `CLAUDE.md` version refs.
