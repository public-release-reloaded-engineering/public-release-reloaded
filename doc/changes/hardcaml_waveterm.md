# hardcaml_waveterm

Four sub-targets were previously disabled with `(enabled_if false)` and the
comment "requires internal unreleased packages".  All four depended only on
`notty_async` (workspace) and `notty-community` (public opam package, now
installed).

**Targets re-enabled:**

| Target | dune file |
|--------|-----------|
| `hardcaml_waveterm.interactive` | `interactive/dune` |
| `hardcaml-waveform-viewer` (binary) | `bin/dune` |
| `hardcaml_waveterm_test` library | `test/dune` |
| `hardcaml_waveterm_test_interactive` library | `test_interactive/dune` |

---

## `interactive/dune` — additional flags and ppx

The `interactive/` library uses `[@@deriving hardcaml, sexp_of]` on key types,
requiring `ppx_hardcaml` in the preprocessor list (was absent in the disabled
stub).  Two warnings were also suppressed:

- `-w -67`: unused functor parameters in `signals_window_intf.ml`,
  `waves_window_intf.ml`, and `values_window_intf.ml` (the `Render` parameter
  is part of the interface contract but not used in the intf body)
- `-w -69`: several mutable fields in `scroll.ml` that are set at construction
  time but never mutated after (intentional immutable-after-init pattern)

---

## `test/dune` — public library name for `filesystem.core`

The test library depends on `filesystem_core`.  Within the dune workspace the
internal library name is `filesystem_core` but dune requires the public name
`filesystem.core` when referencing a library from a different package.

---

## `test_interactive/test_notty_rendering.ml` — JST pipe-hole syntax

One expression used JST-specific "anonymous argument" syntax:

```ocaml
Test_data.create ...
|> Waveform.sort_ports_and_formats _ (Some [ Default ])
```

Standard OCaml does not allow `_` as a hole in a function application.
Rewritten as a let-binding:

```ocaml
(let t = Test_data.create ... in
 Waveform.sort_ports_and_formats t (Some [ Default ]))
```
