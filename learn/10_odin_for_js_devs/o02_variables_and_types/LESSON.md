# O02 — Variables And Types

## Goal

Understand how Odin declares variables and why it has many numeric types
instead of just one `number` like JavaScript.

---

## If You Know JS/TS...

In JavaScript, you have three ways to declare variables:

```js
var x = 10;    // old, function-scoped, avoid
let y = 20;    // block-scoped, reassignable
const z = 30;  // block-scoped, not reassignable
```

And there is essentially ONE number type:

```js
typeof 42       // "number"
typeof 3.14     // "number"
typeof -7       // "number"
```

JavaScript does not distinguish between integers and floats.
`42` and `42.0` are the same type. The engine handles the difference
internally and you never think about it.

If you use TypeScript, you have:

```ts
let x: number = 42;
let name: string = "hello";
let active: boolean = true;
```

TypeScript adds type annotations, but at runtime everything is still
the same JS types. The types are erased when you compile.

Odin is fundamentally different on both of these points.

---

## How Odin Does It

### Three ways to bind names to values:

```odin
x := 42              // runtime variable, type inferred (like `let x = 42`)
y : f32 = 3.14       // runtime variable, type explicit
PI :: 3.14159         // compile-time constant (like `const` but stronger)
```

### The operators:

| Operator | Meaning | JS equivalent |
|----------|---------|---------------|
| `:=` | declare + assign, infer type | `let x = 42` |
| `: type =` | declare + assign, explicit type | `let x: number = 42` in TS |
| `::` | compile-time constant binding | `const` but resolved at compile time |
| `=` | reassign existing variable | `x = 100` |

### Many numeric types:

| Odin type | Size | Range | JS equivalent |
|-----------|------|-------|---------------|
| `i8` | 1 byte | -128 to 127 | none |
| `i16` | 2 bytes | -32768 to 32767 | none |
| `i32` | 4 bytes | -2B to 2B | none |
| `i64` | 8 bytes | very large | none |
| `int` | platform-size | 4 or 8 bytes | closest to JS `number` for integers |
| `u8` | 1 byte | 0 to 255 | `Uint8Array` element |
| `u16` | 2 bytes | 0 to 65535 | none |
| `u32` | 4 bytes | 0 to 4B | none |
| `f32` | 4 bytes | floating point | `Float32Array` element |
| `f64` | 8 bytes | floating point | JS `number` (which is f64) |
| `bool` | 1 byte | true/false | `boolean` |
| `string` | 16 bytes | pointer + length | `string` (but very different internally) |

---

## Deep Dive

### Why so many number types?

In JavaScript, the engine hides all of this from you. Internally, V8
uses "Smis" (small integers) and "HeapNumbers" (doubles) but you never
see it. You write `let x = 5` and it just works.

Games cannot afford that luxury. Here is why:

1. **GPU data must be exact sizes.** When you send vertex data to the
   GPU, each position is exactly `f32` (4 bytes). Not "some number" — a
   specific 32-bit IEEE 754 float. If you send the wrong size, the GPU
   reads garbage.

2. **Memory layout matters.** A particle system with 10,000 particles
   storing `f32` positions uses 40KB. If those were `f64` (like JS
   numbers), it would be 80KB. Double the cache pressure. Slower.

3. **Integer vs float behavior differs.** `7 / 2` in integer math = `3`
   (truncated). `7.0 / 2.0` in float math = `3.5`. In JS both give
   `3.5` because everything is float. In Odin you choose.

4. **Color bytes.** A color is typically 4 `u8` values: red, green, blue,
   alpha. Each 0-255. Using `u8` means one color = 4 bytes. Using `f32`
   per channel would be 16 bytes. For millions of pixels, this matters.

### Why `:=` vs `::` vs `=`?

This confuses every JS developer at first. Here is the clearest way to
think about it:

- `:=` says: "Create a new variable right now, figure out the type for me."
  This is the one you will use most often.

- `:: ` says: "This name is a compile-time constant. It will never change.
  The compiler can inline it, optimize it, or use it in type definitions."
  You use this for constants, function definitions, type definitions, and
  enum values.

- `=` says: "Change the value of a variable that already exists."
  You can only use `=` after `:=` or `: type =` created the variable.

```odin
x := 10    // create x, infer type int
x = 20     // ok: reassign x
x := 30    // ERROR: x already declared in this scope
```

Compare with JS:
```js
let x = 10;
x = 20;     // ok
let x = 30; // ERROR in strict mode: already declared
```

The pattern is similar, but the syntax differs.

### Explicit types vs inferred types

```odin
a := 42          // type is `int` (inferred)
b : f32 = 42     // type is `f32` (explicit)
c : u8 = 42      // type is `u8` (explicit)
```

When you write `a := 42`, Odin infers `int`. But for game dev, you often
want `f32` specifically because that is what the GPU and renderer expect.
So explicit typing is common in game code:

```odin
player_x : f32 = 100.0
player_y : f32 = 200.0
```

### No implicit type coercion

In JS:
```js
"5" + 3     // "53" (string concatenation)
"5" - 3     // 2 (numeric subtraction)
true + 1    // 2
```

In Odin: **none of this works.** Types must match exactly.

```odin
x : f32 = 5.0
y : i32 = 3
z := x + y           // ERROR: cannot add f32 and i32
z := x + f32(y)      // OK: explicit cast
```

This feels restrictive coming from JS. But it prevents an entire
category of bugs. In a game updating 60 times per second, a subtle
type coercion bug can cause positions to drift, physics to break, or
rendering to produce garbage. Strict types catch these at compile time.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o02_variables_and_types/main.odin`

Line refs:
- package + import: lines 1-3
- basic inference: lines 6-8
- explicit types: lines 11-14
- constants: lines 17-18
- casting: lines 21-24
- booleans: lines 27-29

Read those sections. Notice:
- `:=` for variables
- `: type =` for explicit types
- `::` for constants
- `f32(...)` for casting

---

## What Would Break If...

### You wrote `x = 42` without prior `:=`?
```
Error: Undeclared name: x
```
`=` only reassigns. `:=` creates. In JS, `var x = 42` both creates and
assigns. In Odin, creation and reassignment are separate operators.

### You tried to add `f32` and `i32` directly?
```
Error: Mismatched types: f32 vs i32
```
You must explicitly cast: `f32(my_int)` or `i32(my_float)`.

### You wrote `PI := 3.14` instead of `PI :: 3.14`?
It would compile, but `PI` would be a mutable variable, not a constant.
You could accidentally write `PI = 0` later and break everything.
`::` prevents that at compile time.

### You used a number outside the type range?
```odin
x : u8 = 300    // ERROR: 300 does not fit in u8 (max 255)
```
The compiler catches this. In JS, numbers silently overflow or become
`Infinity`. In Odin, the compiler rejects out-of-range constants.

---

## Common JS-Developer Mistakes

1. **Using `let` or `const`.**
   These do not exist in Odin. Use `:=` for variables, `::` for constants.

2. **Expecting everything to be `number`.**
   You must choose: `f32`, `i32`, `u8`, etc. For game dev, `f32` for
   positions/sizes and `i32` or `int` for counts/indices is the most
   common pattern.

3. **Forgetting to cast between types.**
   `f32(x)` and `i32(x)` are explicit casts. There is no implicit
   conversion. This feels tedious at first but prevents bugs.

4. **Writing `x : f32;` (with semicolon).**
   Odin does not use semicolons. Just end the line.

5. **Confusing `:=` and `::`.**
   `:=` is for runtime variables that can change.
   `::` is for compile-time constants that are fixed forever.
   If you want to define a procedure or type, you always use `::`.

---

## Mental Model

Think of Odin types like shipping containers:

- `u8` is a small box that fits 0-255.
- `f32` is a medium box that fits decimal numbers with some precision.
- `i32` is a medium box that fits large integers.
- `f64` is a large box with more precision.

In JS, everything goes into one giant flexible bag called `number`.
Convenient but wasteful and imprecise.

In Odin (and game dev), you pick the exact container size because:
- The GPU has specific container slots.
- Memory is a real resource you can run out of.
- Precision matters for physics and rendering.

---

## Exercises

### Exercise 1 — Declare and Print
Create variables of type `f32`, `i32`, `u8`, `bool`, and `string`.
Print each with `fmt.println`.

### Exercise 2 — Explicit vs Inferred
Create `a := 100` and `b : f32 = 100`. Print both.
Then try `c := a + b`. What error do you get? Fix it with a cast.

### Exercise 3 — Constants
Define `SCREEN_WIDTH :: 960` and `SCREEN_HEIGHT :: 540`.
Calculate and print the total number of pixels.
Try reassigning `SCREEN_WIDTH = 800`. What happens?

### Exercise 4 — Color Bytes
Define a color as four `u8` values: `r`, `g`, `b`, `a`.
Print them. Calculate total bytes used (hint: 4).
Then define the same color as four `f32` values and calculate total bytes
(hint: 16). Print which is more efficient.

---

## Exit Criteria

- [ ] Your program compiles and runs
- [ ] You can declare variables with `:=` and `: type =`
- [ ] You can define constants with `::`
- [ ] You can cast between numeric types with `f32(x)`, `i32(x)`, etc.
- [ ] You can explain why games use specific numeric types instead of one `number`
- [ ] You understand the difference between `:=`, `::`, and `=`

---

## Why This Matters For Game Dev

Every game frame, you work with positions (`f32`), colors (`u8`),
indices (`i32`), and flags (`bool`). Knowing your types means:
- You send correct data to the GPU.
- You use memory efficiently.
- The compiler catches type bugs before they become runtime crashes.

When you later see `player_x : f32 = 100` in game code, you will know
exactly what that means, why it is `f32`, and why it is not just
"a number."

---

## Next Lesson

`learn/10_odin_for_js_devs/o03_procs_not_functions`
