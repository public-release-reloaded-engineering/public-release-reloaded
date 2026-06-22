# lsp_rpc

## `proof-of-concept/src/lsp_proof_of_concept.ml`: removed `CustomNotification` case

The installed LSP library (`jsonrpc 1.26.0` / `lsp`) removed the
`CustomNotification` constructor from `Lsp.Client_notification.t`.  Custom
notifications are now handled by the existing `UnknownNotification` constructor
instead.

The proof-of-concept server had a catch-all pattern that listed both:

```ocaml
| T (CustomNotification _)    (* no longer exists *)
| T (UnknownNotification _)
| Invalid_params _ -> return ()
```

**Fix:** removed the `| T (CustomNotification _)` line from
`releases/lsp_rpc/proof-of-concept/src/lsp_proof_of_concept.ml`.
The `UnknownNotification` branch already handles the same cases.
