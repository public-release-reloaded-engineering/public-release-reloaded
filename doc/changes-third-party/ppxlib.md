# ppxlib (vendor)

The ppxlib library (0.38.0) is vendored in `vendor/ppxlib/`.

## `astlib/migrate_504_503.ml`: bug fix in `copy_module_type_desc_with_loc`

The `Pmty_with` branch called `copy_module_type x0` on the module type being
migrated, but then passed the *copied* (migrated) type into
`Encoding_504.To_503.encode_bivariant_pmty_with`.  This caused the type to be
migrated twice when a bivariant constraint was detected.  Fixed by passing the
original `mty` (already the migrated value from the caller's scope) instead:

```diff
-      else Ast_503.Parsetree.Pmty_with (copy_module_type x0, constraints)
+      else Ast_503.Parsetree.Pmty_with (mty, constraints)
```

## `.opam` files: version field added

The generated `.opam` files (`ppxlib.opam`, `ppxlib-tools.opam`,
`ppxlib-bench.opam`) lacked a `version:` field, which caused dune to emit a
warning.  Added `version: "0.38.0"` to each.
