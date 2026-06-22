# jst-config

- `discover/discover.ml`: deleted the unused `type posix_timers` (with constructors
  `Available` and `Not_available`).  The type was defined but the surrounding code was
  refactored to use `C.c_test` returning `bool`, leaving the type completely unused.
  OCaml 5.x promotes warnings 34 and 37 (unused type / constructor) to errors here.
