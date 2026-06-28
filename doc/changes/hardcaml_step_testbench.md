# hardcaml_step_testbench

- `digital_components/src/step_core_intf.ml` and `step_core.ml`: renamed the
  type parameter `'effect` to `'effect_` throughout.  OCaml 5.3 made `effect`
  a hard keyword; the lexer now tokenises `'effect` as the quote character `'`
  followed by the keyword `effect`, causing a syntax error in type parameter
  positions.

---

## OCaml 5 effects port (eliminates `handled_effect` dependency)

`hardcaml_step_testbench` previously depended on `Handled_effect.S2` (from
`handled_effect.raises_in_jsoo`), which is implemented using OxCaml-specific
primitives (`%with_stack`, `%resume`, `%reperform`) and cannot be compiled with
standard OCaml 5.5.

Instead of porting `handled_effect` itself, the dependency was eliminated by
reimplementing the same semantics directly using `Effect.Shallow`.

### Changes to `digital_components/src/`

**`step_core_intf.ml`** — the `module Eff : Handled_effect.S2 with type ...`
constraint was replaced with a self-contained `Eff` module definition:

```ocaml
module Eff : sig
  type ('i, 'o) t
  module Handler : sig
    type ('i, 'o) t
  end
  type ('a, 'i, 'o, 'es) result =
    | Value : 'a -> ('a, 'i, 'o, 'es) result
    | Exception : exn -> ('a, 'i, 'o, 'es) result
    | Operation :
        ('ret, 'i, 'o, ('i, 'o) t) Effect_ops.t
        * ('ret -> ('a, 'i, 'o, 'es) result)
        -> ('a, 'i, 'o, 'es) result
  module Continuation : sig
    type ('a, 'b, 'i, 'o, 'es) t = 'a -> ('b, 'i, 'o, 'es) result
  end
  val run : (('i, 'o) Handler.t -> 'a) -> ('a, 'i, 'o, unit) result
  val perform : ('i, 'o) Handler.t -> ('a, 'i, 'o, ('i, 'o) t) Effect_ops.t -> 'a
end
```

**`step_core.ml`** — `Eff.Handler.t = unit` (abstract to callers).
A private `step_op` GADT erases the existential `'i`/`'o` parameters so the
effect can be installed as a standard OCaml `Effect.t` extension:

```ocaml
type _ step_op = AnyOp : ('ret, _, _, _) Effect_ops.t -> 'ret step_op
type _ Effect.t += Step_op : 'a step_op -> 'a Effect.t
```

`Eff.run` uses `Effect.Shallow` so each resumed continuation installs a fresh
handler without nesting the result type:

```ocaml
let run (type i o) (f : (i, o) Handler.t -> _) =
  let rec resume_with_handler
    : type ret b. (ret, b) Effect.Shallow.continuation -> ret -> (b, i, o, unit) result
    = fun k v ->
    Effect.Shallow.continue_with k v
      { Effect.Shallow.retc = (fun b -> Value b)
      ; exnc = (fun e -> Exception e)
      ; effc = (fun (type r) (eff : r Effect.t) ->
          match eff with
          | Step_op (AnyOp op) ->
            Some (fun (k2 : (r, b) Effect.Shallow.continuation) ->
              Operation (Obj.magic op, fun v2 -> resume_with_handler k2 v2))
          | _ ->
            Some (fun (k2 : (r, b) Effect.Shallow.continuation) ->
              resume_with_handler k2 (Effect.perform eff)))
      }
  in
  resume_with_handler (Effect.Shallow.fiber (fun () -> f ())) ()
```

The `Obj.magic` cast on `op` is safe: the computation can only produce effects
with the correct `'i`/`'o` types matching the handler.

`Runner.Continuation.Effect_continuation` stores the resume closure directly
(a `Unique.Once.t`) instead of a `Eff.Continuation.t`.

**`dune`** — removed `handled_effect` from the `(libraries ...)` stanza.

**`test/dune`** — added `(flags (:standard -w -56))` to suppress warning 56
(unreachable match case in a generated expect-test that pattern-matches on the
`result` GADT).

### Key design points

- `Effect.Shallow` vs `Effect.Deep`: `Deep.continue k v` has the handler's
  overall return type as `k`'s second type parameter, causing result-type
  nesting when used recursively.  `Shallow.continue_with k v handler` keeps `k
  : (ret, b) continuation` where `b` is the raw computation return type,
  avoiding nesting.
- Unhandled effects are re-performed via `Effect.perform` so they propagate to
  any outer handler.
- The handler token `('i, 'o) Eff.Handler.t` is `unit` at runtime; callers
  receive and pass it through the abstract type without inspecting it.
