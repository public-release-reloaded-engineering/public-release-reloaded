# bigdecimal

## `src/zarith.ml`: removed `Zarith_version` alias

`Zarith_version` is a module that exists in some builds of the Zarith library
but is not compiled to a `.cmi` file in the installed version used here (Zarith
1.x from opam).  The alias `module Zarith_version = Zarith_version` caused a
build error:

```
Error: Unbound module Zarith_version
```

**Fix:** removed the line `module Zarith_version = Zarith_version` from
`releases/bigdecimal/src/zarith.ml`.
