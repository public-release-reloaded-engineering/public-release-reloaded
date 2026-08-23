# Updating to `v0.18~preview.130.106+341`

Scope study: what it would take to move this workspace from the current
release **`v0.18~preview.130.100+614`** to **`v0.18~preview.130.106+341`**.

This document is an analysis / plan, not a change log. It surveys the current
layout, explains the version scheme, and lays out the concrete steps, risks,
and open questions involved in a version bump.

---

## 0. Measured scope (crawl of 2026-07-21)

The org crawl was re-run with `-max-commits 100` and the two package sets
diffed (`releases.sexp` now reflects this run). **This overrides the worst-case
estimate in §5/§6** — the real scope is much smaller and fully bounded:

| Class | Count | Meaning | Action |
|-------|-------|---------|--------|
| **Changed** | 144 | Carry both a `…100+614` and a `…106+341` stamp — re-cut at the new release | Advance pointer + re-apply compat |
| **New** | 4 | Present only at `…106+341`, not in our tree | Fork, import, port, add as submodule |
| **Unchanged** | 166 | Carry `…100+614` (or earlier) but **no** `…106+341` stamp | **Leave at current commit** — not re-cut upstream, so nothing to import |

Verification that "unchanged" is safe (not a real removal):

- Our 310 submodules match the `130.100+614` crawl set **exactly** (0 diff both
  ways) — our tree is precisely at `130.100+614`.
- All 166 "unchanged" packages are **still in our submodule tree**; they include
  core packages (`stdio`, `variantslib`, `fieldslib`, `ppx_hash`,
  `ppx_inline_test`, …) that obviously remain part of v0.18. They simply were
  not re-stamped at `130.106+341`.
- `max_commits=100` was deep enough: no existing package was misclassified as
  "new" (all 4 new names are genuinely absent from our tree), and every
  unchanged package still shows its `…614` stamp within 100 commits (so a
  `…106` stamp, being newer, would have been seen if it existed).

**The 4 new packages:**

| Package | Likely nature |
|---------|---------------|
| `base_test` | Test code split out of `base` (JST's ongoing `_test` package split) |
| `sexplib0_test` | Test code split out of `sexplib0` |
| `fixed_list` | New data-structure library |
| `hardcaml_packed_array` | New hardcaml library |

So the executable job is: **re-port 144 changed packages, add + port 4 new
ones, and leave 166 untouched.** Not "310 × 6 minors."

---

## 0b. Pilot results (foundation, 2026-08-22)

Piloted the re-port on the foundational chain to validate the pipeline. **8
packages rebased onto their `106` upstream** on new
`v0.18_preview.130.106+341+reloaded` branches (old `…100+614…` branches left
untouched — verified): `base`, `sexplib0`, `basement`, `capsule0`,
`ppx_sexp_conv`, `ppx_compare`, `ppx_template`, `sexp_grammar`.

**What worked (validated):**

- **Rebase-onto-106 is the right mechanic.** For each package the old
  `+reloaded` branch = pristine `614` + a short stack of compat commits, and
  `614` is a clean ancestor. `git rebase --onto <106> <614>` on a *new* branch
  replays compat cleanly; source files rebased with **zero conflicts** in every
  case.
- **Residual JST syntax is minimal.** `106` occasionally introduces new
  `stack @ local` ppx_template alloc compounds in files our old textual compat
  never touched; the fix is the same documented transform (`stack @ local` →
  `stack_local`, leaving `heap @ global` and axis vars like `a @ l` intact).
  Found ~1 such case in `base`; none in the others.
- **API drift from *changed* ppx packages is fixed by updating them.**
  `base@106`'s `equal_iarray [@kind k]` (bits64) error disappeared once
  `ppx_compare` was moved to `106`.

**Refined strategy (important):** our recent **opam-constraint commits**
(`constrain-deps`, ppxlib bumps, dev-repo URL rewrites) conflict on almost
every package because `106` changed dependency lists — but they only touch
`*.opam`. So during the rebase, **`git rebase --skip` any commit whose only
conflicts are in `*.opam`**, and **re-derive all opam metadata at the end**
across the whole `106` tree via the existing tooling (`constrain-deps`, the
ppxlib `{> "0.38.0"}` normalization, the dev-repo/branch URL rewrite, and
`populate-opam-repo.sh`). Don't hand-resolve constraint conflicts per package.

**New transform found (`~unboxed`) — cheap, not the ppxlib_jane rabbit hole.**
`base@106` uses a **new** deriving modifier `sexp ~unboxed` (614 had only
`sexp ~stackify`). Initially this mis-compiled (`Variable t_of_sexp is bound
several times`) even with `ppx_sexp_conv@106`, which looked like the standing
ppxlib_jane / ppxlib-0.38 gap. It is **not**: `~unboxed` generates converters
for unboxed-product types that don't exist on standard OCaml 5.5, i.e. it is
another **OxCaml-only modifier to strip** (like `local_`, `include functor`,
`[%call_pos]`). The fix is a one-line transform — `s/ ~unboxed//g` on deriving
attributes — and with it **`base@106` builds green (`dune build
releases/base/base.install`, exit 0).**

**Pilot outcome: SUCCESS.** `base@106` builds against its updated changed-dep
closure. The end-to-end pipeline for a changed package is now proven:
1. `git rebase --onto <106> <614>` on a new branch (skip `*.opam`-only commits);
2. strip residual JST syntax — `stack @ local` → `stack_local`, `s/ ~unboxed//g`,
   plus the existing `local_` / `include functor` / `[%call_pos]` transforms;
3. update the package's *changed* dependency closure the same way;
4. re-derive opam metadata via tooling at the end.

**New compat transforms to add to `doc/changes/ocaml55-compat.md`:**
- strip ` ~unboxed` from deriving attributes (OxCaml unboxed-product converters);
- `stack @ local` → `stack_local` in ppx_template alloc compounds introduced by
  `106` (keep `heap @ global` and axis vars like `a @ l`).

**State:** all pilot work is local, uncommitted, on new
`v0.18_preview.130.106+341+reloaded` branches; nothing pushed; old `…100+614…`
branches untouched; the `166` unchanged packages untouched.

---

## 0c. Batch re-port results (2026-08-23)

Ran the validated pipeline across all remaining changed packages (script
`.dune-tmp/rebase_pkg.sh`: rebase-onto-106 on a new branch, auto-`--skip` any
commit whose only conflicts are `*.opam`).

**Result: 131 of 144 changed packages rebased onto 106 and committed** (new
`v0.18_preview.130.106+341+reloaded` branches; old `…100+614…` branches intact;
all working trees clean).

- **120 clean** (112 batch + 8 pilot).
- **11 needed conflict resolution:**
  - 6 `dune` files — one pattern (106 changed `(libraries …)`, our compat added
    `(flags (:standard -w -NN))`): keep 106 libs + our flags. Scripted resolver.
  - `core/src/gc_stubs.c` — 106 has its own OCaml 5.3+ memprof path; took 106
    (our compat fix now redundant upstream).
  - `bonsai_examples` — 106 deleted `effect_examples.ml`; accepted deletion.
  - `ppx_diff` — `@ local`/`local_` in cinaps-generated strings; took 106 +
    re-applied the removal.
  - `bonsai_web`, `bonsai_web_components` — took 106 + re-applied mechanical
    transforms (`effect`→`effect_`, `local_`/`@ local` removal); the
    hand-written **jsoo-api** fixes (`doc/changes/jsoo-api.md`) were *not*
    re-applied and will resurface as build errors to fix build-driven.
- Residual `stack @ local` → `stack_local`: only `bin_prot`, `re2` (committed).

**Deferred (13 not on 106):**
- OxCaml-excluded, build-skipped anyway (fine to leave at 614): `await`,
  `bonsai_term`, `bonsai_term_components`, `bonsai_term_test`, `concurrent`,
  `ocaml_simd`, `parallel`, `proctopus`, `strace_ui`, `unboxed`. These reported
  `NO-106-COMMIT` (no `130.106+341` stamp on `janestreet/master`).
- Need attention: `skyline`, `hardcaml_template_project` (also `NO-106-COMMIT` —
  investigate default branch), `handled_effect` (`614-NOT-ANCESTOR` — needs a
  fresh re-port rather than rebase).

**Still to do (next phases):** add the 4 new packages; build-driven fixes
(`~unboxed` strip, jsoo-api re-application, any new API drift); re-derive opam
metadata across the whole 106 tree (`constrain-deps`, ppxlib `{> "0.38.0"}`,
dev-repo/branch URLs, `populate-opam-repo.sh`); assemble the `releases/`
`130.106+341` branch + main-repo pointer; full `@install` build.

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

- [x] Raise `max_commits` in `list_releases` (now a `-max-commits` flag,
      default 100), re-run `list`, refresh `releases.sexp`. *(done 2026-07-21)*
- [x] Diff package sets: **144 changed, 4 new, 166 unchanged** (see §0).
- [ ] Triage the 4 new packages (build / compat / exclude).
- [ ] `fork fork` + `set-remote` + `set-default-branch` for any new repos.
- [ ] Create `v0.18_preview.130.106+341+reloaded` branches; re-apply compat.
- [ ] Re-verify each `doc/changes/*.md` transform against the new tree.
- [ ] Extend `vendor/` compat if cohttp/ppxlib/jsoo APIs drift.
- [ ] Advance sub-submodule pointers; commit `releases/` on new branch.
- [ ] Point main-repo `releases` submodule at new branch; update `.gitmodules`.
- [ ] `dune build --root=. @install` green; capture new fixes as `doc/changes/`.
- [ ] Update `doc/structure.md`, `doc/work-in-progress.md`, `CLAUDE.md` version refs.
