# O16 — Debugging And Printing

## Goal

Learn practical debugging in Odin without browser DevTools, and build
the habits that will keep you productive when game code breaks.

---

## If You Know JS/TS...

JavaScript gives you rich debugging tools:

```js
console.log("player:", player);          // prints anything
console.log({ x, y, health });           // structured output
console.table(enemies);                  // table format
console.time("update"); /* ... */ console.timeEnd("update");
debugger;                                // breakpoint in DevTools
// Plus: React DevTools, network tab, profiler, source maps
```

You are used to:
- Printing any object and seeing all its fields
- Setting breakpoints visually
- Inspecting state while paused
- Hot reloading without restarting

**Odin game dev is different:**
- No browser DevTools
- No hot reloading (you recompile)
- `fmt.println` is your primary tool
- `lldb` exists for step debugging but most game devs print-debug
- `assert` is your crash-on-bug tool

---

## How Odin Does It

### `fmt.println` — your console.log

```odin
fmt.println("player pos:", player.x, player.y)
fmt.println("health:", player.health, "alive:", player.is_alive)
```

`fmt.println` prints multiple values separated by spaces, with a
newline at the end. It handles most types automatically.

### `fmt.printf` — formatted output

```odin
fmt.printf("Player at (%.2f, %.2f) HP: %d\n", player.x, player.y, player.health)
```

Format specifiers:
- `%d` — integer
- `%f` — float (default precision)
- `%.2f` — float with 2 decimal places
- `%s` — string
- `%v` — any type (auto-format, very useful)
- `%p` — pointer address
- `\n` — newline (printf does NOT add one automatically)

### `fmt.tprintf` — build debug strings

```odin
label := fmt.tprintf("[Frame %d] pos=(%.1f, %.1f)", frame, x, y)
fmt.println(label)
```

Temp-allocated. Perfect for per-frame debug labels.

### `assert` — crash on programmer error

```odin
assert(entity != nil, "entity must exist here")
assert(index >= 0 && index < len(array), "index out of range")
assert(health >= 0, "health went negative — logic bug")
```

Unlike `console.assert` in JS (which only warns), Odin `assert`
CRASHES the program immediately. This is intentional: you want to
find logic bugs as fast as possible.

### `log` package — leveled logging

```odin
import "core:log"

log.info("Game started")
log.warn("Missing texture, using fallback")
log.error("Failed to load level:", path)
```

`core:log` uses the context logger. The `sauce/` build system sets
up a logger that timestamps and categorizes messages.

### Conditional debug prints

```odin
when ODIN_DEBUG {
    fmt.println("[DEBUG] entity count:", len(entities))
}
```

`when ODIN_DEBUG` compiles the code only in debug builds. In release
builds, this code does not exist at all — zero overhead.

This replaces JS patterns like:
```js
if (process.env.NODE_ENV === "development") {
  console.log("debug info");
}
```

### `runtime.trap()` — hard crash

```odin
import "base:runtime"

if impossible_state {
    fmt.println("FATAL: this should never happen")
    runtime.trap()   // crash immediately
}
```

Like `process.exit(1)` in Node, but more direct.

---

## Deep Dive

### Why print-debugging is normal in game dev

In web dev, you have the browser debugger always available. In game dev:
- The game runs at 60fps. Pausing at a breakpoint freezes the game.
- Game state changes every frame. A breakpoint shows one frozen moment.
- Print-debugging shows data flowing over time — often more useful.
- `lldb` step debugging exists but is slower to iterate with.

Most professional game developers print-debug daily. It is not a "bad
practice" — it is a pragmatic choice.

### Debug overlay pattern

Many games draw debug info on screen:

```odin
// In your frame proc, after game drawing:
when ODIN_DEBUG {
    debug_y : f32 = 10
    draw_text(fmt.tprintf("FPS: %.0f", 1.0/dt), {10, debug_y})
    debug_y += 16
    draw_text(fmt.tprintf("Entities: %d", entity_count), {10, debug_y})
    debug_y += 16
    draw_text(fmt.tprintf("Cam: (%.0f, %.0f)", cam.x, cam.y), {10, debug_y})
}
```

This is common in `sauce/` style code. You will build this pattern
once you have text rendering.

### Frame-count gating

Printing every frame at 60fps floods your terminal. Gate it:

```odin
if sapp.frame_count() % 60 == 0 {
    fmt.println("Player:", player.x, player.y)
}
```

Prints once per second. Readable.

### Print then crash pattern

```odin
entity := find_entity(handle)
if entity == nil {
    fmt.println("BUG: entity not found for handle:", handle)
    fmt.println("  entity_count:", len(entities))
    fmt.println("  frame:", sapp.frame_count())
    assert(false, "entity lookup failed")
}
```

Print all useful context BEFORE crashing. When you see the crash,
you have all the information you need to fix it.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o16_debugging_and_printing/main.odin`

Line refs:
- println examples: lines 6-12
- printf formatting: lines 14-22
- conditional debug: lines 24-30
- assert: lines 32-38
- gated printing: lines 40-48
- main: lines 50-end

---

## What Would Break If...

### You used `fmt.printf` without `\n`?
Output stays on the same line. Unlike `println`, `printf` does not
auto-add newlines. Always end with `\n` or use `println` instead.

### You put `assert(false)` in production code path?
The game crashes every time it reaches that line. Use `assert` only
for states that should NEVER happen. Not for expected failure cases.

### You forgot `when ODIN_DEBUG` on verbose prints?
They stay in release builds. Printing to terminal in a release game
is wasteful and can slow it down.

### You print-debugged inside a hot loop without gating?
Terminal floods with thousands of lines per second. Gate with
`if frame_count % 60 == 0` or similar.

---

## Common JS-Developer Mistakes

1. **Looking for Chrome DevTools equivalent.**
   Does not exist for native Odin games. Use `fmt.println` and `assert`.

2. **Expecting `console.log` to show object structure.**
   `fmt.println(my_struct)` works but may not show all fields nicely.
   Use `fmt.printf("%v\n", my_struct)` for more detail.

3. **Not using `assert` aggressively enough.**
   In JS, you rarely assert. In Odin game dev, assert early and often.
   Every assumption about game state should be asserted in debug builds.

4. **Not gating frame-rate debug prints.**
   Printing 60 times per second is unreadable. Gate prints.

5. **Forgetting `when ODIN_DEBUG` for verbose output.**
   Release builds should not print debug info.

---

## Mental Model

**JS debugging:** You have a magnifying glass (DevTools) that lets you
pause time and inspect everything. Very powerful. Very slow to iterate.

**Odin debugging:** You have a stack of sticky notes (print statements)
that you place at interesting spots. The game runs at full speed and
you read the notes afterward. Faster iteration, but you choose which
notes to place.

**assert:** You place a trip wire. If anything crosses it, the alarm
goes off immediately. You know exactly where the bad state happened.

---

## Exercises

### Exercise 1 — Print Basics
Create a player struct. Print all its fields using `fmt.println` and
using `fmt.printf` with `%v`.

### Exercise 2 — Assert
Write 3 assert statements checking different conditions.
Trigger one and observe the crash message. Then fix it.

### Exercise 3 — Conditional Debug
Use `when ODIN_DEBUG` to wrap a verbose print. Build with `-debug`
flag. Then build without it and confirm the print is gone.

### Exercise 4 — Gated Printing
Write a loop that runs 300 times. Print only every 60th iteration.
Confirm output has exactly 5 lines.

---

## Exit Criteria

- [ ] You can use `fmt.println` and `fmt.printf` effectively
- [ ] You can use `%v`, `%d`, `%f`, `%s` format specifiers
- [ ] You can use `assert` for bug detection
- [ ] You understand `when ODIN_DEBUG`
- [ ] You can gate prints by frame count
- [ ] You accept that print-debugging is normal and productive

---

## Why This Matters For Game Dev

Debugging is 50% of game development. The faster you can identify
and fix bugs, the more game you build. `fmt.println` + `assert` is
a simple toolkit that professional game developers use every day.

When you later work in `sauce/`, you will use these tools constantly:
- Print entity positions to find collision bugs
- Assert state invariants to catch logic errors
- Gate prints to monitor per-frame behavior
- Use `when ODIN_DEBUG` to keep release builds clean

---

## Congratulations

You completed the Odin for JS/TS Developers track.

You now understand:
- Variables, types, and constants
- Procedures (not functions)
- Structs (not classes)
- Enums and exhaustive switch
- Arrays, slices, and dynamic arrays
- Pointers and value semantics
- Memory without garbage collection
- The context system
- Imports and packages
- Error handling without exceptions
- All loop forms
- Strings and cstrings
- Defer and cleanup
- Reading compiler errors
- Practical debugging

**Next step:** `learn/20_game_thinking_for_web_devs/` (coming soon)
or jump directly to `learn/30_fundamentals/t01_hello_window`

You are ready for game code.
