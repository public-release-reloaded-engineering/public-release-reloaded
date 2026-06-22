# hardcaml_c

## `lib/ctypes_foreign_flat.ml`: removed `Ctypes_foreign_threaded_stubs` alias

`Ctypes_foreign_threaded_stubs` is an internal C stub module from the `ctypes`
library that is not compiled to a `.cmi` file in the installed version.  The
alias `module Ctypes_foreign_threaded_stubs = Ctypes_foreign_threaded_stubs`
caused:

```
Error: Unbound module Ctypes_foreign_threaded_stubs
```

**Fix:** removed the alias line from `releases/hardcaml_c/lib/ctypes_foreign_flat.ml`.

See also: `hardcaml_verilator` has the identical fix.
