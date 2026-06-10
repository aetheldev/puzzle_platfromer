# O18 — Unions And Variants

## Goal

Understand Odin's tagged `union` type: a value that can be exactly one
of several types at a time. Learn type switches, `.( )` assertions, and
why unions drive event systems, entity variants, and ability systems in
idiomatic Odin game code.

---

## If You Know JS/TS...

In TypeScript, you model "one of several shapes" with union types and
a discriminant field:

```ts
type GameEvent =
  | { kind: "damage"; amount: number; target: string }
  | { kind: "pickup"; item: string }
  | { kind: "level_complete"; timeSeconds: number };

function handle(e: GameEvent) {
  switch (e.kind) {
    case "damage":
      console.log(`${e.target} takes ${e.amount}`);
      break;
    case "pickup":
      console.log(`got ${e.item}`);
      break;
    case "level_complete":
      console.log(`done in ${e.timeSeconds}s`);
      break;
  }
}
```

TS narrows the type inside each `case`. Nice — but it is all erased at
runtime. The `kind` string is your own convention; nothing stops a
malformed object at runtime.

Odin has this concept **built into the language**, with a real runtime
tag and real memory layout: the tagged `union`.

---

## How Odin Does It

### Defining a union

```odin
Damage_Event :: struct {
    amount: int,
    target: string,
}

Pickup_Event :: struct {
    item: string,
}

Level_Complete_Event :: struct {
    time_seconds: f32,
}

Game_Event :: union {
    Damage_Event,
    Pickup_Event,
    Level_Complete_Event,
}
```

A `Game_Event` value holds **one** of those three structs at a time —
plus a hidden tag saying which one. Memory = size of the biggest
variant + the tag. No heap allocation, no inheritance.

### Creating a union value

```odin
e: Game_Event = Damage_Event{ amount = 10, target = "player" }
```

Just assign one of the variant types. The tag is set automatically.

### The type switch — the heart of unions

```odin
handle :: proc(event: Game_Event) {
    switch e in event {
    case Damage_Event:
        fmt.println(e.target, "takes", e.amount)
    case Pickup_Event:
        fmt.println("got", e.item)
    case Level_Complete_Event:
        fmt.println("done in", e.time_seconds, "s")
    case:
        // nil case — union holds nothing
        fmt.println("empty event")
    }
}
```

Notes:
- `switch e in event` — `e` is the unwrapped value, correctly typed
  inside each case. Same idea as TS narrowing, but enforced by compiler.
- Like enum switches (o05), union type switches are **exhaustive**:
  forget a variant and the compiler errors.
- The bare `case:` handles `nil` — a union with no value assigned.

### Type assertion — when you already know

```odin
dmg, ok := event.(Damage_Event)
if ok {
    fmt.println("damage:", dmg.amount)
}
```

Like the `(value, ok)` pattern (o11, o17). The panicking version
`dmg := event.(Damage_Event)` crashes if the tag is wrong — use only
when you are certain.

### Unions are nil by default

```odin
e: Game_Event        // nil — holds nothing
if e == nil {
    fmt.println("no event")
}
```

---

## Deep Dive

### Memory layout — why unions beat class hierarchies

In JS/TS, each event object is a separate heap allocation with hidden
class info. In Odin:

```
Game_Event memory:
┌────────────────────────────┬─────┐
│ space for BIGGEST variant  │ tag │
└────────────────────────────┴─────┘
```

`size_of(Game_Event)` = biggest variant + tag. You can pack thousands
of events in a flat dynamic array — one allocation, cache-friendly:

```odin
events: [dynamic]Game_Event
append(&events, Damage_Event{ amount = 5, target = "boss" })
append(&events, Pickup_Event{ item = "key" })
```

This is THE idiomatic event queue in Odin games. Compare to JS where
an event array is an array of pointers to scattered heap objects.

### Union vs enum + struct megastruct — two valid styles

You already saw the megastruct style in this repo (`sauce/entity.odin`):

```odin
// megastruct style (sauce uses this)
Entity :: struct {
    kind: Entity_Kind,    // enum tag
    pos: Vec2,
    health: i32,          // used by player, enemy
    push_dir: Vec2,       // only used by box
    // ... every field any entity might need
}
```

versus union style:

```odin
// union style
Entity_Data :: union {
    Player_Data,
    Enemy_Data,
    Box_Data,
}
Entity :: struct {
    pos: Vec2,            // shared fields stay in struct
    data: Entity_Data,    // variant fields go in union
}
```

Trade-offs:

| | megastruct | union |
|---|---|---|
| Memory | wastes unused fields | tight (biggest variant) |
| Access | `e.health` always works | must unwrap with switch |
| Adding kinds | add fields, easy | add variant + handle all switches |
| Compiler safety | none — you can read box fields on a player | tag-checked |

The repo's README links Randy's "entity megastruct" article — that
style favors iteration speed for gameplay slop. Unions favor type
safety. **Events, messages, commands, abilities = unions. Entities in
this codebase = megastruct.** Know both; pick per problem.

### `Maybe(T)` — the tiny union you get for free

Odin's standard "optional" is literally a union:

```odin
Maybe :: union($T: typeid) { T }
```

Usage:

```odin
target: Maybe(int)        // nil = no target
target = 42

if id, ok := target.?; ok {
    fmt.println("targeting", id)
}
```

`.?` is shorthand assertion for Maybe. This replaces TS's
`number | undefined`.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o18_unions_and_variants/main.odin`

Line refs:
- event structs + union definition: lines 5-22
- handle proc with type switch: lines 24-36
- creating events + nil check: lines 38-49
- event queue in dynamic array: lines 51-61
- type assertion with ok: lines 63-68
- Maybe(T) demo: lines 70-78
- size_of demo: lines 80-84

After reading, close it.

---

## What Would Break If...

### You forgot a variant in the type switch?
```
Error: Unhandled union cases: Pickup_Event
```
Exhaustive, like enum switches. The compiler hunts down every switch
when you add a new event type — this is a feature, not a chore.

### You asserted the wrong type without `ok`?
```
runtime panic: Invalid type_assertion from Game_Event to Pickup_Event
```
Use `v, ok := e.(T)` when unsure. Bare `e.(T)` is a confident crash.

### You read a field without unwrapping?
```
Error: Game_Event has no field 'amount'
```
The union is a sealed box. Type switch or assertion opens it.

### You switched on the union but used `event` inside, not `e`?
`event` stays the sealed union inside cases. Only the capture `e`
(from `switch e in event`) is unwrapped and typed.

---

## Common JS-Developer Mistakes

1. **Adding your own `kind` discriminant field.**
   The union's tag IS the discriminant. No `kind: string` needed.

2. **Expecting structural narrowing.**
   TS narrows by analyzing your `if`s. Odin narrows ONLY in
   `switch e in` cases and `.( )` assertions.

3. **Reaching for inheritance.**
   "Enemy extends Entity" thinking. Odin: shared fields in struct,
   variant fields in union (composition), or megastruct.

4. **Heap-allocating each variant.**
   No `new` needed. Unions are values — stack them, array them.

5. **Forgetting unions start nil.**
   Declared-but-unassigned union = nil. The bare `case:` in a type
   switch catches it.

---

## Mental Model

A union is a **shape-shifting box with a label on the side:**

```
┌──────────────────────────────┐
│ label: Damage_Event          │
│ contents: {amount=10,        │
│            target="player"}  │
└──────────────────────────────┘
```

The box is always the same size (fits the biggest shape). The label
always tells the truth — the compiler updates it on every assignment,
and forces you to read the label (type switch) before touching the
contents.

TS unions are labels the compiler *imagines* and then erases.
Odin unions are labels that *exist in memory* at runtime.

---

## Exercises

### Exercise 1 — Define An Event Union
Define three event structs: `Jump_Event { height: f32 }`,
`Coin_Event { value: int }`, `Death_Event { cause: string }`.
Wrap them in `Game_Event :: union`. Create one of each and print them
with `fmt.println` (printing a union shows its current variant).

### Exercise 2 — Type Switch Handler
Write `handle :: proc(e: Game_Event)` with an exhaustive type switch
that prints a different message per variant plus a `case:` for nil.
Call it with all three events AND a nil event.

### Exercise 3 — Event Queue
Create `events: [dynamic]Game_Event` (defer delete!). Append 4 mixed
events. Loop and handle each. Count how many were `Coin_Event` and
print total coin value collected.

### Exercise 4 — Break The Switch
Add a 4th variant `Checkpoint_Event { id: int }` to the union. Build.
Read the compiler error listing your unhandled switch. Fix it.
(Same exhaustiveness drill as o05 Exercise 4 — now with types.)

---

## Exit Criteria

- [ ] You can define a union of several struct variants
- [ ] You can write an exhaustive type switch with `switch e in`
- [ ] You can use `v, ok := e.(T)` assertion safely
- [ ] You can explain the memory layout (biggest variant + tag)
- [ ] You can explain when to choose union vs entity megastruct
- [ ] You know unions start nil and how to handle it

---

## Why This Matters For Game Dev

Unions are how Odin games model "one of several things":

```odin
// damage/heal/status messages between systems
Combat_Msg :: union { Damage, Heal, Stun }

// co-op network packets (your future Ticket 075/076!)
Net_Packet :: union { Player_Intent, Room_Join, Ping }

// ability targeting
Target :: union { Entity_Id, Grid_Pos, Direction }
```

Your co-op game's `Player_Intent` networking path (Ticket 075) will
serialize exactly this kind of variant data. And when you read
`sauce/entity.odin`'s megastruct, you will now understand the
trade-off it made — and when you would make a different one.

---

## Next Lesson

`learn/10_odin_for_js_devs/o19_bit_sets_and_flags`
