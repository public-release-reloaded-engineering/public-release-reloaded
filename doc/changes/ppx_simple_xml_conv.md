# ppx_simple_xml_conv

- `expander/ppx_simple_xml_conv_expander.ml` line 673: replaced
  `Builder.pexp_function ~loc cases` with `Builder.pexp_function_cases ~loc cases`.
  ppxlib ≥ 0.38 changed `pexp_function` to take `function_param list *
  type_constraint option * function_body`; `pexp_function_cases` wraps a `case list`.
