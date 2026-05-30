# O15 — Reading Compiler Errors

## Goal

Learn to read Odin compiler error messages quickly and correctly.
This is a practical survival skill — you will see errors every day.

---

## If You Know JS/TS...

In JavaScript, errors happen at runtime:
```
TypeError: Cannot read properties of undefined (reading 'x')
    at move (player.js:12)
    at update (game.js:45)
```

TypeScript catches some errors at compile time:
```
error TS2339: Property 'x' does not exist on type 'string'.
```

But many JS bugs only appear when the code runs. You ship code that
looks fine but crashes in production.

**Odin catches far more errors at compile time.** The trade-off: you
see more errors before your code runs, but once it compiles, far fewer
runtime surprises.

---

## How Odin Errors Look

### Format

```
/full/path/to/file.odin(LINE:COL) Error: message
    code line with problem
    ^~~~^  pointer to exact location
```

Example:
```
main.odin(12:5) Error: Undeclared name: consol
    consol.println("hello")
    ^~~~~^
```

This tells you:
- **File:** `main.odin`
- **Line 12, column 5**
- **Error type:** `Undeclared name`
- **What it found:** `consol` (you probably meant `console` — but there is no `console` in Odin anyway)
- **The `^~~~^` points to the exact token**

### Multiple errors

Odin often reports multiple errors at once. Fix the FIRST one. Often
later errors are caused by the first problem (cascading errors).

---

## Deep Dive — The 15 Most Common Errors

### 1. `Undeclared name`
```
Error: Undeclared name: x
```
**Cause:** Variable or proc not declared, or wrong spelling, or missing import.
**JS parallel:** `ReferenceError: x is not defined`
**Fix:** Check spelling. Check imports. Check scope.

### 2. `Mismatched types`
```
Error: Mismatched types: f32 vs i32
```
**Cause:** Trying to use `f32` where `i32` is expected (or vice versa).
**JS parallel:** Does not happen in JS (loose coercion). TS version: type mismatch.
**Fix:** Add explicit cast: `f32(my_int)` or `i32(my_float)`.

### 3. `Assignment count mismatch`
```
Error: Assignment count mismatch '2' = '1'
```
**Cause:** Proc returns 2 values but you only captured 1.
**JS parallel:** Does not happen (JS ignores extra returns).
**Fix:** `result, err := some_proc()` — capture both values.

### 4. `Unused variable`
```
Error: Unused variable: x
```
**Cause:** You declared `x` but never used it.
**JS parallel:** TS/ESLint warning, not error.
**Fix:** Use it, remove it, or assign to `_`: `_ = x`

### 5. `Unused import`
```
Error: Unused import: "core:math"
```
**Cause:** Imported a package but did not use anything from it.
**Fix:** Remove the import.

### 6. `Cannot convert type`
```
Error: Cannot convert 'Player' to '^Player'
```
**Cause:** Passing struct by value to a proc expecting pointer.
**Fix:** Add `&`: `do_thing(&player)`

### 7. `Expected ':' or ':=' after identifier`
```
Error: Expected ':' or ':=' after identifier 'function'
```
**Cause:** Used a JS keyword (`function`, `let`, `const`, `var`).
**Fix:** Use Odin syntax: `proc`, `:=`, `::`.

### 8. `Unhandled switch cases`
```
Error: Unhandled switch cases: .left, .right
```
**Cause:** Switch on enum is not exhaustive.
**Fix:** Add missing cases, or use `#partial switch`.

### 9. `Parameter must have a type`
```
Error: parameter 'a' must have a type
```
**Cause:** Wrote `proc(a, b)` without types.
**Fix:** `proc(a, b: f32)` — all params need types.

### 10. `'using' has been disallowed`
```
Error: 'using' has been disallowed as statement outside of immediate refactoring
```
**Cause:** Old Odin code used `using` as a statement. Newer Odin forbids it.
**Fix:** Add `#+feature using-stmt` before package line, or refactor away from `using`.

### 11. `Path does not exist`
```
Syntax Error: Path does not exist: core:os/os2
```
**Cause:** Importing a package that was removed or renamed.
**Fix:** Check current Odin stdlib. `os2` was folded into `core:os`.

### 12. `No procedures for procedure group`
```
Error: No procedures or ambiguous call for procedure group 'os.read_entire_file'
```
**Cause:** API changed. New Odin requires explicit allocator parameter.
**Fix:** Read the error's suggestion. Often shows the correct overload.

### 13. `Index out of bounds` (runtime)
```
Runtime panic: Index 10 is out of range for array of length 10
```
**Cause:** Accessing array beyond its size.
**JS parallel:** Returns `undefined`. Odin crashes.
**Fix:** Check bounds before access.

### 14. `Nil pointer dereference` (runtime)
```
Runtime panic: Nil pointer dereference
```
**Cause:** Used `^T` that is nil.
**Fix:** Check `if p != nil` before access.

### 15. `Assertion failure` (runtime)
```
Runtime assertion failure: "health should not be negative"
```
**Cause:** `assert(condition)` failed.
**Fix:** Fix the logic that caused the invalid state.

---

## Error Reading Strategy

1. **Read the FIRST error only.** Fix it. Recompile. Later errors often vanish.
2. **Read the file and line number.** Go directly there.
3. **Read the `^~~~^` pointer.** It shows the exact token.
4. **Read the suggestion.** Odin often says "Did you mean?" — trust it.
5. **Search for the error message** in this lesson if stuck.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o15_reading_compiler_errors/main.odin`

This solution is unique: it is a working program that PRINTS descriptions
of common errors. It does not contain the errors themselves (that would
not compile!).

---

## Exercises

### Exercise 1 — Cause And Fix 3 Errors
Intentionally write code that causes:
- `Undeclared name`
- `Mismatched types`
- `Unused variable`
Fix each one. Write a comment explaining the fix.

### Exercise 2 — Read A Real Error
Write `x : f32 = "hello"`. Read the error message carefully.
What does it say? Write the fix.

### Exercise 3 — Cascading Errors
Write a function with a missing return type that is used in 3 places.
Observe how 1 root error causes 3+ error messages. Fix only the root.

### Exercise 4 — Exhaustive Switch
Write a switch on a 4-value enum. Handle only 2 cases. Read the error.
Fix it two ways: add missing cases, or use `#partial switch`.

---

## Exit Criteria

- [ ] You can read error format: `file(line:col) Error: message`
- [ ] You fix the FIRST error and recompile
- [ ] You recognize the 10 most common errors by sight
- [ ] You can explain `^~~~^` pointer meaning
- [ ] You trust compiler suggestions ("Did you mean?")

---

## Why This Matters For Game Dev

You will write hundreds of compile-fix cycles. Reading errors fast =
faster development. Every minute saved reading errors = more time
making your game.

The Odin compiler is your strictest code reviewer. Learn to listen to
it and development becomes smooth.

---

## Next Lesson

`learn/10_odin_for_js_devs/o16_debugging_and_printing`
