# O19 — Bit Sets And Flags

## Goal

Understand Odin's `bit_set` type: a set of enum values stored as bits
in a single integer. Learn add/remove/test/combine operations, and why
bit_sets are the idiomatic way to store flags, ability states, input
state, and puzzle progress in Odin games.

---

## If You Know JS/TS...

In JS, when something has multiple on/off flags, you usually write:

```js
// object of booleans
const player = {
  isGrounded: true,
  isWallSliding: false,
  hasDoubleJump: true,
  hasDash: false,
};

// or a Set of strings
const abilities = new Set(["double_jump"]);
abilities.add("dash");
abilities.has("dash");      // true
abilities.delete("dash");
```

Or, if you have C heritage, manual bit twiddling:

```js
const GROUNDED = 1 << 0;
const WALL_SLIDE = 1 << 1;
let flags = 0;
flags |= GROUNDED;           // set
flags & GROUNDED             // test — easy to typo, no type safety
```

JS gives you a choice between readable-but-heavy (objects, Sets) and
fast-but-dangerous (manual bitmasks).

Odin's `bit_set` is **both**: reads like a Set, compiles to a single
integer with bitwise ops. Type-checked by the compiler.

---

## How Odin Does It

### Defining a bit_set

```odin
Ability :: enum {
    double_jump,
    dash,
    wall_climb,
    glide,
}

Ability_Set :: bit_set[Ability]
```

`Ability_Set` stores any combination of `Ability` values — as single
bits inside one integer. 4 enum values = 4 bits used.

### Creating and adding

```odin
abilities: Ability_Set                  // empty set
abilities = {.double_jump}              // set literal
abilities += {.dash}                    // add one
abilities += {.wall_climb, .glide}     // add several
```

### Removing

```odin
abilities -= {.dash}
```

### Testing membership

```odin
if .double_jump in abilities {
    fmt.println("can double jump")
}

if .dash not_in abilities {
    fmt.println("no dash yet")
}
```

Same `in` keyword as maps (o17). Reads like English.

### Set operations

```odin
a := Ability_Set{.dash, .glide}
b := Ability_Set{.glide, .wall_climb}

union_set := a + b        // {.dash, .glide, .wall_climb}
common   := a & b         // {.glide}
diff     := a - b         // {.dash}
```

JS `Set` only recently got union/intersection methods. Odin bit_sets
have had them as single CPU instructions all along.

### Counting and clearing

```odin
count := card(abilities)   // cardinality — how many flags set
abilities = {}             // clear all
```

---

## Deep Dive

### Memory — this is the whole point

```odin
// JS-style struct of bools:
Player_Flags_Bools :: struct {
    is_grounded:     bool,   // 1 byte
    is_wall_sliding: bool,   // 1 byte
    is_dashing:      bool,   // 1 byte
    is_invincible:   bool,   // 1 byte
}
// = 4 bytes, grows by 1 byte per flag

// bit_set:
Player_Flag :: enum { grounded, wall_sliding, dashing, invincible }
Player_Flags :: bit_set[Player_Flag]
// = 1 byte total. 8 flags fit. 64 flags = 8 bytes.
```

For one player, who cares. For 10,000 entities × checked every frame,
bit_sets keep your struct small and your cache hot (o08 thinking).

You can control the backing integer explicitly:

```odin
Player_Flags :: bit_set[Player_Flag; u8]   // exactly 1 byte
```

This matters for serialization — your co-op network packets (Ticket
075/076) can send a whole flag state as one byte.

### bit_set vs [Enum]bool vs map — choosing

| Container | Memory | Use when |
|---|---|---|
| `bit_set[Enum]` | bits | on/off flags, ≤ 128 enum values |
| `[Enum]bool` | 1 byte per value | same idea, simpler, slightly bigger |
| `map[Enum]bool` | heap, hashing | almost never — wrong tool |
| struct of bools | 1 byte each | 2-3 unrelated flags, max readability |

Rule: many related on/off states keyed by enum → `bit_set`.

### Real usage in this repo

The co-op design doc (`learn/80_design/coop_lovers_puzzle/README.md`)
already uses one for puzzle progress:

```odin
levers_pulled: bit_set[Lever; u8]
```

8 levers, one byte, network-friendly. And input handling commonly looks
like:

```odin
Input_Action :: enum { left, right, jump, interact }
Input_State :: bit_set[Input_Action]

held: Input_State
if key_down(.A) { held += {.left} }
if .jump in held { try_jump() }
```

This is also exactly the shape of `Player_Intent` from Ticket 075 —
two players' intents per frame, each a few bits, trivially
serializable for networking.

### Checking multiple flags at once

```odin
// does the player have ALL of these?
required := Ability_Set{.dash, .wall_climb}
if required <= abilities {       // subset test
    fmt.println("can do the advanced route")
}

// does the player have ANY of these?
if abilities & {.dash, .glide} != {} {
    fmt.println("has some movement tech")
}
```

`<=` is the subset operator. Try writing "has all of these abilities"
with a JS object of bools — it is a `&&` chain that grows forever.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o19_bit_sets_and_flags/main.odin`

Line refs:
- enum + bit_set definition: lines 5-12
- add/remove/test: lines 15-30
- set operations (+ & -): lines 32-39
- card and clear: lines 41-44
- subset and any-of checks: lines 46-53
- input state demo: lines 55-77
- memory size demo: lines 79-82

After reading, close it.

---

## What Would Break If...

### You added a value from a different enum?
```
Error: 'Tile_Kind' is not a member of 'bit_set[Ability]'
```
Type-checked. Manual `1 << 3` bitmasks in C/JS never catch this.

### You used `==` to test membership?
```odin
if abilities == .dash { }   // Error: cannot compare bit_set with Ability
```
Membership is `in`, not `==`. `==` compares whole sets.

### You wrote `abilities += .dash` (no braces)?
```
Error: ... (mismatched types)
```
Add/remove takes a SET, even of one element: `+= {.dash}`.

### Your enum grew past the backing type?
```odin
Big :: enum { a, b, ... 9 values ... }
S :: bit_set[Big; u8]   // Error: bit_set range is greater than 8 bits
```
8 flags per byte. The compiler counts for you.

---

## Common JS-Developer Mistakes

1. **Struct of booleans for related flags.**
   Works, but bloats entity structs and cannot be combined/compared
   in one operation. Related flags keyed by enum → bit_set.

2. **Forgetting braces in `+=`/`-=`.**
   Operations are set-with-set: `flags += {.dash}`, not `+= .dash`.

3. **Using `map[Enum]bool`.**
   Heap allocation and hashing for something that fits in one byte.

4. **Testing with `&` then comparing to a flag (C habit).**
   Odin reads better: `.dash in flags`. Use `&` only for set algebra.

5. **Not specifying backing type for serialized data.**
   For network/save data, pin the size: `bit_set[Flag; u8]`.
   Default backing may differ from what your protocol expects.

---

## Mental Model

A bit_set is a **row of labeled light switches on one panel:**

```
Ability panel (1 byte):
┌─────────┬──────┬────────────┬───────┐
│ dbl_jump│ dash │ wall_climb │ glide │
│   ON    │ OFF  │     ON     │  OFF  │
└─────────┴──────┴────────────┴───────┘
```

- `+= {.dash}` — flip a switch on
- `.dash in s` — glance at one switch
- `a & b` — hold two panels together, see which switches are on in both
- `a <= b` — is every switch that is on in panel a also on in panel b?

The whole panel is one integer. Every operation is one CPU instruction.
A JS object of booleans is a filing cabinet; this is a light panel.

---

## Exercises

### Exercise 1 — Ability Unlocks
Define `Ability :: enum { double_jump, dash, wall_climb, glide }` and
`Ability_Set :: bit_set[Ability]`. Start empty. Unlock `double_jump`,
then `dash`. Print the set. Check `in` for one you have and one you
do not have.

### Exercise 2 — Lever Puzzle
Define `Lever :: enum { l1, l2, l3, l4 }`. The door opens when
`pulled == {.l1, .l3}` (exactly these two). Pull levers one at a time,
printing whether the door is open after each pull — including a state
where pulling a WRONG lever keeps it closed.

### Exercise 3 — Input Frame
Define `Input_Action :: enum { left, right, jump }` and a bit_set for
it. Simulate 3 frames: frame 1 = `{.right}`, frame 2 =
`{.right, .jump}`, frame 3 = `{}`. For each frame print "moving",
"jumping" based on membership tests.

### Exercise 4 — Set Algebra
`unlocked := {.double_jump, .dash}`, route needs
`required := {.dash, .wall_climb}`. Print: which required abilities
you have (`&`), which are missing (`required - unlocked`), and whether
you can take the route (`required <= unlocked`). Then unlock the
missing one and re-test.

---

## Exit Criteria

- [ ] You can define a bit_set over an enum
- [ ] You can add/remove with `+= {}`/`-= {}` and test with `in`
- [ ] You can use set algebra: `+`, `&`, `-`, `<=`, `card()`
- [ ] You can explain why bit_set beats a struct of bools for many flags
- [ ] You can pin the backing type (`; u8`) and say why it matters for networking
- [ ] You can choose between bit_set, `[Enum]bool`, and plain bools

---

## Why This Matters For Game Dev

Flags are everywhere in games, and your co-op puzzle game specifically:

```odin
// puzzle progress — the design doc already uses this
levers_pulled: bit_set[Lever; u8]

// player state per frame
state: bit_set[Player_State]     // grounded, sliding, dashing...

// input intent for networking (Ticket 075)
Player_Intent :: struct {
    actions: bit_set[Input_Action; u8],   // one byte over the wire
    move_x:  f32,
}

// which players stand on which pressure plates
plates_active: bit_set[Plate; u8]
```

When you reach Ticket 075 (network-ready input), the entire per-frame
button state of a player becomes one byte. Serializing it is a memcpy.
That is why this lesson exists.

---

## Next Lesson

Language track complete. Next:
`learn/20_game_thinking_for_web_devs/g01_game_loop_vs_react`
