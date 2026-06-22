# memtrace_viewer

## `effect` → `effect_` rename

All `.ml`/`.mli` files in `releases/memtrace_viewer/` were processed by the
bulk `effect` → `effect_` rename (see `doc/changes/ocaml55-compat.md` §1).

## `server/src/memtrace_viewer_native.ml`: cohttp 6 + unused parameter

Two fixes in this file:

1. **`respond_string`**: removed `?flush` from the local wrapper's signature and
   from its call to `Cohttp_async.Server.respond_string`.  `?flush` was dropped
   in cohttp 6 (see `doc/changes/cohttp6.md`).

2. **`main ~http:_`**: the `~http` labelled parameter was declared in `main` but
   never referenced in the function body.  This triggered warning 27 (unused
   variable).  Renamed to `~http:_` to silence the warning without removing the
   parameter (its caller at the command definition site still passes it).

## `server/src/dune`: warning 69 suppression

Added `(flags (:standard -w -69))` to suppress "unused record field" warnings
in `filtered_trace.ml` (`prev_out_length`), `hierarchical_heavy_hitters.ml`
(`delta`), and `location_trie.ml` (`suffix_cache`).  These fields are set or
used in construction but never read by subsequent code paths; the warning is
spurious in context.
