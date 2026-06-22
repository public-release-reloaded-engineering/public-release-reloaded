# ppx_module_timer

- `runtime/dune`: added `(flags (:standard -w -69))` to suppress warning 69
  (unused mutable record field) for `nested_timer` in
  `ppx_module_timer_runtime.ml`.  The field is declared mutable for future
  mutation but is never written in any currently reachable path;
  OCaml 5.x promotes warning 69 to an error.
