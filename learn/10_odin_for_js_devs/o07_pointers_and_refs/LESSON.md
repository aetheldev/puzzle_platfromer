# O07 — Pointers And References

## Goal

Understand what pointers are, why they exist, how `^` and `&` work,
and why this concept does not exist in JavaScript at all.

---

## If You Know JS/TS...

JavaScript hides memory addresses from you completely.

When you write:
```js
const player = { x: 100, y: 200 };
```

The engine allocates memory on the heap, stores the object there, and
gives you a reference (a hidden pointer). You never see the address.
You never think about "where in memory does this live?"

When you pass that object to a function:
```js
function move(p) {
  p.x += 5;  // modifies the original
}
move(player);
console.log(player.x); // 105
```

It works because `p` is a reference to the same object. But you did not
ask for a reference — JS gave you one automatically.

**In Odin, you must choose explicitly:**
- Pass by value (copy) — default
- Pass by pointer (reference) — you ask for it with `^` and `&`

---

## How Odin Does It

### The operators

| Syntax | Meaning | English |
|--------|---------|---------|
| `^T` | pointer to T | "a variable that holds the memory address of a T" |
| `&x` | address of x | "give me the memory address where x lives" |
| `p^` | dereference p | "give me the value at the address p holds" (rarely needed explicitly) |

### Example

```odin
Player :: struct { x, y: f32 }

// This proc COPIES the player — changes are lost
reset_copy :: proc(p: Player) {
    p.x = 0    // modifies the COPY, not the original
}

// This proc takes a POINTER — changes stick
reset_real :: proc(p: ^Player) {
    p.x = 0    // modifies the ORIGINAL through the pointer
}

main :: proc() {
    player := Player{ x = 100, y = 200 }

    reset_copy(player)
    fmt.println(player.x)  // 100 — unchanged!

    reset_real(&player)     // & = "address of"
    fmt.println(player.x)  // 0 — changed!
}
```

---

## Deep Dive

### What is a pointer, physically?

A pointer is a number. Specifically, it is a memory address — like a
house number on a street.

```
Memory:
Address   Value
0x1000    Player{ x=100, y=200 }
0x2000    (something else)
0x3000    (something else)
```

When you write `p: ^Player = &player`, `p` holds the value `0x1000`.
It does not hold the player data itself — it holds the address where
the player data lives.

When you write `p.x = 0`, Odin follows the address to the player data
and modifies it there.

In JavaScript, every object variable is secretly a pointer. You just
never see the address or think about it. Odin makes this explicit.

### Why does Odin default to copying?

Safety and predictability.

If everything is passed by pointer (like JS objects), any function
can modify your data unexpectedly:

```js
// JS — any function that receives your object can mutate it
function maybeDangerous(player) {
  player.health = 0;  // surprise!
}
```

In Odin, if a proc takes `Player` (not `^Player`), it physically
cannot modify your data. It gets a copy. This is a guarantee:

```odin
// Cannot possibly modify original — it is a copy
read_player :: proc(p: Player) {
    // p.x = 999  ← would modify the copy, not the original
    fmt.println(p.x)
}
```

When a proc takes `^Player`, the signature tells you: "this proc might
modify the player." The call site also tells you: `reset(&player)` — the
`&` signals "I am giving my data's address, modifications will stick."

This is self-documenting code. You can tell from the call site whether
your data might change.

### `nil` — the null pointer

Pointers can be `nil` (like `null` in JS):

```odin
p: ^Player = nil   // points to nothing

// Accessing nil pointer = crash (panic)
p.x = 5  // RUNTIME PANIC: nil pointer dereference
```

In JS, `null.x` throws `TypeError`. In Odin, `nil` pointer access
crashes the program immediately with a clear error. There is no
optional chaining (`?.`) — you must check for nil yourself:

```odin
if p != nil {
    p.x = 5
}
```

### Auto-dereferencing

Odin automatically dereferences pointers when accessing struct fields:

```odin
p: ^Player = &player
p.x = 5      // automatically dereferences — same as p^.x = 5
```

You almost never need to write `p^` (explicit dereference). Odin does
it for you when you use `.field` on a pointer. This is a convenience
that makes pointer code read almost like value code.

### Pointers to array elements

```odin
enemies: [10]Entity
first := &enemies[0]   // pointer to first enemy
first.health = 50      // modifies enemies[0] directly
```

This is how game code often works: find the entity you need, get a
pointer to it, modify it. No copying large structs around.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o07_pointers_and_refs/main.odin`

Line refs:
- Vec2 struct and procs: lines 5-20
- copy vs pointer demo: lines 22-40
- nil pointer section: lines 42-53
- array element pointer: lines 55-68
- main: lines 70-end

---

## What Would Break If...

### You passed `Player` to a proc expecting `^Player`?
```
Error: Cannot convert 'Player' to '^Player'
```
You need `&player` to get the address.

### You forgot `&` when calling a pointer-taking proc?
```
Error: Expected '^Player', got 'Player'
```
The `&` is required at the call site.

### You dereferenced a nil pointer?
```
Runtime panic: Nil pointer dereference
```
The program crashes immediately. Always check for nil if a pointer
might be unset.

### You tried `p->x` (C-style arrow syntax)?
```
Error: Unexpected token ->
```
Odin uses `p.x` for pointer field access (auto-dereferenced). There is
no `->` operator.

---

## Common JS-Developer Mistakes

1. **Forgetting that structs copy by default.**
   The #1 pointer-related bug. If your proc changes a struct and the
   caller does not see the change, check: is the parameter `Player` or
   `^Player`?

2. **Thinking every variable is already a reference.**
   In JS, objects are always references. In Odin, structs are values by
   default. You must explicitly use `^` and `&` for reference behavior.

3. **Not understanding `nil`.**
   There is no `undefined` in Odin. Unset pointers are `nil`. Accessing
   nil crashes. Always check if a pointer might be nil.

4. **Trying to use optional chaining (`?.`).**
   Does not exist. Write `if p != nil { ... }`.

5. **Over-using pointers.**
   Not everything needs a pointer. Small structs (Vec2, Color) are
   fine to copy. Use pointers when you need mutation or when copying
   would be wasteful (large structs, arrays).

---

## Mental Model

Think of pointers like **home addresses:**

- `player: Player` — you have a player in your house.
- `p: ^Player = &player` — you write down your home address on a card.
- Passing `Player` to a proc — you send a photocopy of the player.
  The proc can scribble on the copy. Your original is safe.
- Passing `^Player` (the address card) — you give someone your address.
  They can come to your house and rearrange the furniture.

`nil` is an address card that says "nowhere." If someone tries to visit
that address, they crash into a wall.

---

## Exercises

### Exercise 1 — Prove The Copy
Create a `Vec2` struct. Write `double :: proc(v: Vec2)` that doubles
both components. Call it. Print the original. Observe it is unchanged.

### Exercise 2 — Fix With Pointer
Rewrite `double` as `double :: proc(v: ^Vec2)`. Call with `&vec`.
Print the original. Observe it changed.

### Exercise 3 — Nil Safety
Create `p: ^Vec2 = nil`. Write an if-check that prints "nil!" if p is
nil, or prints the value if it is not.

### Exercise 4 — Array Element Pointer
Create `[3]Vec2`. Get a pointer to element 1. Modify it through the
pointer. Print all three to show only element 1 changed.

---

## Exit Criteria

- [x] You can explain what a pointer is (memory address)
- [x] You can use `^T` in proc parameters for mutation
- [x] You can use `&x` to pass addresses
- [x] You understand why Odin defaults to copying
- [x] You can check for nil pointers
- [x] You know when to use pointers vs values

---

## Why This Matters For Game Dev

Every game entity update takes `^Entity` — a pointer to the entity
being updated. Every collision resolver modifies positions through
pointers. Every game system that modifies state does so through explicit
pointer parameters.

Understanding pointers is not optional for game dev. It is the
mechanism by which game state changes happen.

---

## Next Lesson

`learn/10_odin_for_js_devs/o08_memory_without_gc`
