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

Note: `v2/src` still does not link because `embedded_strings.ml` depends on the
`typeahead_worker.bc.js` js_of_ocaml artifact, which is a separate build-ordering
issue (not a source port).
