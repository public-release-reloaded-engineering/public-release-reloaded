# hardcaml_step_testbench

- `digital_components/src/step_core_intf.ml` and `step_core.ml`: renamed the
  type parameter `'effect` to `'effect_` throughout.  OCaml 5.3 made `effect`
  a hard keyword; the lexer now tokenises `'effect` as the quote character `'`
  followed by the keyword `effect`, causing a syntax error in type parameter
  positions.
