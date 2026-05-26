# O03 — Procs, Not Functions

## Goal

Understand how Odin procedures work, how they differ from JS functions,
and why those differences matter for game programming.

---

## If You Know JS/TS...

In JavaScript, you have many ways to define functions:

```js
// Named function
function add(a, b) {
  return a + b;
}

// Arrow function
const add = (a, b) => a + b;

// Method on object
const player = {
  x: 0,
  move(dx) { this.x += dx; }
};

// Callback
setTimeout(() => console.log("done"), 1000);

// Closure — captures outer variable
function makeCounter() {
  let count = 0;
  return () => ++count;
}
```

JS functions can:
- Capture variables from outer scope (closures)
- Be stored in variables, passed around, returned
- Have `this` context that changes based on how they are called
- Be async with `async/await`
- Infer parameter and return types (in plain JS)

Now forget most of that. Odin procedures are simpler, more explicit,
and more restricted — deliberately.

---

## How Odin Does It

### Basic procedure

```odin
add :: proc(a: f32, b: f32) -> f32 {
    return a + b
}
```

Breaking it apart:
- `add` — the name
- `::` — compile-time constant binding (the procedure itself is a constant)
- `proc(a: f32, b: f32)` — procedure that takes two `f32` parameters
- `-> f32` — return type
- `{ return a + b }` — body

### Shorthand for same-type parameters

```odin
add :: proc(a, b: f32) -> f32 {
    return a + b
}
```

When consecutive parameters share a type, you can group them.

### No return value

```odin
greet :: proc(name: string) {
    fmt.println("Hello,", name)
}
```

No `-> type` means the proc returns nothing (like `void` in C/TS).

### Multiple return values

```odin
divide :: proc(a, b: f32) -> (f32, bool) {
    if b == 0 { return 0, false }
    return a / b, true
}

// Usage:
result, ok := divide(10, 3)
```

This is a big difference from JS. In JS, you would return an object:
```js
function divide(a, b) {
  if (b === 0) return { result: 0, ok: false };
  return { result: a / b, ok: true };
}
const { result, ok } = divide(10, 3);
```

Odin does it without allocating any object. The two values are returned
on the stack, no heap allocation, no garbage collector involvement.

---

## Deep Dive

### Why `::` and not `const` or `let`?

When you write:
```odin
add :: proc(a, b: f32) -> f32 { ... }
```

The `::` means `add` is bound at compile time. The compiler knows
exactly what `add` is before the program runs. This allows:
- Direct function calls (no lookup table, no vtable)
- Inlining (compiler can paste the function body at the call site)
- Zero overhead

In JS, even `const add = (a, b) => a + b` is a runtime binding. The
engine creates a function object, puts it in memory, and `add` is a
reference to that object. In Odin, `add` is not an object — it is a
label that the compiler resolves to a memory address.

### No closures

This is the biggest difference for JS developers.

In JS:
```js
function makeGreeter(prefix) {
  return (name) => `${prefix} ${name}`;
}
const greet = makeGreeter("Hello");
greet("World"); // "Hello World"
```

The inner arrow function "captures" `prefix` from the outer scope.
This requires the runtime to keep `prefix` alive on the heap even after
`makeGreeter` returns.

In Odin: **procedures cannot capture variables from outer scope.**

```odin
make_greeter :: proc(prefix: string) -> proc(string) -> string {
    // ERROR: cannot capture `prefix` in procedure literal
    return proc(name: string) -> string {
        return fmt.tprintf("%s %s", prefix, name)  // prefix not accessible!
    }
}
```

Why? Because closures require heap allocation to keep captured variables
alive. Games avoid unnecessary heap allocation. Odin makes this explicit:
if you need to pass data to a callback, you pass it explicitly as a
parameter, or through a struct, or through a `rawptr` (raw pointer) +
data pair. No hidden magic.

### No `this`

In JS, `this` changes based on how a function is called:
```js
const obj = {
  x: 10,
  getX() { return this.x; }
};
const fn = obj.getX;
fn(); // undefined — `this` is lost!
```

In Odin, there is no `this`. There are no methods. If a procedure needs
to work on data, you pass that data explicitly:

```odin
Player :: struct { x, y: f32 }

move_player :: proc(p: ^Player, dx, dy: f32) {
    p.x += dx
    p.y += dy
}
```

The `^Player` is a pointer (we will cover pointers in o07). The
important thing now: the data is an explicit parameter. There is no
hidden context, no binding confusion, no `this` bugs.

### The `"c"` calling convention

You will see this in game code:

```odin
init :: proc "c" () {
    context = rt_ctx
    // ...
}
```

The `"c"` tells the compiler: "This procedure uses the C calling
convention." This is needed when Sokol (which is written in C) calls
your Odin code as a callback.

Important detail: `"c"` procs do not carry the Odin `context`
automatically. That is why you see `context = rt_ctx` at the top of
every Sokol callback. We will cover `context` fully in lesson o09.

For now, just know: `"c"` means "this proc is called from C code."

### Procedures as values

Odin procedures can be stored in variables and passed as parameters:

```odin
operation :: proc(a, b: f32, op: proc(f32, f32) -> f32) -> f32 {
    return op(a, b)
}

result := operation(10, 3, add)
```

This is similar to passing functions as arguments in JS. The difference
is that Odin procedure values cannot be closures — they are just
function pointers.

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o03_procs_not_functions/main.odin`

Line refs:
- `add` proc: lines 5-7
- `greet` proc: lines 9-11
- `divide` with multiple returns: lines 13-17
- calling and destructuring returns: lines 21-23
- `apply_op` higher-order proc: lines 26-28
- `"c"` callback note: lines 31-37
- main: lines 39-56

After reading, close it.

---

## What Would Break If...

### You forgot the parameter type?
```odin
add :: proc(a, b) -> f32 { ... }
// ERROR: parameter 'a' must have a type
```
Odin does not infer parameter types. Every parameter must be typed.

### You wrote `function` instead of `proc`?
```
ERROR: Expected ':' or ':=' after identifier 'function'
```
There is no `function` keyword in Odin.

### You tried to capture an outer variable?
```odin
x := 42
callback :: proc() {
    fmt.println(x)  // ERROR: undeclared name 'x'
}
```
Procedures cannot see variables from outer runtime scope.
They can see compile-time constants (`::`) from outer scope, but not
runtime variables (`:=`).

### You forgot `-> type` on a proc that returns a value?
```odin
add :: proc(a, b: f32) {
    return a + b    // ERROR: cannot return value from proc with no return type
}
```
Return types must be declared explicitly.

---

## Common JS-Developer Mistakes

1. **Expecting closures to work.**
   `let count = 0; const inc = () => ++count;` — this pattern does not
   exist in Odin. You must pass data explicitly.

2. **Writing `function` instead of `proc`.**
   It is always `proc` in Odin.

3. **Forgetting parameter types.**
   In JS, `function add(a, b)` is fine. In Odin, `proc(a, b)` is an
   error. You must write `proc(a, b: f32)`.

4. **Expecting `this` to exist.**
   There is no `this`. Pass the object explicitly: `proc(p: ^Player)`.

5. **Expecting to destructure returns with `{ }`.**
   In JS: `const { result, ok } = divide(10, 3)`.
   In Odin: `result, ok := divide(10, 3)`. Just comma-separated names.

6. **Not understanding `::` vs `:=` for procs.**
   `add :: proc(...)` = compile-time constant proc (most common).
   `add := proc(...)` = runtime variable holding a proc value (rare,
   but needed for proc-in-struct or callback tables).

---

## Mental Model

Think of Odin procedures like tools in a workshop:

- Each tool (proc) has a specific set of input slots (parameters) and
  produces a specific output (return value).
- The tool does not remember what happened last time (no closure state).
- The tool does not know which workbench it sits on (no `this`).
- You bring the material (data) to the tool. The tool does not reach
  into your pocket.

In JS, functions are like smart robots that can:
- Remember their environment (closures)
- Know which object they belong to (`this`)
- Decide what type of input they accept at runtime

In Odin, procedures are simpler and more predictable. This makes game
code easier to reason about: you always know exactly what data a
procedure touches, because it is all in the parameter list.

---

## Exercises

### Exercise 1 — Basic Proc
Write a `multiply` proc that takes two `f32` values and returns their product.
Call it from `main` and print the result.

### Exercise 2 — Multiple Returns
Write a `safe_divide` proc that returns `(f32, bool)`.
If the divisor is zero, return `0, false`. Otherwise return the result and `true`.
Call it twice: once with valid input, once with zero divisor.

### Exercise 3 — Proc As Parameter
Write an `apply` proc that takes two `f32` values and a proc parameter.
Pass your `multiply` proc to it and print the result.

### Exercise 4 — No Closure Proof
Try to write a proc that captures a variable from `main`.
Observe the compiler error. Write a comment explaining why it fails.
Then rewrite it to pass the variable as a parameter instead.

---

## Exit Criteria

- [ ] You can write procs with typed params and return types
- [ ] You can use multiple return values
- [ ] You can pass procs as parameters
- [ ] You can explain why closures do not work in Odin
- [ ] You understand what `"c"` calling convention means (even if you do not need it yet)
- [ ] You know the difference between `add :: proc(...)` and `add := proc(...)`

---

## Why This Matters For Game Dev

Game code is full of procedures:
- `init` sets up the game
- `frame` runs every 16ms
- `event` handles input
- `draw_rect` draws a shape
- `try_move` checks if a move is legal

Every one is a `proc`. Understanding how they work — especially the
"no closures, no this, explicit parameters" model — is essential before
you can read or write any game code in this repo.

When you later see `init :: proc "c" ()`, you will know:
- It is a constant procedure
- It takes no parameters
- It uses the C calling convention for Sokol
- It has no return value
- It cannot capture variables from outer scope

---

## Next Lesson

`learn/odin_for_js_devs/o04_structs_not_classes`
