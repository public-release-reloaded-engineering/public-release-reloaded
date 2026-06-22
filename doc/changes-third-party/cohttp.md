# cohttp (vendor)

The cohttp library is vendored in `vendor/cohttp/`.  Several components
required changes to build without unavailable dependencies.

## Disabled: eio backend

`cohttp-eio` depends on the `eio` library which is not available in this
build.  The following files were reduced to empty stubs:

- `cohttp-eio/src/dune`: library stub with `(modules)` and no dependencies.
- `cohttp-eio/examples/dune`: all executables removed.
- `cohttp-eio/tests/dune`: all tests removed.
- `cohttp-bench/dune`: removed the `eio_server` executable target.

## Disabled: mirage backend

`cohttp-mirage` depends on the mirage stack which is not available in this
build.

- `cohttp-mirage/src/dune`: library stub with `(modules)` and no dependencies.
