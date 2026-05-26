# O08 — Memory Without A Garbage Collector

## Goal

Understand where data lives in memory, why Odin has no garbage collector,
and how games manage memory without one. This is the concept that
separates web development from systems/game development the most.

---

## If You Know JS/TS...

In JavaScript, you never think about memory. Ever.

```js
function createPlayer() {
  return { x: 100, y: 200, inventory: [] };
}

const player = createPlayer();
// When nothing references `player`, the GC eventually frees the memory.
```

The garbage collector (GC) does everything:
- Allocates memory when you create objects
- Tracks which objects are still referenced
- Frees memory when objects are no longer reachable
- Runs automatically, at unpredictable times

You might have seen GC pauses in React apps — a brief stutter when the
GC stops your code to clean up memory. On a website, this is barely
noticeable. In a game running at 60fps, a 16ms GC pause = one entire
frame dropped. The player sees a stutter.

**Odin has no garbage collector.** You manage memory yourself.

This sounds scary. It is actually simpler than it sounds, because Odin
gives you clear tools and most game data lives on the stack anyway.

---

## How Odin Does It

### The Stack (automatic, fast, free)

```odin
main :: proc() {
    x := 42                     // stack: lives until main exits
    player := Player{ x = 100 } // stack: lives until main exits
    tiles: [100]Tile             // stack: 100 tiles, lives until main exits
}
// Everything above is automatically freed here. No GC needed.
```

Stack memory:
- Allocated when a proc starts
- Freed when the proc returns
- Extremely fast (just moving a pointer)
- Fixed size per proc call
- This is where most game data should live

In JS, local variables are also on the stack (primitives) or heap
(objects). You never choose. In Odin, structs and arrays default to
stack — you must explicitly request heap.

### The Heap (manual, flexible, your responsibility)

```odin
// Heap allocation
p := new(Player)         // allocates Player on heap, returns ^Player
p.x = 100
// ... use p ...
free(p)                  // YOU must free it when done
```

Heap memory:
- Lives until you free it
- Can outlive the proc that created it
- Slower to allocate than stack
- If you forget `free`, memory leaks

JS equivalent: every `new Object()` or `{ ... }` is heap. The GC frees it.
Odin equivalent: you `new()`, you `free()`. No invisible cleanup.

### The Temp Allocator (best of both worlds for games)

This is Odin's killer feature for game dev:

```odin
// Temp allocator resets at the end of each frame
temp_string := fmt.tprintf("Score: %d", score)
// No need to free! Temp allocator is cleared automatically.
```

The temp allocator is a bump allocator that:
- Allocates very fast (just increment a pointer)
- Gets reset all at once (typically once per frame)
- Perfect for per-frame scratch data

In `sauce/core_main.odin`, you will see the temp allocator being reset
each frame. This means anything allocated with `context.temp_allocator`
is valid for that frame only.

Think of it like this:
- **Stack:** lives until proc returns.
- **Heap:** lives until you free it.
- **Temp:** lives until the frame ends.

---

## Deep Dive

### Why no GC in games?

1. **Predictable frame time.** A game must deliver a frame every 16ms
   (for 60fps). A GC can pause for 1-20ms unpredictably. One pause =
   one stutter = the player notices.

2. **Controlled memory usage.** Games often have fixed budgets: 256MB
   for this, 512MB for that. A GC adds overhead (tracking tables,
   write barriers, GC thread) and makes memory usage harder to predict.

3. **Performance.** Heap allocation + GC is slower than stack allocation.
   Games allocate and free thousands of objects per second (particles,
   projectiles, UI elements). Stack and pool allocation handle this
   much better.

4. **Simplicity of ownership.** In a game, ownership is usually clear:
   - Entity array owns entities.
   - Particle pool owns particles.
   - Level data owns tiles.
   With clear ownership, you know when to free. GC is solving a problem
   that well-structured game code does not have.

### Common memory patterns in games

**Pattern 1: Fixed pool**
```odin
MAX_PARTICLES :: 256
particles: [MAX_PARTICLES]Particle   // stack or global
// No allocation! Reuse by toggling .active flag.
```

**Pattern 2: Dynamic with known lifetime**
```odin
levels: [dynamic]Level_Data
defer delete(levels)      // freed when scope exits
// Known lifetime = easy to manage.
```

**Pattern 3: Temp allocator for scratch work**
```odin
// Build a temporary string for display
label := fmt.tprintf("HP: %d / %d", current, max)
// No free needed — temp allocator clears each frame.
```

**Pattern 4: Arena allocator**
```odin
// Allocate a big block, sub-allocate from it, free all at once
// Used for level loading, asset loading, etc.
// We will see this in production code later.
```

### The `context` connection

Every Odin proc has an implicit `context` that carries:
- `context.allocator` — default allocator for `new`, `make`, `append`
- `context.temp_allocator` — temp allocator for scratch data

You can change these per-scope:

```odin
{
    context.allocator = my_arena_allocator
    data := make([]u8, 1024)   // uses arena, not default heap
}
```

This is covered in depth in lesson o09. For now, just know: the
allocator is part of the context, and games customize it.

### What about `defer`?

`defer` is Odin's cleanup helper:

```odin
data := new(Player)
defer free(data)
// ... use data ...
// free(data) runs automatically when this scope exits
```

Similar to `finally` in JS or the cleanup function in `useEffect`.
Covered in detail in lesson o14.

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o08_memory_without_gc/main.odin`

Line refs:
- stack allocation: lines 6-15
- heap allocation: lines 17-27
- temp allocator: lines 29-35
- fixed pool pattern: lines 37-60
- main: lines 62-end

---

## What Would Break If...

### You forgot to free heap memory?
Memory leak. The program uses more and more memory over time. In a
game that runs for hours, this can eventually crash or slow down.

### You used a temp-allocated string after the frame reset?
Dangling pointer. The memory was reused for something else. The string
now contains garbage. This is a use-after-free bug — one of the
trickiest bugs in systems programming.

### You allocated in the game loop every frame without pooling?
Gradually increasing heap usage. If using dynamic arrays, potential
re-allocation every frame. Slower than fixed pools.

### You tried to free stack memory?
```odin
x := 42
free(&x)  // ERROR or crash — stack memory cannot be freed manually
```
Only free what you `new` or `make`.

---

## Common JS-Developer Mistakes

1. **Assuming a GC will clean up.**
   There is no GC. If you `new()`, you must `free()`.

2. **Over-allocating on the heap.**
   In JS, creating objects is cheap (GC handles cleanup). In Odin,
   prefer stack (`Player{...}`) over heap (`new(Player)`) unless
   the data must outlive the current scope.

3. **Not understanding stack lifetime.**
   If you return a pointer to a stack variable, it becomes invalid
   after the proc returns. The memory is gone.

4. **Forgetting `defer free(...)`.**
   Use `defer` immediately after allocation. This prevents forgetting.

5. **Not using the temp allocator.**
   For per-frame strings and scratch data, `context.temp_allocator`
   or `fmt.tprintf` is perfect. No manual free needed.

---

## Mental Model

Think of memory like a hotel:

**Stack = your own house.**
You live here. When you leave the room (proc returns), everything in
that room is automatically gone. No checkout needed.

**Heap = a hotel room you rent.**
You check in (`new`). You stay as long as you want. But you MUST
check out (`free`) or the room stays occupied forever.

**Temp allocator = a day pass at a coworking space.**
You can use a desk all day. At midnight (frame reset), all desks are
cleared. No checkout needed — everything is wiped automatically.

**GC (JS) = a cleaning service that comes whenever it feels like it.**
Sometimes it comes right away. Sometimes it waits an hour. You never
know when, and occasionally it disrupts your meeting (frame stutter).

---

## Exercises

### Exercise 1 — Stack Only
Create a Player struct on the stack. Modify it. Print it.
No `new`, no `free`, no allocator. Just stack.

### Exercise 2 — Heap And Free
Create a Player with `new(Player)`. Set its fields. Print them.
Then `free` it. Add `defer free(p)` right after `new`.

### Exercise 3 — Temp Allocator String
Use `fmt.tprintf("HP: %d/%d", 75, 100)` to create a temporary string.
Print it. No free needed — explain why in a comment.

### Exercise 4 — Fixed Pool
Create `[10]Player` as a fixed pool. Set 3 players as active.
Iterate and print only active ones. No heap allocation anywhere.

---

## Exit Criteria

- [ ] You can explain stack vs heap vs temp allocator
- [ ] You can use `new` and `free` correctly
- [ ] You can use `defer free(...)` for safety
- [ ] You can explain why games avoid GC
- [ ] You understand fixed pools as allocation-free pattern
- [ ] You know when to use temp allocator vs heap

---

## Why This Matters For Game Dev

Memory management is THE fundamental difference between web dev and
game dev. Every particle, every entity, every level, every string in
your game exists somewhere in memory. Understanding where it lives
and when it dies is not optional — it is the foundation everything
else builds on.

When you later see `particles: [MAX_PARTICLES]Particle` in game code,
you will know: this is a fixed pool on the stack. Zero allocations.
Perfect for per-frame processing. When you see `defer delete(levels)`,
you will know: this is a dynamic array freed at scope exit.

---

## Next Lesson

`learn/odin_for_js_devs/o09_context_system`
