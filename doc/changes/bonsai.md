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

## js_of_ocaml API fixes

See `doc/changes/jsoo-api.md` for:
- `clipboardData` now `Js.opt` (`bonsai_web_components/clipboard`)
- `dataTransfer` now `Js.opt` (`bonsai_web_components/file/drop_file`)
- `composedPath` elements typed as `Js.Unsafe.any` (`bonsai_web/web/util.ml`,
  `bonsai_web_components/drag_and_drop`)
