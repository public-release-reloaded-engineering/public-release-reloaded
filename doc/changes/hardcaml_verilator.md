# hardcaml_verilator

## `src/ctypes_foreign_flat.ml`: removed `Ctypes_foreign_threaded_stubs` alias

Same issue as `hardcaml_c`: `Ctypes_foreign_threaded_stubs` has no `.cmi` in
the installed `ctypes` package.

**Fix:** removed `module Ctypes_foreign_threaded_stubs = Ctypes_foreign_threaded_stubs`
from `releases/hardcaml_verilator/src/ctypes_foreign_flat.ml`.
