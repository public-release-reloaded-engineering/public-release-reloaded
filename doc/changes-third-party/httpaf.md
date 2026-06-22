# httpaf (vendor)

The httpaf library is vendored in `vendor/httpaf/`.  One file required changes
for compatibility with the current Jane Street library versions.

## `async/httpaf_async.ml`: `Bigstring.read*` moved to `Bigstring_unix`

In `core` v0.17+, the Unix-specific bigstring I/O functions were moved from
`Core.Bigstring` into a new `Bigstring_unix` module (in the `core_unix`
package).  Two functions used in `httpaf_async.ml` are affected:

- `Bigstring.read` → `Bigstring_unix.read`
- `Bigstring.read_assume_fd_is_nonblocking` → `Bigstring_unix.read_assume_fd_is_nonblocking`

**Files changed:**

- `vendor/httpaf/async/httpaf_async.ml`: replaced both call sites.

- `vendor/httpaf/async/dune`: added `core_unix` to the `(libraries ...)` list
  (previously only `core` was listed), and added `-alert -deprecated` to flags
  (for `Async.Ivar.fill`, which was deprecated in favour of `fill_if_empty`).

```diff
 (libraries
-  async core faraday-async httpaf)
-(flags (:standard -safe-string))
+  async core core_unix faraday-async httpaf)
+(flags (:standard -safe-string -alert -deprecated))
```
