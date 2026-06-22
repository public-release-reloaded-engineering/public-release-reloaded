# js_of_ocaml API changes

Several properties in js_of_ocaml's DOM bindings changed from returning bare
values to returning `Js.opt` values (reflecting the JavaScript reality that
these properties can be `null`).  The affected packages required code changes
to unwrap the optional values.

---

## `clipboardData` now returns `Js.opt`

`Dom_html.clipboardEvent##.clipboardData` changed type from
`Dom_html.dataTransfer Js.t` to `Dom_html.dataTransfer Js.t Js.opt`.

**File:** `releases/bonsai_web_components/clipboard/js_clipboard/src/synchronous.ml`

All four access sites were updated to use `Js.Opt.iter` (for write-only paths)
or `Js.Opt.case` (for read paths):

```ocaml
(* Before *)
cl##setData (Js.string type_) (Js.string (f ()))

(* After — intercept_copy_type *)
Js.Opt.iter event##.clipboardData (fun cl ->
  cl##setData (Js.string type_) (Js.string (f ())))

(* Before *)
Js.to_string (cl##getData (Js.string type_))

(* After — intercept_paste_type *)
Js.Opt.case event##.clipboardData
  (fun () -> "")
  (fun cl -> Js.to_string (cl##getData (Js.string type_)))
```

---

## `dataTransfer` now returns `Js.opt`

`Dom_html.dragEvent##.dataTransfer` changed type from
`Dom_html.dataTransfer Js.t` to `Dom_html.dataTransfer Js.t Js.opt`.

**File:** `releases/bonsai_web_components/file/drop_file/bonsai_web_drop_file.ml`

- `on_dragenter` handler: replaced `e##.dataTransfer##.dropEffect := ...` with
  `Js.Opt.iter e##.dataTransfer (fun dt -> dt##.dropEffect := ...)`, and
  replaced direct call to `dragging_over_state e##.dataTransfer` with a
  `Js.Opt.to_option` match (returning `` `No_files_valid `` when `None`).
- `on_dragover` handler: same `Js.Opt.iter` wrapping for `dropEffect`.
- `on_drop` handler: `get_files_guaranteed_present_exn` now only called when
  `Js.Opt.to_option e##.dataTransfer` returns `Some`.
- `on_paste` handler: `e##.clipboardData` also returns `Js.opt`; wrapped with
  `Js.Opt.to_option`, returning `Effect.Ignore` on `None`.

---

## `composedPath()` elements typed as `Js.Unsafe.any`

`event##composedPath` returns `'a Js.js_array Js.t` where `'a` is the element
type.  In newer js_of_ocaml / OCaml 5.5, the element type defaults to
`Js.Unsafe.any = Js.Unsafe.top Js.t` rather than remaining flexible, so
`##.` property access on the resulting array elements fails.

**File:** `releases/bonsai_web/web/util.ml` — `am_within_disabled_fieldset`

Replaced `element##.tagName` and `element##.disabled` (which require a typed
object) with `Js.Unsafe.get element "tagName"` and `Js.Unsafe.get element
"disabled"`, which work on any untyped value:

```ocaml
(* Before *)
let tag_name = Js.Optdef.to_option element##.tagName in
let disabled = Js.Optdef.to_option element##.disabled in

(* After *)
let tag_name = Js.Optdef.to_option (Js.Unsafe.get element "tagName") in
let disabled = Js.Optdef.to_option (Js.Unsafe.get element "disabled") in
```

**File:** `releases/bonsai_web_components/drag_and_drop/src/bonsai_web_drag_and_drop.ml` (two call sites — `on_mousedown` and `on_mousemove` handlers)

Replaced `element##.dataset` with a `Js.Unsafe.coerce` to `Dom_html.element
Js.t` followed by a direct property access, and removed the surrounding
`Js.Opt.to_option` (since `dataset` is a mandatory property in current
js_of_ocaml):

```ocaml
(* Before *)
let%bind.Option dataset = Js.Opt.to_option element##.dataset in

(* After *)
let element : Dom_html.element Js.t = Js.Unsafe.coerce element in
let dataset = element##.dataset in
```
