# O09 — The Context System

## Goal

Understand Odin's implicit `context` parameter — what it carries, why it
exists, and why every Sokol callback starts with `context = rt_ctx`.

---

## If You Know JS/TS...

React has a "Context" system:

```jsx
const ThemeContext = React.createContext("light");

function App() {
  return (
    <ThemeContext.Provider value="dark">
      <Button />
    </ThemeContext.Provider>
  );
}

function Button() {
  const theme = useContext(ThemeContext); // "dark"
}
```

React Context passes data down the component tree without explicit props.
Every child can access it. It is opt-in — you choose what to provide.

Odin's context is similar in spirit but different in mechanism:
- Every single proc automatically receives a hidden `context` parameter.
- You do not opt in. It is always there.
- It carries allocators, logger, random seed, and assertion handler.
- You can modify it for a scope, and all procs called within that scope
  see the modified version.

---

## How Odin Does It

### What `context` contains

```odin
// Simplified — the real struct has more fields
Context :: struct {
    allocator:      Allocator,       // default allocator for new/make/append
    temp_allocator: Allocator,       // per-frame scratch allocator
    logger:         Logger,          // logging backend
    assertion_failure_proc: proc(),  // what happens on assert failure
    random_generator: ...,           // random number source
    // ... more fields
}
```

### Implicit passing

Every proc receives `context` invisibly:

```odin
do_work :: proc() {
    // `context` is available here — you did not pass it
    data := make([]u8, 1024)  // uses context.allocator
    fmt.println("hello")       // fmt uses context internally
}
```

You never write `proc(ctx: Context)`. It happens automatically.

### Modifying context for a scope

```odin
main :: proc() {
    // Default context is active here

    {
        // Create a scoped modification
        context.allocator = my_custom_allocator
        do_work()  // this call uses my_custom_allocator
    }

    do_work()  // this call uses the original default allocator
}
```

The modification is lexically scoped — it applies to everything called
within those braces, then reverts.

### Why `context = rt_ctx` in Sokol callbacks

This is the most important practical detail for game code.

Sokol is a C library. When it calls your Odin callback, it uses the C
calling convention. C does not know about Odin's context system:

```odin
rt_ctx: runtime.Context   // global variable

main :: proc() {
    rt_ctx = context       // save the Odin context before handing off to C
    sapp.run({
        init_cb = init,
        frame_cb = frame,
        // ...
    })
}

init :: proc "c" () {
    context = rt_ctx       // restore the Odin context inside C callback
    // Now context.allocator, fmt, etc. all work correctly
}

frame :: proc "c" () {
    context = rt_ctx       // same pattern — must do this in every "c" callback
    // game code here
}
```

Without `context = rt_ctx`, calling `fmt.println` or `new` inside a
Sokol callback would crash or behave unpredictably because the context
would be garbage.

**Rule:** Every `proc "c"` callback that uses any Odin features must
start with `context = rt_ctx`.

---

## Deep Dive

### Why implicit context instead of global variables?

In JS, you might use global state:
```js
let currentAllocator = defaultAllocator;
```

Problem: any code can change it, and you cannot scope changes cleanly.
Nested calls get confused about which allocator is active.

Odin's context is:
- Implicitly passed (no manual threading through parameter lists)
- Lexically scoped (modifications apply only within braces)
- Copied per-scope (modifying it in a child scope does not affect parent)

This means you can write:
```odin
outer :: proc() {
    context.allocator = allocator_a
    inner()           // uses allocator_a
    // allocator_a still active here
}

inner :: proc() {
    context.allocator = allocator_b
    do_stuff()       // uses allocator_b
    // when inner returns, outer still has allocator_a
}
```

No global mutation, no confusion about active state.

### The temp allocator in practice

The temp allocator is the most-used context feature in game code:

```odin
// In game frame:
label := fmt.tprintf("Score: %d", score)     // temp allocated
path := fmt.tprintf("res/levels/%s", name)   // temp allocated
// Both are valid until end of frame.
// core_main.odin clears temp allocator each frame.
```

You do not need to free these. You do not need to track them. The temp
allocator wipes everything at frame boundaries.

### Context and testing

Context makes testing easier:

```odin
test_with_tracking :: proc() {
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)

    // Run game code — any leaked allocation is tracked
    do_game_stuff()

    // Check for leaks
    for leak in tracking_allocator.allocation_map {
        fmt.println("LEAK:", leak)
    }
}
```

By swapping the allocator in context, you can detect memory leaks
without changing any game code.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o09_context_system/main.odin`

Line refs:
- basic context usage: lines 6-12
- scoped allocator change: lines 14-25
- why `"c"` procs need context restore: lines 27-40
- main: lines 42-end

---

## What Would Break If...

### You forgot `context = rt_ctx` in a Sokol callback?
`fmt.println` would crash or produce garbage. `new()` would fail.
The allocator pointer would be nil or invalid.

### You modified context.allocator globally instead of in a scope?
All subsequent code uses the new allocator. If it is freed or invalid,
everything breaks. Always scope your context modifications.

### You used temp-allocated data after the frame reset?
Use-after-free. The memory was wiped. The string or data now contains
garbage from the next frame's temp allocations.

---

## Common JS-Developer Mistakes

1. **Not understanding why `context = rt_ctx` is needed.**
   C callbacks do not carry Odin context. You must restore it manually.
   This is the single most common confusion in Sokol game code.

2. **Thinking context is like React Context.**
   React Context is a tree-based data-passing mechanism. Odin context
   is an implicit parameter on every single proc call. Different scope.

3. **Modifying context outside a scope block.**
   Always use `{ context.allocator = ...; ... }` to scope changes.

4. **Expecting context to persist across frames.**
   The temp allocator is cleared each frame. Data allocated with it
   does not survive to the next frame.

---

## Mental Model

Think of context as a **clipboard you carry everywhere:**

- Every time you enter a room (call a proc), you bring your clipboard.
- The clipboard has your allocator, logger, and settings.
- You can temporarily put a different page on the clipboard (scope change).
- When you leave that room, the old page comes back.
- C rooms (`"c"` procs) do not give you a clipboard — you must bring
  your own copy from the hallway (`context = rt_ctx`).

---

## Exercises

### Exercise 1 — Print Context Info
In `main`, print `context.allocator` and observe the output.
(Hint: `fmt.println(context.allocator)`)

### Exercise 2 — Scoped Change
Create a scope block. Inside it, change something printable about
context (e.g., set a custom logger or just print a message showing
you are inside the scope). Print outside the scope to show it reverted.

### Exercise 3 — Explain rt_ctx
In a comment, write in your own words: why does every Sokol callback
start with `context = rt_ctx`? What would happen without it?

### Exercise 4 — Temp Allocator
Use `fmt.tprintf` to build 3 different strings. Print them all.
Write a comment explaining when these strings become invalid.

---

## Exit Criteria

- [ ] You can explain what `context` carries
- [ ] You understand implicit passing (no explicit parameter)
- [ ] You understand scoped modification
- [ ] You can explain `context = rt_ctx` in Sokol callbacks
- [ ] You know what temp allocator is and when it resets

---

## Why This Matters For Game Dev

Every line of game code runs under a context. Understanding context
explains:
- Why Sokol callbacks look the way they do
- How memory allocation works per-frame
- How to customize behavior without global variables
- How to debug memory leaks

When you see `context = rt_ctx` in `sauce/core_main.odin`, you will
know exactly what it does and why it is there.

---

## Next Lesson

`learn/10_odin_for_js_devs/o10_imports_and_packages`
