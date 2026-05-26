# O14 — Defer And Cleanup

## Goal

Understand `defer` — Odin's mechanism for guaranteed cleanup at scope
exit — and how it replaces `finally`, `useEffect` cleanup, and RAII.

---

## If You Know JS/TS...

JavaScript has several cleanup patterns:

```js
// try/finally
try {
  const file = openFile("data.txt");
  processFile(file);
} finally {
  closeFile(file); // runs even if processFile throws
}

// React useEffect cleanup
useEffect(() => {
  const subscription = subscribe();
  return () => subscription.unsubscribe(); // cleanup on unmount
}, []);

// Async cleanup (less reliable)
const handle = setTimeout(fn, 1000);
clearTimeout(handle); // manual cleanup
```

The common theme: "I acquired a resource, and I need to release it
later, even if something goes wrong in between."

---

## How Odin Does It

### Basic defer

```odin
main :: proc() {
    data := new(Player)
    defer free(data)        // runs when main exits, no matter how

    // ... use data for 100 lines of code ...
    // free(data) executes automatically here
}
```

`defer` says: "run this statement when the current scope exits."

It runs:
- When the proc returns normally
- When the proc returns early (error path)
- When the scope block `{ }` ends

It is unconditional. The deferred statement always runs at scope exit.

### Multiple defers — LIFO order

```odin
main :: proc() {
    fmt.println("1: start")
    defer fmt.println("4: deferred first (runs last)")
    defer fmt.println("3: deferred second (runs second)")
    defer fmt.println("2: deferred third (runs first)")
    fmt.println("1.5: middle")
}
// Output:
// 1: start
// 1.5: middle
// 2: deferred third (runs first)
// 3: deferred second (runs second)
// 4: deferred first (runs last)
```

Defers execute in reverse order — Last In, First Out (LIFO).
This is natural for resource cleanup: you close things in the
reverse order you opened them.

### Defer with scoped blocks

```odin
{
    buffer := make([]u8, 1024)
    defer delete(buffer)
    // ... use buffer ...
}  // buffer freed here, not at proc exit
```

Defer is scoped to the nearest `{ }` block, not always the proc.
This lets you control lifetime precisely.

### Common game dev patterns

**Pattern 1: Allocate + defer free**
```odin
p := new(Player)
defer free(p)
```

**Pattern 2: Dynamic array + defer delete**
```odin
items: [dynamic]string
defer delete(items)
```

**Pattern 3: Open + defer close (files)**
```odin
f, err := os.open("level.txt")
if err != nil { return }
defer os.close(f)
```

---

## Deep Dive

### Why defer instead of finally?

`try/finally` in JS:
```js
try {
  acquire();
  mightFail();
} finally {
  release();
}
```

Problem: the `release()` is far from the `acquire()`. In 100-line
functions, you lose track of what needs cleanup.

`defer` in Odin:
```odin
resource := acquire()
defer release(resource)   // right next to acquire!
// ... 100 lines of code ...
// release happens automatically
```

The cleanup is written immediately after acquisition. You never forget
it. You never lose track of it. It is right there.

### Why not destructors (RAII)?

C++ uses destructors: when an object goes out of scope, its destructor
runs automatically. This is called RAII (Resource Acquisition Is
Initialization).

Odin does not have destructors because:
1. Structs are plain data — they do not have hidden behavior.
2. `defer` is explicit — you see exactly what cleanup happens.
3. No hidden cost — you know when and what runs at scope exit.

RAII hides cleanup in type definitions. `defer` puts cleanup in the
code where you read it. For game dev, explicit > implicit.

### Defer does NOT run on panic

If your program crashes (e.g., nil pointer, assert failure), defers
may not run. This is fine because:
- On crash, the OS reclaims all memory anyway.
- Defers are for normal cleanup, not crash recovery.

### Defer captures by value at defer-time

```odin
x := 10
defer fmt.println(x)   // captures x = 10 at this point
x = 20
// prints 10, not 20
```

The deferred expression captures variable values when the `defer`
statement is encountered, not when it executes. This matches Go's
behavior and can be surprising.

For pointer-based cleanup (`defer free(p)`), this is fine because
the pointer value does not change.

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o14_defer_and_cleanup/main.odin`

Line refs:
- basic defer: lines 6-12
- LIFO order: lines 14-22
- scoped defer: lines 24-32
- allocate + defer free: lines 34-42
- main: lines 44-end

---

## What Would Break If...

### You forgot `defer free(p)` after `new(Player)`?
Memory leak. The player data stays on the heap forever.

### You put defer outside any scope?
```
Error: 'defer' statement only allowed inside a procedure
```
Defer must be inside a proc or block scope.

### You expected defers to run in forward order?
They run in LIFO (reverse) order. First defer runs last.

### You relied on defer for crash recovery?
Defers may not run on panic/crash. Do not use them for critical
crash-time cleanup. Use them for normal scope exit cleanup.

---

## Common JS-Developer Mistakes

1. **Expecting `finally` syntax.**
   No `try/finally`. Use `defer`.

2. **Putting cleanup at the bottom of a function.**
   In JS you might write cleanup at the end. In Odin, write
   `defer cleanup()` right after acquisition. Never at the bottom.

3. **Forgetting defer is LIFO.**
   Multiple defers run in reverse order. If order matters, be aware.

4. **Not using defer for dynamic arrays.**
   `items: [dynamic]string; defer delete(items)` — always pair them.

5. **Expecting defer to work like useEffect cleanup.**
   `defer` runs at scope exit, not on some lifecycle event. It is
   simpler and more predictable than React cleanup returns.

---

## Mental Model

Think of `defer` as **sticky notes on a door:**

When you enter a room (scope), you can stick notes on the door.
Each note says "do this when leaving." When you walk out, you peel
off the notes in reverse order (top note first = last one stuck).

```
Door:
  [3] close file       ← runs first (last stuck)
  [2] free buffer      ← runs second
  [1] print "done"     ← runs last (first stuck)
```

You always stick the note RIGHT AFTER acquiring the resource.
Never at the bottom of the room. Right there. Next to the acquisition.

---

## Exercises

### Exercise 1 — Basic Defer
Write a proc with `fmt.println("start")`, `defer fmt.println("end")`,
and `fmt.println("middle")`. Predict the output. Run it. Were you right?

### Exercise 2 — LIFO Order
Write 3 defers in a row. Predict execution order. Verify.

### Exercise 3 — Allocate + Defer Free
Create a `[dynamic]i32`. `defer delete(...)` immediately. Append 5 values.
Print them. The delete happens automatically when main exits.

### Exercise 4 — Scoped Defer
Create a block `{ }` inside main. Inside it, allocate something and
defer its cleanup. Print a message after the block to prove the
cleanup happened at block exit, not at proc exit.

---

## Exit Criteria

- [ ] You can use `defer` for cleanup
- [ ] You understand LIFO execution order
- [ ] You pair `new`/`free` and `make`/`delete` with defer
- [ ] You know defer is scoped to `{ }` blocks
- [ ] You understand why defer is better than `finally` for readability

---

## Why This Matters For Game Dev

Every dynamic array, every heap allocation, every file handle in your
game should have a `defer` immediately after creation. This prevents
memory leaks and resource leaks in game code that runs for hours.

When you see `defer delete(entities)` in sauce, you know: that array
is cleaned up when the scope ends. No mystery. No forgotten cleanup.

---

## Next Lesson

`learn/odin_for_js_devs/o15_reading_compiler_errors`
