# base

- `src/set.ml`: moved `[@alloc a]` from inside the `with type` constraint to the outer
  `Ptyp_package` core type in the `sexp_of_m__t` template, i.e.
  `((module Elt) : (module Sexp_of_m with type t = elt)[@alloc a])`.
  Previously `(module Elt : Sexp_of_m with type t = elt[@alloc a])` placed the
  attribute on the constraint type `elt`, which ppx_template cannot see when visiting
  the `Ptyp_package` node, so `Sexp_of_m` was never mangled to `Sexp_of_m__stack`
  and the generated `sexp_of_t__stack` function referred to the non-existent
  `Elt.sexp_of_t__stack`.

- `src/map.ml`: same fix as `set.ml` — moved `[@alloc a]` to the outer `Ptyp_package`
  for the `sexp_of_m__t` template (module `K` instead of `Elt`).

- `src/bytes0.ml` / `src/bytes0.mli` / `src/bytes_stubs.c`: **GC-safety fix for
  `Bytes.create_local`.** The C stub `Base_unsafe_create_local_bytes` was declared
  `external … [@@noalloc]`, but on stock OCaml its body allocates on the GC heap
  (`caml_alloc_string`) — there is no local (stack) region as there is on OxCaml,
  where the annotation was truthful. `[@@noalloc]` tells the compiler no GC can
  occur across the call, so the call skips the GC safepoint and does not flush the
  allocation pointer; the freshly created bytes then get clobbered by the next
  allocation, producing a corrupted value.

  This corrupts any `Bytes.create_local` result. It surfaced as a **segmentation
  fault** in `String.filter_map` (via `local_copy_prefix`), which in turn crashed
  every `Enum.command_friendly_name` call — so building any `Core.Command`
  spec that used `Enum.make_param_*_of_flags` (e.g. `sexp diff`'s layout flag)
  segfaulted at startup.

  Fix: route `create_local` through the ordinary allocating `create`
  (`let create_local len = create len`), drop the now-false `[@@noalloc]`
  external and the `[@zero_alloc]`/`[@@zero_alloc]` assertions (they cannot hold
  for a heap allocation), and remove the unused `unsafe_create_local` external
  from the `.ml`/`.mli`. The `%template [@alloc stack] create` binding is kept
  (still resolved by `(Bytes.create [@alloc a])` when `a = stack_local`) but no
  longer claims to be zero-alloc. On stock OCaml a "local" bytes is simply a
  short-lived heap allocation — correct, just not stack-allocated.

  Note: the same pattern (a `[@@noalloc]` external whose stock-OCaml body actually
  heap-allocates) is a hazard to watch for elsewhere in the port; the C stub
  itself is now unreferenced from native code and could be removed.

- `src/comparator_intf.ml`: **re-expose `Comparator.t` as a `private` record.**
  The `Comparator` module type declared `type ('a, 'witness) t` abstractly (with
  `val compare` / `val sexp_of_t` accessors).  Base historically (through v0.17)
  exposed it as a private record

  ```ocaml
  type ('a, 'witness) t = private
    { compare : 'a -> 'a -> int
    ; sexp_of_t : 'a -> Sexp.t
    }
  ```

  and external libraries read the `compare` / `sexp_of_t` fields directly off a
  comparator value.  Restored the private-record exposure; `private` keeps
  construction internal to `Base` (preserving the witness-based safety invariant),
  while allowing field reads.  The `[@@unsafe_allow_any_mode_crossing]` attribute on
  the concrete definition is OxCaml-only and irrelevant to this stock-OCaml target,
  so it does not need to appear in the interface.

  Mechanical follow-through in `core` (see `doc/changes/core.md`): once the type is a
  record, `Core.Comparator`'s `include module type of Base.Comparator with type t := t`
  no longer type-checks, because OCaml forbids destructive substitution (`:=`) on a
  type whose declaration is a bare record/variant.  Core's re-export repeats the
  private-record manifest so the substitution has a manifest to bite on — a purely
  mechanical change; `Core.Comparator.t` already equalled `Base.Comparator.t`.
