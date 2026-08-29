# skyline

All changes are in a single commit (`compat: port skyline to OCaml 5.5 and
upstream ppxlib/core`) touching `bonsai_web_components/` sub-libraries and
`private/` internal libraries.

---

## `local_` / `@ local` removal

Bulk removal (see `doc/changes/ocaml55-compat.md` §2) applied to all files
under `bonsai_web_components/` and `private/`.  One mechanical damage site
required a manual fix: the `sed` pass corrupted `local_config` variable names
to `config` in several files — these were restored by hand.

---

## `effect` → `effect_` rename

Bulk rename (see `doc/changes/ocaml55-compat.md` §1) applied throughout.

---

## `[%call_pos]` → `Source_code_position.t`

Several files used the JST-only `[%call_pos]` PPX extension to capture caller
source positions.  Replaced with explicit `~here:[%here]` arguments at each
call site and changed the parameter type from the PPX-generated opaque type to
`Source_code_position.t` (which `[%here]` produces).

---

## `Comparable.Make*` — `sexp_of_t` / `t_of_sexp` requirement

See `doc/changes/ocaml55-compat.md` §7.  Three patterns appeared:

- `Comparable.Make_plain` → struct now includes `[@@deriving compare]` only
  (no sexp needed for `Make_plain`)
- `Comparable.Make` → struct now includes `[@@deriving compare, sexp_of]`
- `Comparable.Make_using_comparator` → struct now includes
  `[@@deriving compare, sexp_of, t_of_sexp]`

---

## `Iarray.t` field pattern matching

One match arm used `[]` as a literal empty-iarray pattern (JST extension).
Replaced with a guard: `iarray when Iarray.is_empty iarray`.

---

## Warning suppression

`private/typeahead/src/dune`: added `-w -69` (unused record field in a
public API record `typeahead_controller`; field is intentionally exported for
external use).

---

## `private/utility-classes/demo` disabled

The demo executable depends on `ppx_tailwind` and `private_skyline_utility_classes`,
neither of which is available in the public release.  Its `dune` file has
`(enabled_if false)` added.

---

## `picker/v2` OxCaml constructs (typeahead worker)

`components/picker/v2` is the only skyline component using OxCaml-only syntax.
(The related `%tydi` disambiguation failure was a `ppx_tydi` bug — see
`doc/changes/ppx_tydi.md`.)  Remaining source ports:

- `v2/src/worker_filter.ml`:
  - `include functor Comparator.Make` → explicit
    `include Comparator.Make (struct type nonrec t = t [@@deriving compare, sexp_of] end)`.
  - Attributes on type *parameters* (`type ('a[@sexp.phantom], 'b[@sexp.phantom]) t`,
    `type 'a[@sexp.phantom] t`) are a JST grammar extension that stock OCaml's
    parser rejects.  Moved to the floating `[@@sexp.phantom: …]` form that
    `ppx_sexp_conv` also accepts: `[@@sexp.phantom: 'a * 'b]` and
    `[@@sexp.phantom: 'a]` on the declaration.  (Inline `[@sexp.phantom]` on a
    core_type in a type *application* — e.g. `(('a[@sexp.phantom]), …) Action.t` —
    parses fine and is left as-is.)

- `v2/src/local_data_source.ml`: `let mutable acc = … / acc <- …` (OxCaml local
  mutable binding) rewritten to a `ref` (`let acc = ref … / acc := …`).

- `v2/src/embedded_strings.ml`: the `[%embed_file_as_string …]` path was
  package-root-relative (`components/picker/v2/typeahead_worker/bin/typeahead_worker.bc.js`),
  which only resolves when skyline is the workspace root. Changed to the
  source-relative `../typeahead_worker/bin/typeahead_worker.bc.js`, paired with
  the `ppx_embed_file` fix that resolves embed paths relative to the source file
  (see `doc/changes/ppx_embed_file.md`). Works both standalone and nested under
  `releases/skyline/`.

With these changes the whole `components/picker` component builds (library +
`typeahead_worker` bin's `.bc.js` + the embedding `picker_v2` library).

---

## `skyline.opam`: restore `ppx_embed_file` dependency

`ppx_embed_file` (used by `components/picker/v2/src`) was missing from
`depends`. It was dropped by commit `2f14045` ("compat: update opam version
constraints for OCaml 5.5"): upstream listed it as a *bare, unconstrained*
`"ppx_embed_file"` entry, so it sat among the third-party deps that commit was
rewriting and was removed alongside them without being re-added — even though it
is a first-party `releases/` package.  The build never noticed because dune
resolves ppx from the workspace regardless of opam metadata.  Re-added, now
correctly constrained as a releases dep: `"ppx_embed_file" {>= "v0.18~" & < "v0.19~"}`.
(A cross-check confirmed it was the only first-party dep `2f14045` dropped, and
the other ppx used only in the disabled `docs`/`demo` dirs correctly remain
absent.)

---

## `bonsai_web_components/focusable_list/docs` disabled

The docs library `bonsai_garden_focusable_list_docs` depends on
`bonsai_garden_docs_common`, `bonsai_garden_markdown_render_engine`, and the
`ppx_demo_md` ppx — the bonsai_garden docs infrastructure, none of which is in
the public release. It is a leaf (nothing depends on it), so `(enabled_if false)`
was added to its `dune` (same treatment as `private/utility-classes/demo`).
With this, all of `releases/skyline` builds.
