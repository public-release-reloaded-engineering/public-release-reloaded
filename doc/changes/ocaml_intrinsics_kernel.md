# ocaml_intrinsics_kernel

## Weak symbols for the `[@@builtin]` abort-stubs

- `src/runtime.c`: the `BUILTIN(name)` macro now emits `CAMLweakdef void name()`
  instead of `void name()`, making all 44 generated stubs weak symbols:
  `caml_int_clz` / `ctz` / `popcnt` and the `int32` / `int64` / `nativeint`
  `clz` / `ctz` / `popcnt` / shift families.

### Why

Each `external` in `src/{int,int32,int64,nativeint}.ml` is marked `[@@builtin]`
and names a C symbol.  The symbol has to *exist* at link time even though it is
never called:

- in OxCaml native code (amd64 and arm64) the compiler expands the intrinsic
  inline and the stub is dead;
- everywhere else `Common.available` is `false` (see `src/common.ml`, which this
  port sets to `false`), so the OCaml fallbacks in `src/emu.ml` are used and the
  stub is again dead.

Hence the stub bodies are `assert(!"Didn't use [@@builtin] intrinsic."); abort();`
— placeholders that only satisfy the linker.

A placeholder must not out-rank a real definition.  **The OCaml 5.6 runtime
defines `caml_int_clz`**, so a strong definition here collides with it at link
time.  The OxCaml runtime has long defined several of these too — which is why
the `caml_simd_float64_*` stubs higher up in the same file were already
`CAMLweakdef`, and why `releases/ocaml_simd/sse/sse_stubs.c` already spells its
otherwise-identical `BUILTIN` macro with `CAMLweakdef`.  This change just brings
`ocaml_intrinsics_kernel`'s copy into line.

Making *all* of them weak, rather than only `caml_int_clz`, is deliberate: every
one is an unreachable abort-stub, so a weak binding is correct regardless of
which subset a given runtime happens to provide, and the file needs no update
the next time a runtime grows another of these.

### Not changed

`caml_csel_int_untagged`, `caml_csel_{int64,int32,nativeint}_unboxed` and
`caml_csel_value` stay **strong**.  They are real implementations, not
abort-stubs, and `csel` is an OxCaml notion that upstream does not define.  If a
future runtime does define them, they need the same treatment — but with a
different justification, since there the runtime's version would silently
replace a working implementation of ours.

### Verification

`nm --defined-only` on `_build/default/releases/ocaml_intrinsics_kernel/src/runtime.o`:

```
W caml_int_clz
W caml_int_clz_tagged_to_untagged
W caml_int_clz_untagged_to_untagged
W caml_int64_popcnt
...
T caml_csel_value          <- still strong, as intended
```

Neither `libasmrun.a` nor `libcamlrun.a` of the switch's ocaml 5.5.0 defines any
of these symbols, so the change is inert for the current compiler and only takes
effect against a runtime that provides its own.
`@releases/ocaml_intrinsics_kernel/runtest` passes.
