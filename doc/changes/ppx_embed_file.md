# ppx_embed_file

- `main.ml`: resolve embedded paths relative to the **source file's directory**
  rather than the ppx process's working directory.

  `[%embed_file_as_string "path"]` read `path` with `In_channel.with_file`,
  i.e. relative to the ppx's current working directory. Dune runs ppx rewriters
  with the working directory set to the **build-context root** — the enclosing
  workspace root, not the package root. So a relative embed path only resolves
  when the package sits at the workspace root, as it did in the original Jane
  Street monorepo. Vendored under `releases/<pkg>/`, the same path pointed one or
  more directory levels too high and failed with e.g.

  ```
  Error: I/O error: components/picker/v2/typeahead_worker/bin/typeahead_worker.bc.js: No such file or directory
  ```

  (`skyline` picker_v2 embeds its web-worker's compiled JS this way). The other
  in-tree use, `bonsai_examples/codemirror_readonly` (`[%embed_file_as_string "./main.ml"]`),
  was broken for the same reason.

  There is no way for the ppx to recover the package root: dune does not mirror
  `dune-project` into `_build`, ppxlib's `Code_path` exposes no project/workspace
  root, and dune sets no environment variable carrying it. But the source file's
  own path (`loc.loc_start.pos_fname`) is always build-root-relative and stable,
  so resolving the embed path against `Filename.dirname` of it works identically
  whether the package is built standalone (root = the package) or nested inside
  another workspace. Absolute paths are left untouched.

  Consequence for callers: embed paths are now written **relative to the source
  file**. `skyline`'s picker_v2 embed path changed from the package-root-relative
  `components/picker/v2/typeahead_worker/bin/typeahead_worker.bc.js` to the
  source-relative `../typeahead_worker/bin/typeahead_worker.bc.js`
  (see `doc/changes/skyline.md`).
