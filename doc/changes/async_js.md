# async_js

## `src/http.ml`: GADT match with open object type

`XmlHttpRequest.response` is a GADT:

```ocaml
type _ response =
  | ArrayBuffer : Typed_array.arrayBuffer t Opt.t response
  | Blob        : #File.blob t Opt.t response   (* open object type *)
  | Document    : Dom.element Dom.document t Opt.t response
  | JSON        : 'a Opt.t response
  | Text        : js_string t response
  | Default     : string response
```

The `Blob` constructor refines the type parameter to `#File.blob t Opt.t`, an
open row type.  In standard OCaml 5.5, GADT equations involving open object
types cannot be established on a locally abstract type (`(type resp)`) when the
match expression also carries an explicit type annotation — the annotation
forces early unification of `resp` across all branches, causing the `Blob`
branch to be checked against the type inferred from the `ArrayBuffer` branch
(`Typed_array.arrayBuffer Js.t Opt.t`) rather than its own equation.

**File:** `releases/async_js/src/http.ml`

**Fix:** replaced the annotated `let%bind.Or_error content : resp Or_error.t =
match response_type with ...` with a locally polymorphic helper function
that performs the GADT match, giving OCaml a fresh rigid type variable per
branch:

```ocaml
(* Before — type annotation prevents per-branch GADT refinement *)
let%bind.Or_error content : resp Or_error.t =
  let get_text_contents_or_error () = ... in
  let open Response_type in
  match response_type with
  | ArrayBuffer -> Ok (File.CoerceTo.arrayBuffer req##.response)
  | Blob        -> Ok (File.CoerceTo.blob req##.response)  (* error here *)
  | ...

(* After — local polymorphic function allows per-branch refinement *)
let%bind.Or_error content =
  let get_text_contents_or_error () = ... in
  let open Response_type in
  let get_content : type r. r t -> r Or_error.t = function
    | ArrayBuffer -> Ok (File.CoerceTo.arrayBuffer req##.response)
    | Blob        -> Ok (File.CoerceTo.blob req##.response)
    | Document    -> Ok (File.CoerceTo.document req##.response)
    | JSON        -> Ok (File.CoerceTo.json req##.response)
    | Text        -> get_text_contents_or_error ()
    | Default     -> Or_error.map (get_text_contents_or_error ()) ~f:Js.to_string
  in
  get_content response_type
```

The `type r.` quantifier introduces a truly polymorphic `r` in the local
function, allowing OCaml to establish a fresh GADT equation in each branch
independently.
