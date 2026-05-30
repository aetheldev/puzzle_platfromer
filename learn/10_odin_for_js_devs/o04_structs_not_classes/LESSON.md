# O04 — Structs, Not Classes

## Goal

Understand how Odin organizes data using structs instead of classes,
why there is no `this`, no inheritance, no methods, and why that is
actually better for game programming.

---

## If You Know JS/TS...

In JavaScript, you group data and behavior together using classes:

```js
class Player {
  constructor(x, y) {
    this.x = x;
    this.y = y;
    this.health = 100;
  }

  move(dx, dy) {
    this.x += dx;
    this.y += dy;
  }

  takeDamage(amount) {
    this.health -= amount;
    if (this.health <= 0) this.die();
  }

  die() {
    console.log("Player died at", this.x, this.y);
  }
}

const player = new Player(100, 200);
player.move(5, 0);
player.takeDamage(30);
```

This is the OOP (Object-Oriented Programming) model:
- Data and behavior live together in the class.
- `this` refers to the current instance.
- Inheritance lets you extend: `class Enemy extends Player { ... }`.
- The JS engine allocates the object on the heap, tracks it with GC.

You probably use this pattern a lot if you work with React class
components or TypeScript classes.

**Odin has none of this.** No classes, no `this`, no inheritance, no
method syntax, no `new`, no GC. And this is intentional.

---

## How Odin Does It

### Defining a struct

```odin
Player :: struct {
    x, y:     f32,
    health:   i32,
    is_alive: bool,
}
```

This defines a **type** called `Player`. It is a plain data container.
It has four fields. It has no methods, no constructor, no `this`.

Think of it as a TypeScript interface or type that is also the
runtime shape — not erased, not wrapped, not heap-allocated by default.

### Creating an instance

```odin
player := Player{
    x = 100,
    y = 200,
    health = 100,
    is_alive = true,
}
```

No `new`. No constructor. No heap allocation. This creates the struct
**on the stack** — it lives in the current function's memory frame and
is automatically cleaned up when the function exits.

Compare JS:
```js
const player = new Player(100, 200);  // heap allocation, GC tracked
```

Odin:
```odin
player := Player{ x = 100, y = 200, ... }  // stack allocation, free when scope ends
```

### Working with struct data

Since there are no methods, you write standalone procedures:

```odin
move_player :: proc(p: ^Player, dx, dy: f32) {
    p.x += dx
    p.y += dy
}

take_damage :: proc(p: ^Player, amount: i32) {
    p.health -= amount
    if p.health <= 0 {
        p.is_alive = false
    }
}
```

And call them explicitly:

```odin
move_player(&player, 5, 0)
take_damage(&player, 30)
```

Notice:
- `^Player` means "pointer to Player" (like a reference)
- `&player` means "take the address of player" (like creating a reference)
- You explicitly pass the player to the function
- There is no hidden `this`

---

## Deep Dive

### Value semantics — the single biggest trap for JS developers

In JavaScript, objects are always passed by reference:

```js
function reset(obj) {
  obj.x = 0;
  obj.y = 0;
}
const player = { x: 100, y: 200 };
reset(player);
console.log(player.x); // 0 — modified!
```

In Odin, **structs are passed by VALUE by default.** This means they
are COPIED when passed to a procedure:

```odin
// THIS IS A BUG — very common for JS developers
reset :: proc(p: Player) {    // p is a COPY of the original
    p.x = 0                    // modifies the copy
    p.y = 0                    // modifies the copy
}

player := Player{ x = 100, y = 200 }
reset(player)
fmt.println(player.x)  // 100 — NOT modified! The copy was modified.
```

To modify the original, you must pass a pointer:

```odin
// CORRECT
reset :: proc(p: ^Player) {   // p is a pointer to the original
    p.x = 0                    // modifies the original
    p.y = 0                    // modifies the original
}

player := Player{ x = 100, y = 200 }
reset(&player)               // & takes the address
fmt.println(player.x)  // 0 — modified!
```

This is the most important thing to understand in this lesson:
- **Without `^`: the proc gets a copy. Changes are lost.**
- **With `^` and `&`: the proc gets the real thing. Changes stick.**

In JS, you never think about this because objects are always references.
In Odin, you must choose explicitly. This catches a huge class of bugs
at compile time instead of letting them silently happen at runtime.

### Why no classes? Why no methods?

Game programming benefits from "data-oriented design":

1. **Separate data from behavior.** Struct = data shape. Procs = operations.
   This makes it easy to have the same data used by different systems
   (render system reads position, physics system updates position,
   AI system decides new position).

2. **No hidden state.** Every proc declares exactly what it reads and
   writes through its parameter list. In OOP, `player.move()` might
   secretly touch `this.health`, `this.inventory`, `this.questLog` —
   you cannot tell from the call site. In Odin, `move_player(&p, 5, 0)`
   clearly shows: this proc works on a Player, with dx=5, dy=0.

3. **No inheritance tax.** Class hierarchies (`Enemy extends Entity
   extends GameObject extends ...`) create complex call chains, virtual
   dispatch overhead, and "banana-gorilla-jungle" problems where you
   cannot grab one class without pulling in the entire hierarchy.
   Odin structs are flat. If you want shared fields, you use
   composition, not inheritance.

4. **Cache-friendly memory.** Arrays of structs pack tightly in memory.
   When you iterate over 10,000 entities, having their positions in a
   flat array means the CPU cache stays happy. Class instances scattered
   on the heap cause cache misses.

### Default values

Fields you do not initialize are zero-valued:

```odin
player := Player{}
// player.x = 0, player.y = 0, player.health = 0, player.is_alive = false
```

In JS, uninitialized properties are `undefined`. In Odin, everything
starts at zero. This is predictable and removes an entire class of
"undefined is not a function" errors.

### Assignment copies the entire struct

```odin
a := Player{ x = 100, y = 200, health = 100, is_alive = true }
b := a         // b is a COMPLETE COPY of a
b.x = 999     // only b changes
fmt.println(a.x)  // 100 — a is untouched
```

In JS:
```js
const a = { x: 100, y: 200 };
const b = a;       // b is a reference to the SAME object
b.x = 999;
console.log(a.x);  // 999 — a is modified too!
```

This is a fundamental difference. In Odin, `b := a` copies all bytes.
In JS, `const b = a` copies only the reference.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o04_structs_not_classes/main.odin`

Line refs:
- `Player` struct definition: lines 5-10
- `move_player` with pointer: lines 12-15
- `take_damage` with pointer: lines 17-22
- `print_player`: lines 24-26
- copy behavior demo: lines 30-39
- pointer mutation demo: lines 41-48
- zero-value demo: lines 50-53
- main: lines 55-83

After reading, close it.

---

## What Would Break If...

### You passed `Player` instead of `^Player` to a mutating proc?
The proc modifies a copy. The original is unchanged. This is the
most common struct bug for JS developers. No error — just wrong behavior.

### You wrote `player.move(5, 0)` (method syntax)?
```
Error: type 'Player' has no field 'move'
```
There are no methods. Write `move_player(&player, 5, 0)` instead.

### You forgot `&` when calling a proc that takes `^Player`?
```
Error: Cannot convert 'Player' to '^Player'
```
The `&` operator takes the address. Without it, you are passing a value,
not a pointer.

### You used `new Player(...)` like JS?
```
Error: Undeclared name: new
```
`new` exists in Odin but it is a different thing (allocates on heap).
For stack allocation, just use `Player{ ... }`.

---

## Common JS-Developer Mistakes

1. **Expecting struct assignment to share references.**
   `b := a` copies the whole struct in Odin. In JS, `const b = a`
   shares the reference. This is the #1 source of bugs for JS devs.

2. **Writing methods on structs.**
   There is no `Player.move()`. Write `move_player :: proc(...)`.

3. **Forgetting `^` for mutation.**
   If you want a proc to modify a struct, the param must be `^Player`
   and the caller must pass `&player`.

4. **Using `this` inside a proc.**
   There is no `this`. The struct is an explicit parameter.

5. **Expecting constructors.**
   There is no `constructor()`. Initialize with `Player{ field = value }`.
   If you want a factory function, write a proc that returns a Player:
   ```odin
   make_player :: proc(x, y: f32) -> Player {
       return Player{ x = x, y = y, health = 100, is_alive = true }
   }
   ```

---

## Mental Model

Think of a struct as a **form with labeled blank fields:**

```
┌─────────────────────┐
│ Player              │
│ x:     [  100.0  ]  │
│ y:     [  200.0  ]  │
│ health: [  100   ]  │
│ alive:  [  true  ]  │
└─────────────────────┘
```

When you write `b := a`, Odin **photocopies the entire form.** Two
separate pieces of paper. Changing one does not affect the other.

In JS, `const b = a` gives you **a second name tag pointing to the same
form.** Both names see the same data.

When you pass `^Player` (pointer), you are giving the proc the **address
of the original form.** The proc can write on it directly.

When you pass `Player` (value), you are giving the proc a **photocopy.**
The proc writes on the copy. The original stays clean.

---

## Exercises

### Exercise 1 — Define And Print
Create a `Vec2 :: struct { x, y: f32 }`.
Create an instance with `x = 3, y = 4`.
Print both fields.

### Exercise 2 — Write A Proc That Reads
Write `length :: proc(v: Vec2) -> f32` that returns the length of the
vector (hint: `sqrt(x*x + y*y)`, import `"core:math"`).
This proc does NOT need a pointer because it only reads, not writes.

### Exercise 3 — Write A Proc That Mutates
Write `scale :: proc(v: ^Vec2, factor: f32)` that multiplies both x and
y by factor. Call it with `&vec`. Print before and after.

### Exercise 4 — Prove Copy Behavior
Create `a := Vec2{ x = 10, y = 20 }`.
Create `b := a`.
Modify `b.x = 999`.
Print both `a.x` and `b.x`.
Write a comment explaining what happened and why.

---

## Exit Criteria

- [ ] You can define a struct type
- [ ] You can create instances with field initialization
- [ ] You can write procs that read structs (pass by value)
- [ ] You can write procs that modify structs (pass by pointer with `^` and `&`)
- [ ] You can explain why `b := a` copies the struct, not the reference
- [ ] You understand why Odin has no classes, methods, or `this`

---

## Why This Matters For Game Dev

Every game entity — player, enemy, box, particle, tile, card — is a
struct. Every frame, procedures read and modify those structs.

When you later see in `sauce/entity.odin`:
```odin
Entity :: struct {
    kind:       Entity_Kind,
    pos:        Vec2,
    sprite:     Sprite_Name,
    ...
}
```

You will know: this is just a data container. Procedures in `game.odin`
read and modify it. There is no hidden behavior, no constructor magic,
no inheritance chain. Just data and functions that work on data.

This is the data-oriented style that makes game code fast and readable.

---

## Next Lesson

`learn/10_odin_for_js_devs/o05_enums_and_switches`
