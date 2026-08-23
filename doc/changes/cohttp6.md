# Cohttp 6 API changes

The workspace uses vendored `cohttp` / `cohttp-async` (in `vendor/cohttp/`),
which tracks the cohttp 6.x series.  Several API changes from earlier versions
required fixes in packages that call into cohttp.

---

## `respond_with_file` and `respond_string` lost `?flush`

`Cohttp_async.Server.respond_with_file` and `respond_string` no longer accept
a `?flush` optional argument.  Any call site that forwarded `?flush` through
needed to drop it.

**Files changed:**

- `releases/cohttp_static_handler/src/cohttp_static_handler.ml`:
  - `respond_with_file_or_gzipped`: removed `?flush` from signature and call
  - `respond_string`: removed `?flush` from signature and call to
    `Cohttp_async.Server.respond_string`

- `releases/bonsai_examples/open_source/rpc_chat/server/src/bonsai_chat_open_source_native.ml`:
  - local `respond_string`: removed `?flush` from signature and call

- `releases/memtrace_viewer/server/src/memtrace_viewer_native.ml`:
  - local `respond_string`: removed `?flush` from signature and call
  - `main`: `~http` parameter was declared but never used in the body;
    renamed to `~http:_` to silence warning 27

---

## `Cohttp_async.Io` restructured — use `Cohttp_async.Io.IO` as functor argument

`Cohttp.Request.Make` and `Cohttp.Response.Make` expect a module satisfying
`Cohttp.S.IO` (with `type t`, `type ic`, `type oc`, `type conn`, …).

In the old API, `Cohttp_async.Io` itself satisfied `S.IO`.  In cohttp 6,
`Cohttp_async.Io` is a container module with three sub-modules
`{ IO; Request; Response }` — it no longer matches `S.IO` directly.  The
correct functor argument is `Cohttp_async.Io.IO`.

**File:** `releases/cohttp_async_websocket/src/cohttp_async_websocket.ml` (line 500):

```ocaml
(* Before *)
module Request_  = Cohttp.Request.Make  (Cohttp_async.Io)
module Response_ = Cohttp.Response.Make (Cohttp_async.Io)

(* After *)
module Request_  = Cohttp.Request.Make  (Cohttp_async.Io.IO)
module Response_ = Cohttp.Response.Make (Cohttp_async.Io.IO)
```

---

## `Cohttp_async.Io.IO.ic` is `Input_channel.t`, not `Reader.t`

With the `Cohttp_async.Io.IO` module, `IO.ic = Cohttp_async__Input_channel.t`
(a buffered wrapper around `Async_unix.Reader.t`), not `Reader.t` itself.

`Cohttp.Response.Make(Cohttp_async.Io.IO).read` therefore expects an
`Input_channel.t`.  In `cohttp_async_websocket`, the TCP connection yields a
raw `Async_unix.Reader.t`; it must be wrapped before passing to
`Response_.read`.

**File:** `releases/cohttp_async_websocket/src/cohttp_async_websocket.ml`
(function `read_websocket_response`):

```ocaml
(* Before *)
let read_websocket_response (request : Request.t) reader =
  match%map Response_.read reader with ...

(* After *)
let read_websocket_response (request : Request.t) (reader : Async_unix.Reader.t) =
  let ic = Cohttp_async__Input_channel.create reader in
  match%map Response_.read ic with ...
```

Note: the `reader : Async_unix.Reader.t` is still used directly for the
WebSocket pipe (`websocket_create ... reader writer`) — only the HTTP response
header read uses the `Input_channel` wrapper.

---

## `Cohttp_async.Request` deprecated alert

`Cohttp_async.Request` (a re-export of `Cohttp.Request`) is deprecated in
cohttp 6.  `releases/async_rpc_websocket/src/src/rpc.mli` references it in
type annotations.

**Fix:** added `(flags (:standard -alert -deprecated))` to
`releases/async_rpc_websocket/src/src/dune`.

---

## `cohttp-async` opam constraint excluded 6.x

Several packages carried the upstream disjunction

```
"cohttp-async" {>= "2.5.7" & < "3.0.0" | >= "5.1.1" & < "6.0.0"}
```

which caps below `6.0.0` and therefore excludes the cohttp-async 6.x series this
workspace targets (the code is ported to the cohttp 6 API, above).  This only
matters for opam resolution — the dune build ignores opam constraints and uses
the vendored cohttp 6 — but it makes an opam install of these packages
unsatisfiable (or resolve an incompatible pre-6 cohttp-async).

**Fix:** relaxed the constraint to `{>= "6.2.1"}` (matching the sibling
`cohttp` constraint; works with cohttp-async 6.3.0), dropping the stale 2.x/5.x
ranges, in:

- `cohttp_async_websocket`
- `async_rpc_websocket`
- `cohttp_static_handler`
- `memtrace_viewer`
- `tracing`
- `bonsai_examples`
