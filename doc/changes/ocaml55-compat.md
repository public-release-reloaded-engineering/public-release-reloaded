# OCaml 5.5 compatibility: cross-cutting changes

These changes were applied across many packages to make the workspace build
cleanly on OCaml 5.5.0+flambda with standard (non-Jane-Street-fork) OCaml.

---

## 1. `effect` is a reserved keyword (OCaml 5.3+)

`effect` became a keyword in OCaml 5.3 and cannot be used as a value name,
label, or parameter.  The following packages used `effect` as a variable name
(typically for a `Vdom.Effect.t` value or a labelled argument):

- `releases/bonsai/src/`
- `releases/bonsai/bonsai_kernel_components/`
- `releases/bonsai_web/`
- `releases/bonsai_web_test/`
- `releases/bonsai_web_components/` (all sub-libraries)
- `releases/bonsai_examples/`
- `releases/memtrace_viewer/`

**Fix:** bulk `sed -i 's/\beffect\b/effect_/g'` applied to every `.ml`/`.mli`
file in the affected directories (excluding files already using `effect_`).
This renamed the variable, label, and parameter consistently throughout each
package's public and internal interfaces.

---

## 2. `local_` / `@ local` are JST-only syntax extensions

Jane Street's OCaml fork supports `local_` as a keyword (marking stack
allocation) and `@ local` as a type modifier.  Neither is valid in standard
OCaml 5.5.  Examples of affected syntax:

```ocaml
(* Invalid in standard OCaml 5.5: *)
let f (local_ x) = x
type t = foo @ local
```

These extensions appear in a large fraction of the workspace packages.

**Fix:** bulk `sed -i 's/local_ //g; s/ @ local\b//g'` applied to all `.ml`
and `.mli` files in every non-excluded package under `releases/`.  Removing
`local_` and `@ local` produces valid standard OCaml — the code continues to
compile correctly, just without the stack-allocation hints.

---

## 3. `include functor` is a JST-only syntax extension

Jane Street's fork supports `include functor F` as a shorthand for applying a
functor `F` and including its result.  This is not valid in standard OCaml 5.5.

Three files in `releases/bonsai_term_components/` used this syntax:

- `chart/src/line.ml`:
  ```ocaml
  (* Before *)
  include functor Comparator.Make
  (* After *)
  include Comparator.Make (struct type nonrec t = t [@@deriving sexp_of, compare] end)
  ```

- `tmux/src/bonsai_term_tmux.ml`:
  ```ocaml
  (* Before *)
  include functor Comparable.Make
  (* After *)
  include Comparable.Make (struct type nonrec t = t [@@deriving compare, sexp_of] end)
  ```

- `ncdu/src/bonsai_term_ncdu.ml`:
  ```ocaml
  (* Before *)
  include functor Comparable.Make_plain
  (* After *)
  include Comparable.Make_plain (struct type nonrec t = t [@@deriving compare] end)
  ```

---

## 4. `stack` → `stack_local` in ppx_template alloc/mode annotations

In compound `(Alloc @ Mode)` contexts within `ppx_template` annotations, the
allocator name `stack` (type `Alloc`) must be written `stack_local` (type
`Alloc × Mode`) when both allocator and mode are specified together.

**Fix:** targeted `sed` replacing `\bstack\b` with `stack_local` only on lines
matching `[a-z] @ [a-z]` (i.e. lines that already have an alloc-mode
compound), applied across all non-excluded packages.

---

## 5. `[@@@warning "-incompatible-with-upstream"]` is a JST-only warning name

Jane Street's fork defines the named warning `incompatible-with-upstream`.
Standard OCaml 5.5 rejects CLI-style warning names in attributes.

**Fix:** removed the attribute from:
- `releases/core/validate/src/validate.ml`
- `releases/core/validate/src/validate.mli`

---

## 6. Warning suppressions added to dune files

OCaml 5.x promotes several warnings to errors that older OCaml versions
treated as informational.  The following warning numbers were suppressed in
over 40 dune library stanzas:

| Warning | Meaning | Packages affected (sample) |
|---------|---------|---------------------------|
| 67 | Unused functor parameter | `streamable`, `resource_cache`, `bonsai`, `env_config`, `hardcaml_*`, `ecaml`, `incremental`, `procfs`, `legacy_diffable`, `versioned_polling_state_rpc`, `hardcaml_hobby_boards_kernel`, and more |
| 69 | Unused record field | `core_unix/iobuf_unix`, `ppx_css`, `core_profiler`, `sexp`, `async_log`, `memtrace_viewer`, `bonsai_web_components/{bonsai_codemirror,element_size_hooks,keyboard_shortcut,low_level_vdom}`, `bonsai_web_test/jsdom`, `toplayer`, and more |
| 32 | Unused value declaration | `async_unix`, `procfs`, `ppx_simple_xml_conv`, `bonsai_web_components/experimental/snips` |
| 34 | Unused open statement | `core_bench`, `toplayer` |

All suppressions use `(flags (:standard -w -NN))` in the relevant `(library ...)`
stanza.  Deprecation alerts were suppressed with `-alert -deprecated` where
needed (e.g. `cohttp_async_websocket`, `cohttp_static_handler`, `email_message`,
`async_websocket`, `async_rpc_websocket`, `vendor/httpaf`).

---

## 7. Packages excluded from the build

The following packages require Jane Street's proprietary OCaml fork or an
uninstalled dependency and cannot be built with standard OCaml 5.5:

| Package | Reason |
|---------|--------|
| `await` | Requires JST-internal effect/concurrency primitives |
| `concurrent` | Requires JST-internal concurrency primitives |
| `hardcaml_step_testbench` | Requires `handled_effect` (JST-internal C stub) |
| `ocaml_simd` | Requires JST-internal SIMD extensions |
| `parallel` | Requires JST-internal parallel runtime |
| `skyline` | Pervasive `local_`/`@ local` JST syntax — not fixable by removal |
| `unboxed` | Requires JST unboxed types extension |
| `ocaml_openapi_generator` | Requires `jingoo` (template engine, not installed) |

Excluded via `(dirs (:standard \ await concurrent ...))` in `releases/dune`.
