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

## 7. `Comparable.Make*` requires sexp derivation in core v0.18

Core v0.18 changed the signature requirements for `Comparable.Make*` functors:

- `Comparable.Make_plain` now requires `sexp_of_t` in addition to `compare`
- `Comparable.Make` and `Comparable.Make_using_comparator` require both directions
  (`sexp_of_t` and `t_of_sexp`, i.e. full `[@@deriving sexp]`)

Many packages that passed `[@@deriving compare]` or `[@@deriving sexp_of, compare]`
to these functors needed updating.

**Fix:** add `sexp_of` (for `Make_plain`) or change `sexp_of` to `sexp` (for
`Make` / `Make_using_comparator`) in the relevant `[@@deriving ...]` attributes.

Notable affected locations: `skyline` (multiple components).

---

## 8. `[%call_pos]` is a JST-only ppx extension

Jane Street's fork defines `[%call_pos]` as a type annotation meaning "the
caller's source position".  Standard ppxlib does not recognize it.

```ocaml
(* JST-only: *)
val f : here:[%call_pos] -> unit

(* Standard OCaml 5.5: *)
val f : here:Source_code_position.t -> unit
```

`Source_code_position.t` is identical to `Stdlib.Lexing.position` and is
what `[%here]` produces.  Call sites that previously received the position
implicitly (via ppx magic) need an explicit `~here:[%here]` argument.

**Fix:** replace `[%call_pos]` with `Source_code_position.t` in signatures and
implementations; add `~here:[%here]` at call sites where `~here` was not
already propagated.

Notable affected location: `skyline/bonsai_web_components/browser_storage`.

---

## 9. ppxlib 0.38 labeled tuple encoding and `Ast_traverse`

ppxlib 0.38's internal AST is fixed at OCaml 5.2.  Labeled tuple patterns and
types from OCaml 5.5 are encoded as extension nodes:

```
Ppat_extension("ppxlib.migration.ppat_labeled_tuple_5_4", payload)
```

The encoding stores label names as `Ppat_var` nodes and the closed/open flag
as a literal `Ppat_var "closed_"` or `Ppat_var "open_"`.

`Ast_traverse.map` and `Ast_traverse.fold` descend into `Ppat_extension`
payloads and visit these encoding metadata nodes as if they were user
variables.  This causes two classes of bugs:

1. **`replace_variable`** in `ppx_pattern_bind`: renames/removes the
   `Ppat_var "closed_"` flag (it's not in the variable map, so it gets
   `\`Remove`), making `decode_ppat_labeled_tuple` fail with
   `Invalid ppxlib.migration.ppat_labeled_tuple_5_4 encoding`.

2. **`variables_of`** in `ppx_pattern_bind` and `ppx_bonsai_expander`: adds
   `"closed_"` and the label name strings to the variable set, generating
   phantom equality-check bindings (`__old_for_cutoff__028_` etc.) that are
   never bound.

**Fix:** in both `replace_variable` and `variables_of`, detect the labeled
tuple extension by name, decode it with `Astlib__Encoding_504.To_502`, recurse
only on the actual value sub-patterns, and (for `replace_variable`) re-encode
the result.  Add `ppxlib.astlib` to the dune libraries of both packages.

Affected packages: `ppx_pattern_bind`, `bonsai/ppx_bonsai`.

A similar fix was needed in `ppxlib_jane/src/shim.ml` for the migration
encoding/decoding of `Ppat_desc`, `Core_type_desc`, and `Expression_desc`.

---

## 10. Packages excluded from the build

The following packages require Jane Street's proprietary OCaml fork or an
uninstalled dependency and cannot be built with standard OCaml 5.5:

| Package | Reason |
|---------|--------|
| `await` | JST-specific syntax: `@ portable` modalities, unboxed records |
| `concurrent` | Requires JST-internal concurrency primitives |
| `hardcaml_step_testbench` | Dune git file-tracking issue with nested git repo in workspace |
| `ocaml_simd` | Requires JST-internal SIMD extensions |
| `parallel` | Requires JST-internal parallel runtime |
| `unboxed` | Requires JST unboxed types extension |
| `ocaml_openapi_generator` | Requires `jingoo` (template engine, not installed) |

Packages formerly excluded but now building: `skyline` (fully ported).

Excluded via `(dirs (:standard \ await concurrent ...))` in `releases/dune`
and per-package `(dirs ())` stanzas in the sub-submodule dune files.
