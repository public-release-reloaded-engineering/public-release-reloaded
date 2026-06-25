# notty_async

Previously disabled with `(enabled_if false)` in `src/dune` under the comment
"requires internal unreleased packages".  The actual dependency was only
`notty-community` (a public opam package).

**Fix:** install `notty-community` 0.2.4 into the opam switch and restore the
`src/dune` file:

```
(library
 (name notty_async)
 (public_name notty_async)
 (libraries base async core_unix notty-community notty-community.unix)
 (flags (:standard -w -69))
 (preprocess (pps ppx_jane)))
```

`notty-community.unix` is listed explicitly because `notty_async.ml` uses
`Notty_unix.Private.{cap_for_fd,setup_tcattr,Gen_output}` and contains a C
binding `external winch_number : unit -> int = "caml_notty_winch_number"`
whose stub is in `libnotty_unix_stubs.a` (part of `notty-community.unix`).

`-w -69` suppresses an unused-field warning on `fds : Fd.t * Fd.t` in the
`Term.t` record; the field is set but never read (it is kept as a GC root).
