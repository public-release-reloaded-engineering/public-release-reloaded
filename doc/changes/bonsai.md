# bonsai ecosystem

This covers `bonsai`, `bonsai_web`, `bonsai_web_test`, `bonsai_web_components`,
`bonsai_examples`, and `bonsai_term_components`.

---

## `effect` → `effect_` rename (OCaml 5.3+ keyword)

All packages in the bonsai ecosystem used `effect` as a variable name,
typically bound to a `Vdom.Effect.t` value or passed as a labelled function
argument `~effect`.  Since `effect` became a reserved keyword in OCaml 5.3,
these uses are syntax errors in OCaml 5.5.

**Scope of rename:**

| Package | Directories affected |
|---------|---------------------|
| `bonsai` | `src/`, `bonsai_kernel_components/` |
| `bonsai_web` | `web/` |
| `bonsai_web_test` | all |
| `bonsai_web_components` | all sub-libraries |
| `bonsai_examples` | all |
| `memtrace_viewer` | all |

**Method:** `sed -i 's/\beffect\b/effect_/g'` applied to every `.ml` and `.mli`
file in the affected directories.  This consistently renames the variable,
label, and parameter in both implementation and interface files.

---

## `local_` and `@ local` removal

See `doc/changes/ocaml55-compat.md` §2.  The bonsai ecosystem is among the
heaviest users of these JST-only annotations.  The bulk removal applied to all
packages listed above.

---

## `include functor` replacement (`bonsai_term_components`)

Three files in `bonsai_term_components` used the JST-only `include functor`
syntax to derive comparison and ordering for local types.  Each was replaced
with an explicit functor application:

- `chart/src/line.ml`:
  `include functor Comparator.Make` →
  `include Comparator.Make (struct type nonrec t = t [@@deriving sexp_of, compare] end)`

- `tmux/src/bonsai_term_tmux.ml`:
  `include functor Comparable.Make` →
  `include Comparable.Make (struct type nonrec t = t [@@deriving compare, sexp_of] end)`

- `ncdu/src/bonsai_term_ncdu.ml`:
  `include functor Comparable.Make_plain` →
  `include Comparable.Make_plain (struct type nonrec t = t [@@deriving compare] end)`

---

## Warning suppressions

Several dune files in the bonsai ecosystem required warning flag additions
(in addition to the above code changes):

| File | Flags added |
|------|------------|
| `bonsai/bonsai_kernel_components/proc/dune` | `-w -67` |
| `bonsai/bonsai_kernel_components/id_gen/dune` | `-w -67` |
| `bonsai/src/driver/dune` | `-w -69` |
| `bonsai_web_components/experimental/snips/src/dune` | `-w -8 -alert -private_bonsai_view_library` |
| `bonsai_web_components/bonsai_codemirror/src/dune` | `-w -69` |
| `bonsai_web_components/element_size_hooks/src/dune` | `-w -69` |
| `bonsai_web_components/keyboard_shortcut/dune` | `-w -69` |
| `bonsai_web_components/low_level_vdom/src/dune` | `-w -69` |
| `bonsai_web_test/jsdom/src/dune` | `-w -69` |

---

## ppxlib 0.38 labeled-tuple encoding in `ppx_bonsai_expander`

`ppx_bonsai/src/expander/ppx_bonsai_expander.ml` contains a `variables_of`
traversal object (inside `duplicate_pattern`) that collects user-bound variable
names from patterns.  ppxlib 0.38 encodes OCaml 5.5 labeled-tuple patterns
as extension nodes (`ppxlib.migration.ppat_labeled_tuple_5_4`), using
`Ppat_var` nodes for label names and for the open/closed flag (`"closed_"`).
Because `Ast_traverse.fold` descends into extension payloads, these were
mistakenly added to the variable map, producing phantom unbound equality-check
variables at expansion time.

**Fix:** override `method! pattern` in the `variables_of` object to detect
the labeled-tuple extension, decode it with
`Astlib__Encoding_504.To_502.decode_ppat_labeled_tuple`, and recurse only on
the value patterns (second element of each `(label, pattern)` pair).

See also `doc/changes/ppx_pattern_bind.md` for the identical fix in
`ppx_pattern_bind`, and `doc/changes/ocaml55-compat.md` §9 for the ppxlib
0.38 context.

---

## js_of_ocaml API fixes

See `doc/changes/jsoo-api.md` for:
- `clipboardData` now `Js.opt` (`bonsai_web_components/clipboard`)
- `dataTransfer` now `Js.opt` (`bonsai_web_components/file/drop_file`)
- `composedPath` elements typed as `Js.Unsafe.any` (`bonsai_web/web/util.ml`,
  `bonsai_web_components/drag_and_drop`)

---

## `bonsai_web_components`: added missing `public_name`s

Several component libraries in `bonsai_web_components` ship upstream as
**private** libraries (a `(library (name …))` with no `(public_name …)`).  That
is fine within Jane Street's monorepo, but here these components are referenced
across package boundaries (e.g. `bonsai_examples` depends on
`bonsai_web_contrib_tabs`, `bonsai_web_notifications`, …).  A public library may
not depend on a private one, so `dune build @install` — and any opam install of
a consumer — fails until they are made public.

Added `(public_name …)` (following the `bonsai_web_components.<name>`
convention) to these libraries:

| Directory | `public_name` added |
|-----------|---------------------|
| `tabs/src` | `bonsai_web_components.tabs` |
| `notifications/src` | `bonsai_web_components.notifications` |
| `not_connected_warning_box/src` | `bonsai_web_components.not_connected_warning_box` |
| `experimental/animation/src` | `bonsai_web_components.experimental_animation` |
| `experimental/form/src` | `bonsai_web_components.experimental_form` |
| `experimental/table_form/src` | `bonsai_web_components.experimental_table_form` |
| `bonsai_codemirror/form/src` | `bonsai_web_components.codemirror_form` |
| `partial_render_table/configs_for_testing` | `bonsai_web_components.partial_render_table_configs_for_testing` |
| `partial_render_table/computation_report` | `bonsai_web_components.partial_render_table_computation_report` |

Not changed: `bonsai_codemirror/html_to_markdown` (`codemirror_html_to_markdown`)
is left **private** — it depends on the `html_to_markdown` and `lambdasoup`
libraries, which are not available in this workspace, so it cannot build.
Exposing it would only add an `@install` failure.  (Test libraries under
`*/test/` are intentionally left private, as usual.)
