# O06 — Arrays, Slices, And Dynamic Arrays

## Goal

Understand the three array types in Odin, when to use each, and why
games care deeply about the distinction that JavaScript hides from you.

---

## If You Know JS/TS...

JavaScript has one array type that does everything:

```js
const items = [];         // empty, resizable
items.push("sword");      // grows automatically
items.push("shield");
items.length;             // 2
items[0];                 // "sword"
items.splice(0, 1);       // remove first element
```

JS arrays:
- Resize automatically
- Hold mixed types (unless TS restricts it)
- Are heap-allocated and garbage-collected
- Have built-in methods: `.push()`, `.pop()`, `.map()`, `.filter()`, `.forEach()`
- You never think about memory layout

This is convenient. But for games running at 60fps, it hides real costs.

---

## How Odin Does It

Odin has THREE distinct array types:

### 1. Fixed array: `[N]T`

```odin
tiles: [100]i32          // exactly 100 i32 values, on the stack
colors: [4]u8 = {255, 128, 0, 255}   // RGBA color
```

- Size is known at compile time.
- Lives on the stack (fast, no allocation).
- Cannot grow or shrink.
- Best for: particle pools, small buffers, tilemaps with known size.

JS equivalent: `new Int32Array(100)` — but even that is heap-allocated.

### 2. Slice: `[]T`

```odin
all_tiles: [100]i32
first_ten: []i32 = all_tiles[0:10]   // view into first 10 elements
```

- A "window" into existing data. Does NOT own the data.
- Contains: pointer + length. That is it.
- Cannot grow. Does not allocate.
- Best for: function parameters, iterating over part of an array.

JS equivalent: closest is `TypedArray.subarray()` — a view, not a copy.

### 3. Dynamic array: `[dynamic]T`

```odin
enemies: [dynamic]Entity
append(&enemies, new_enemy)
```

- Heap-allocated, can grow.
- Like JS arrays but explicit.
- You are responsible for calling `delete(enemies)` when done.
- Best for: lists that grow at runtime (entity lists, level data loaded from file).

JS equivalent: regular `[]` — but with manual memory management.

---

## Deep Dive

### Why three types instead of one?

Performance and clarity.

**Fixed arrays** are the most common in game dev. When you know the
maximum size at compile time, a fixed array is:
- Zero allocation cost (lives on the stack)
- Cache-friendly (contiguous memory, predictable access pattern)
- Predictable lifetime (dies when the scope ends)

Example: a particle system with max 256 particles:
```odin
MAX_PARTICLES :: 256
particles: [MAX_PARTICLES]Particle
```

No heap allocation. No GC. No resize cost. Every frame you iterate over
this array to update and draw particles. The CPU cache loves this.

**Slices** let you pass parts of arrays to procedures without copying:
```odin
print_tiles :: proc(tiles: []Tile) {
    for t in tiles {
        fmt.println(t)
    }
}

all_tiles: [100]Tile
print_tiles(all_tiles[:])       // pass entire array as slice
print_tiles(all_tiles[0:10])    // pass first 10 only
```

The `[:]` syntax creates a slice from a fixed array. The slice does NOT
copy the data — it is a pointer plus a length.

**Dynamic arrays** are for when you genuinely do not know the size
ahead of time:
```odin
loaded_levels: [dynamic]string
// ... load from files at runtime ...
append(&loaded_levels, "level_01.txt")
append(&loaded_levels, "level_02.txt")
// when done:
delete(loaded_levels)
```

### The cost JS hides from you

In JavaScript, every `array.push()`:
1. Checks if capacity is enough.
2. If not, allocates a bigger backing store on the heap.
3. Copies all old elements to the new store.
4. The old store becomes garbage for the GC to clean up.

This happens invisibly. In a game running 60fps, if you create and
destroy arrays every frame, the GC will eventually pause to clean up.
That pause = frame drop = stutter.

Odin makes this explicit:
- Fixed arrays: zero allocation, zero GC.
- Dynamic arrays: you allocate, you free. No surprise pauses.
- Slices: zero allocation, just a view.

### Iteration

```odin
// iterate by value (read only)
for tile in tiles {
    fmt.println(tile)
}

// iterate by reference (can modify)
for &tile in &tiles {
    tile = .wall
}

// iterate with index
for tile, i in tiles {
    fmt.println(i, tile)
}
```

Notice `for &tile in &tiles` — the `&` means "give me a mutable
reference." Without it, `tile` is a copy and changes are lost.
This is similar to the struct copy issue from o04.

In JS, `array.forEach((item, i) => ...)` always gives you the item
by reference (for objects). In Odin, you must ask explicitly.

### No `.map()`, `.filter()`, `.reduce()`

Odin has no array methods. You write loops.

JS:
```js
const alive = enemies.filter(e => e.health > 0);
const names = enemies.map(e => e.name);
```

Odin:
```odin
for e in enemies {
    if e.health > 0 {
        // ... process alive enemy
    }
}
```

This feels like a step backward from JS. But in game dev:
- `.filter()` creates a new array (allocation!)
- `.map()` creates a new array (allocation!)
- Loops with conditions do the work in-place, zero allocations.

For code that runs 60 times per second, this matters.

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o06_arrays_slices_dynamic/main.odin`

Line refs:
- fixed array: lines 5-14
- slice from fixed array: lines 16-24
- dynamic array: lines 26-41
- iteration patterns: lines 43-65
- main: lines 67-end

---

## What Would Break If...

### You tried to append to a fixed array?
```odin
tiles: [10]i32
append(&tiles, 99)  // ERROR: append works on [dynamic]T, not [N]T
```
Fixed arrays cannot grow. If you need to add elements, use `[dynamic]T`.

### You forgot `delete` on a dynamic array?
Memory leak. Odin has no GC to clean it up. The memory stays allocated
until the program exits. In a long-running game, this grows over time.

### You forgot `&` in `for &item in &array`?
Changes to `item` are lost. You modified a copy, not the original.
Same trap as passing structs by value.

### You accessed beyond array bounds?
```odin
tiles: [10]i32
x := tiles[10]  // Runtime panic: index out of bounds
```
Odin checks bounds at runtime (in debug builds). JS returns `undefined`
silently. Odin crashes immediately, which is actually better — you find
the bug instantly instead of debugging weird `undefined` behavior later.

---

## Common JS-Developer Mistakes

1. **Expecting `.push()` on fixed arrays.**
   Fixed arrays have no methods. Use `[dynamic]T` if you need `append`.

2. **Forgetting to `delete` dynamic arrays.**
   No GC. You allocate, you free.

3. **Using dynamic arrays when fixed would suffice.**
   If you know the max size, use `[MAX]T`. Faster, simpler, no leak risk.

4. **Expecting `.length` property.**
   Use `len(array)` — a built-in procedure, not a property.

5. **Forgetting `[:]` when passing fixed array to slice parameter.**
   `proc(data: []i32)` takes a slice. Pass `my_fixed_array[:]`.

6. **Modifying during iteration without `&`.**
   `for item in array` gives copies. `for &item in &array` gives
   mutable references.

---

## Mental Model

Think of the three types as containers:

**Fixed array = cardboard box with compartments.**
You pick the number of compartments when you build the box. Cannot add
more later. Very cheap to make. Sits right on your desk (stack).

**Slice = window cut into a wall.**
You look through the window at someone else's data. You can see and
maybe touch what is there, but you do not own it. The window has no
storage of its own.

**Dynamic array = stretchy bag from a store.**
It can grow when you add things. But you bought it (allocated) and you
must return it (free/delete) when done. It lives in the warehouse (heap),
not on your desk.

---

## Exercises

### Exercise 1 — Fixed Array
Create `scores: [5]i32 = {10, 20, 30, 40, 50}`.
Print each score with its index using `for score, i in scores`.

### Exercise 2 — Slice Parameter
Write a proc `sum :: proc(values: []i32) -> i32` that sums a slice.
Call it with `scores[:]` and with `scores[1:3]`.

### Exercise 3 — Dynamic Array
Create `names: [dynamic]string`. Append 3 names. Print them all.
Then `delete(names)`.

### Exercise 4 — Mutable Iteration
Create `[5]f32` with values 1-5. Use `for &v in &array` to double
each value in place. Print before and after.

---

## Exit Criteria

- [ ] You can create and use fixed arrays
- [ ] You can create slices from fixed arrays with `[:]` and `[a:b]`
- [ ] You can use `[dynamic]T`, `append`, and `delete`
- [ ] You can iterate with value, reference, and index
- [ ] You can explain why games prefer fixed arrays
- [ ] You understand the memory difference between the three types

---

## Why This Matters For Game Dev

- Tilemaps: `[ROWS][COLS]Tile` — fixed 2D array
- Particle pools: `[MAX]Particle` — fixed array
- Entity lists: `[dynamic]Entity` or fixed pool
- Hands in card game: `[dynamic]Card`
- Level data loaded from file: `[dynamic]u8`
- Slice parameters everywhere: `proc(tiles: []Tile)`

Choosing the right array type is one of the most impactful decisions
in game code. Fixed = fast and predictable. Dynamic = flexible but
you manage memory. Slice = efficient parameter passing.

---

## Next Lesson

`learn/odin_for_js_devs/o07_pointers_and_refs`
