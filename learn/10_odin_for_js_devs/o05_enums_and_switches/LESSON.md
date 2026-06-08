# O05 — Enums And Switches

## Goal

Understand how Odin enums work, why `switch` is exhaustive by default,
and how this pattern drives game state, tile types, entity kinds, and
card colors throughout your future game code.

---

## If You Know JS/TS...

In plain JavaScript, there are no real enums. People fake them:

```js
const Direction = {
  UP: 0,
  DOWN: 1,
  LEFT: 2,
  RIGHT: 3,
};
// But nothing stops you from writing: Direction.UP = 99;
// Or passing any random number where a direction is expected.
```

TypeScript added enums:

```ts
enum Direction {
  Up,
  Down,
  Left,
  Right,
}

function move(dir: Direction) {
  switch (dir) {
    case Direction.Up:    /* ... */ break;
    case Direction.Down:  /* ... */ break;
    // Forgot Left and Right? TS won't complain by default.
  }
}
```

TS enums are better but still have issues:
- They compile to objects at runtime.
- Switch is NOT exhaustive — you can forget cases silently.
- Numeric enums allow any number, even invalid ones.

---

## How Odin Does It

### Defining an enum

```odin
Direction :: enum {
    up,
    down,
    left,
    right,
}
```

This creates a type `Direction` with exactly four values. Nothing else.
You cannot assign `5` to a Direction variable. The compiler rejects it.

### Using enums in switch

```odin
move :: proc(dir: Direction) {
    switch dir {
    case .up:    fmt.println("moving up")
    case .down:  fmt.println("moving down")
    case .left:  fmt.println("moving left")
    case .right: fmt.println("moving right")
    }
}
```

**Key difference from JS/TS:** this switch is **exhaustive by default.**
If you forget a case, the compiler gives you an error:

```
Error: Unhandled switch cases: .left, .right
```

This is a massive safety feature. In a game, forgetting to handle a
tile type, entity kind, or game state leads to subtle bugs that are hard
to find at runtime. Odin catches them at compile time.

### `#partial switch` — opt-out of exhaustiveness

Sometimes you only care about some cases. Use `#partial switch`:

```odin
#partial switch dir {
case .up:   fmt.println("going up")
case .down: fmt.println("going down")
// left and right intentionally ignored — no compiler error
}
```

You will see `#partial switch` a lot in game code, especially for
input handling where you only care about a few keys.

### Enum values in `.dot` syntax

Notice the `.up` syntax in switch cases. This is called an **implicit
selector** — Odin knows the type is `Direction`, so you write `.up`
instead of `Direction.up`. Both work, but `.up` is shorter and idiomatic.

---

## Deep Dive

### Why enums are everywhere in game code

Games are full of discrete states:

```odin
Game_Mode :: enum { menu, playing, paused, game_over }
Tile_Kind :: enum { empty, wall, goal, spike, door }
Entity_Kind :: enum { player, enemy, box, particle }
Card_Color :: enum { red, blue, green, yellow }
Turn_Phase :: enum { choose_card, resolve, draw_if_blocked, end_turn }
```

Each of these is a finite set of possibilities. Enums make the set
explicit. The compiler ensures you handle every case. This is
dramatically safer than using strings or arbitrary numbers.

In JS, you might write:
```js
if (tile === "wall") { ... }
else if (tile === "goall") { ... }  // typo! silent bug!
```

In Odin:
```odin
switch tile {
case .wall: { ... }
case .goall: { ... }  // ERROR: .goall is not a member of Tile_Kind
}
```

The compiler catches the typo immediately.

### Enums have underlying integer values

```odin
Direction :: enum {
    up,     // 0
    down,   // 1
    left,   // 2
    right,  // 3
}
```

By default, values start at 0 and increment. You can specify the
underlying type:

```odin
Tile_Kind :: enum u8 {
    empty,
    wall,
    goal,
}
```

`enum u8` means each value is stored as a single byte. This matters for
memory when you have arrays of thousands of tiles:
- `enum u8` = 1 byte per tile
- `enum i32` = 4 bytes per tile (default)
- For a 100x100 tilemap: 10KB vs 40KB

### Enum iteration

You can loop over all enum values:

```odin
for color in Card_Color {
    fmt.println(color)
}
```

This prints: `red`, `blue`, `green`, `yellow`.

In JS, you would need `Object.values(CardColor)`. In Odin, enums are
directly iterable.

### Combining enums with structs

This is a very common game pattern:

```odin
Entity_Kind :: enum { player, enemy, box }

Entity :: struct {
    kind: Entity_Kind,
    x, y: f32,
    health: i32,
}

update_entity :: proc(e: ^Entity) {
    switch e.kind {
    case .player: // player-specific logic
    case .enemy:  // enemy-specific logic
    case .box:    // box-specific logic
    }
}
```

The struct holds the data. The enum tells you what kind of entity it is.
The switch branches on the kind. Add a new kind → the compiler forces you
to handle it everywhere. This is one of the strongest patterns in
game programming.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o05_enums_and_switches/main.odin`

Line refs:
- `Direction` enum: lines 5-10
- exhaustive switch: lines 12-19
- `Tile_Kind` with `u8`: lines 21-26
- iteration: lines 28-31
- `Game_State` enum: lines 33-38
- nested struct + enum: lines 40-60
- main: lines 62-95

---

## What Would Break If...

### You forgot a case in a non-partial switch?
```
Error: Unhandled switch cases: .left, .right
```
The compiler forces you to handle every case. This is intentional.

### You wrote `switch dir { case "up": ... }` (string instead of enum)?
```
Error: Cannot compare Direction with string
```
Enum values are not strings. They are typed constants.

### You tried to assign an arbitrary integer to an enum variable?
```odin
dir : Direction = 99  // ERROR: 99 is not a valid Direction
```
Odin enums are strict. Only declared values are allowed.

### You wrote `case Direction.up` instead of `case .up`?
Both work. `case .up` is shorter and preferred when the type is obvious
from context (inside a switch on a Direction variable).

---

## Common JS-Developer Mistakes

1. **Using strings instead of enums.**
   In JS you might write `tile === "wall"`. In Odin, define an enum
   and use `tile == .wall`. Type-safe, no typos.

2. **Forgetting `#partial` when you only handle some cases.**
   Regular switch must be exhaustive. Use `#partial switch` if you
   intentionally skip cases.

3. **Expecting enum to be an object.**
   TS enums compile to JS objects. Odin enums are compile-time constants
   with integer backing. No runtime object.

4. **Expecting `.toString()` or string conversion.**
   Use `fmt.println(my_enum_value)` — fmt knows how to print enum names.
   There is no `.toString()` method.

5. **Forgetting `break` — actually, you do not need it.**
   In JS, switch cases fall through without `break`. In Odin, cases
   do NOT fall through. Each case is isolated. No `break` needed.
   This eliminates an entire class of JS switch bugs.

---

## Mental Model

Think of an enum as a **list of valid ID badges:**

```
┌──────────────────┐
│ Direction        │
│ [0] up           │
│ [1] down         │
│ [2] left         │
│ [3] right        │
│ --- end ---      │
└──────────────────┘
```

Only people with valid badges can enter. If you try to enter with
badge number 99, security (the compiler) stops you.

A switch on an enum is like a **checkpoint that must verify every
possible badge type.** If you add a new badge (new enum value) and
forget to update the checkpoint, the compiler tells you.

---

## Exercises

### Exercise 1 — Traffic Light
Define `Traffic_Light :: enum { red, yellow, green }`.
Write a proc that takes a Traffic_Light and prints the appropriate
action ("stop", "caution", "go"). Use exhaustive switch.

### Exercise 2 — Card Suit
Define `Suit :: enum { hearts, diamonds, clubs, spades }`.
Loop over all values and print each one.

### Exercise 3 — Tile Grid
Define `Tile :: enum u8 { empty, wall, spike }`.
Create a small `[3][3]Tile` grid. Set some values.
Loop over the grid and print a character for each tile.

### Exercise 4 — Add A New Case
Take your Traffic_Light and add `flashing_red`.
Observe the compiler errors in your switch.
Fix them. This demonstrates why exhaustive switch is powerful.

---

## Exit Criteria

- [x] You can define enums with named values
- [x] You can switch on enums exhaustively
- [x] You can use `#partial switch` when appropriate
- [x] You can explain why enums are safer than strings or magic numbers
- [x] You can iterate over enum values
- [x] You understand `enum u8` for memory efficiency

---

## Why This Matters For Game Dev

You will define enums for:
- tile types in Sokoban
- card colors in the card game
- player roles in co-op
- entity kinds in your game engine
- game states and turn phases

Every time you add a new kind of tile or entity, exhaustive switch
forces you to handle it everywhere. This prevents the "I added a new
enemy type but forgot to handle it in the collision system" bug that
plagues JS game code.

---

## Next Lesson

`learn/10_odin_for_js_devs/o06_arrays_slices_dynamic`
