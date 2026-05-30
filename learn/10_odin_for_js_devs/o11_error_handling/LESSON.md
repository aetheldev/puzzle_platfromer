# O11 — Error Handling

## Goal

Understand how Odin handles errors without try/catch, and why this
approach is actually cleaner for game code.

---

## If You Know JS/TS...

JavaScript uses exceptions:

```js
try {
  const data = JSON.parse(rawText);
  const file = fs.readFileSync("level.txt", "utf-8");
} catch (err) {
  console.error("Something went wrong:", err.message);
}
```

And async error handling:

```js
fetch("/api/data")
  .then(res => res.json())
  .catch(err => console.error(err));

// or
try {
  const res = await fetch("/api/data");
} catch (err) { ... }
```

The throw/catch model:
- Errors are objects thrown up the call stack.
- Any function between throw and catch gets interrupted.
- If nothing catches it, the program crashes.
- You cannot tell from a function signature whether it might throw.

---

## How Odin Does It

### Return-based errors

Odin uses multiple return values:

```odin
read_file :: proc(path: string) -> (data: []u8, err: Error) {
    // ...
}

data, err := read_file("level.txt")
if err != nil {
    fmt.println("Failed:", err)
    return
}
// data is valid here
```

The error is part of the return value. Not thrown. Not caught. Explicitly
checked at every call site.

### `or_return` — the short circuit

```odin
load_level :: proc(path: string) -> (Level, Error) {
    data, err := os.read_entire_file_from_path(path, context.temp_allocator)
    if err != nil { return {}, err }    // long form

    // or shorter:
    data2 := os.read_entire_file_from_path(path2, context.temp_allocator) or_return
    // if error, return immediately with zero Level + the error
}
```

`or_return` says: "if this call returned an error, propagate it up
immediately." It is like a very controlled version of throw — but
explicit, visible, and typed.

### `assert` — crash intentionally

```odin
assert(health >= 0, "health should never be negative")
```

If the condition is false, the program crashes with that message.
Used for programmer errors, not user errors.

In JS, you might use:
```js
console.assert(health >= 0, "health should never be negative");
// But console.assert does NOT stop execution!
```

In Odin, `assert` is a hard stop. The game crashes immediately.
This is good: you find the bug right now instead of limping along
with corrupt state.

### No exceptions, no try/catch

There is no `try`. There is no `catch`. There is no `throw`.

Every error is a return value. Every error check is explicit.
You can see in the function signature whether errors are possible:

```odin
// This can fail — returns an error
load :: proc(path: string) -> (Data, Error) { ... }

// This cannot fail — no error in return
add :: proc(a, b: f32) -> f32 { ... }
```

In JS, ANY function might throw. You cannot tell without reading the
entire implementation. In Odin, the signature tells you.

---

## Deep Dive

### Why return-based errors are better for games

1. **Visible control flow.** No hidden jumps. No mystery about which
   catch block runs. You see the error check right where it happens.

2. **No performance cost.** Exceptions use stack unwinding, which is
   slow. Return values are just return values — zero overhead.

3. **Compile-time help.** If a proc returns `(Data, Error)` and you
   write `data := load(...)` without handling the error, the compiler
   warns you about the unused return value.

4. **No cleanup confusion.** With exceptions, finally blocks and
   cleanup order can be confusing. With return-based errors, you
   check, handle, and continue. Linear flow.

### Common error patterns in game code

**Pattern 1: Check and return**
```odin
data, err := load_file(path)
if err != nil {
    log.error("Failed to load:", path, err)
    return
}
```

**Pattern 2: Check and fallback**
```odin
data, err := load_file(path)
if err != nil {
    log.warn("Using default level")
    data = default_level_data
}
```

**Pattern 3: Assert for impossible states**
```odin
entity := find_entity(handle)
assert(entity != nil, "entity must exist at this point")
```

**Pattern 4: or_return chain**
```odin
load_game :: proc() -> Error {
    config := load_config("game.cfg") or_return
    levels := load_levels("res/levels/") or_return
    sprites := load_sprites("res/images/") or_return
    return nil
}
```

Clean chain. Each step can fail. Error propagates up automatically.

### `ok` pattern

Many Odin APIs return `(value, ok)` where ok is a `bool`:

```odin
value, ok := my_map[key]
if !ok {
    fmt.println("key not found")
}
```

This replaces JS patterns like:
```js
const value = myMap.get(key);
if (value === undefined) { ... }
```

The `ok` pattern is unambiguous. `undefined` in JS could mean "key
exists but value is undefined" — a real confusion source.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o11_error_handling/main.odin`

Line refs:
- basic error return: lines 6-15
- or_return pattern: lines 17-24
- assert usage: lines 26-32
- ok pattern: lines 34-42
- main: lines 44-end

---

## What Would Break If...

### You ignored an error return value?
The compiler may warn. If the data is invalid and you use it anyway,
the program may crash or produce garbage.

### You used `or_return` in a proc that does not return an error?
```
Error: 'or_return' used in procedure that has no error return
```
`or_return` only works in procs that return a compatible error type.

### You expected `try { ... } catch { ... }`?
```
Error: Undeclared name: try
```
Does not exist. Use `if err != nil { ... }`.

### An assert failed at runtime?
Program crashes immediately with your message. This is intentional.
Fix the bug that caused the invalid state.

---

## Common JS-Developer Mistakes

1. **Looking for try/catch.**
   Does not exist. Check return values explicitly.

2. **Ignoring error returns.**
   In JS, you can ignore rejected promises (bad practice but possible).
   In Odin, ignoring error returns leads to using invalid data.

3. **Using assert for user-facing errors.**
   Assert is for programmer bugs, not for "file not found" or "invalid
   input." Use error returns for recoverable situations.

4. **Expecting exceptions to propagate automatically.**
   Errors do not propagate unless you use `or_return` or return them
   manually. Every level in the call stack must handle or forward.

---

## Mental Model

Think of error handling as **choosing between two doors:**

**JS exceptions:** You walk through a hallway. Any room might have a
trap door (throw) that drops you to the basement (catch). You never
know which room has the trap door until you fall.

**Odin return errors:** Every room has two clearly labeled doors:
"Success" and "Error." You walk through one. You always know which
door you are going through. No surprises.

`or_return` is like a rule: "If I encounter an Error door, walk back
to my caller and hand them the error."

---

## Exercises

### Exercise 1 — Basic Error Return
Write `safe_divide :: proc(a, b: f32) -> (f32, bool)`.
Return `0, false` if b is zero. Otherwise return result and true.
Call it twice and check the bool.

### Exercise 2 — Assert
Write a proc that takes health as `i32`. Assert it is >= 0.
Call it with a valid value and an invalid value (in separate runs).

### Exercise 3 — Error Check Pattern
Write a proc that "loads a level" (just return an error string if
the name is empty, or return data if name is valid).
Call it with good and bad input. Print results.

### Exercise 4 — or_return Chain
Write two procs that each return `(string, bool)`.
Write a third proc that calls both using `or_return` style
(check each, return early on failure). Chain them.

---

## Exit Criteria

- [ ] You can write procs that return errors
- [ ] You can check errors with `if err != nil`
- [ ] You understand `or_return`
- [ ] You can use `assert` for programmer errors
- [ ] You know why Odin has no try/catch
- [ ] You can explain the `(value, ok)` pattern

---

## Why This Matters For Game Dev

Game code loads files, parses levels, creates GPU resources — all of
which can fail. Understanding return-based errors means you can:
- Load levels safely with fallbacks
- Handle missing assets gracefully
- Crash intentionally on programmer bugs (assert)
- Chain loading steps cleanly (or_return)

When you see `png_data, err := os.read_entire_file_from_path(...)` in
`sauce/core_render.odin`, you will know exactly what to expect.

---

## Next Lesson

`learn/10_odin_for_js_devs/o12_for_loops_and_iteration`
