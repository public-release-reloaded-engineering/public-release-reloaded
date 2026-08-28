# postgres_async

- `src/scram_sha256.ml`: `Pbkdf.pbkdf2` API change. The `kdf`/`pbkdf` library
  (used for SCRAM-SHA-256 auth) switched `~password` / `~salt` and its result
  type from `Cstruct.t` to `string`. `pbkdf2_sha256` was wrapping its arguments
  in `Cstruct.of_string` and converting the result with `Cstruct.to_string`;
  those conversions were removed so the arguments and result stay `string`:

  ```ocaml
  (* before *)
  Pbkdf.pbkdf2 ~prf:`SHA256
    ~password:(Cstruct.of_string password)
    ~salt:(Cstruct.of_string salt)
    ~count:iterations ~dk_len:(Int32.of_int_exn key_length)
  |> Cstruct.to_string

  (* after *)
  Pbkdf.pbkdf2 ~prf:`SHA256 ~password ~salt
    ~count:iterations ~dk_len:(Int32.of_int_exn key_length)
  ```

  `Cstruct` is no longer used, so it was dropped from `src/dune`'s `(libraries)`.

  Note on the symptom: with the (default) `-short-paths` flag, the type-checker
  did not report this mismatch — it **hung** (non-terminating), which showed up
  as a stuck `ocamlopt` on `scram_sha256.pp.ml` during the workspace build.
  Compiling with `-short-paths` removed surfaced the real error immediately
  (`Cstruct.t` vs `string` at the `~password` argument). Fixing the type error
  also eliminates the hang, since the loop was in `-short-paths` error-path
  formatting.
