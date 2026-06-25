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
