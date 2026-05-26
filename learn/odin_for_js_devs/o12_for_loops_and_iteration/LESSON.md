# O12 — For Loops And Iteration

## Goal

Understand every form of `for` loop in Odin and why there is no
`.map()`, `.filter()`, `.forEach()`, or `.reduce()`.

---

## If You Know JS/TS...

JavaScript has many iteration patterns:

```js
// Classic for
for (let i = 0; i < 10; i++) { ... }

// for...of
for (const item of array) { ... }

// for...in (objects)
for (const key in obj) { ... }

// Array methods (the JS way)
array.forEach(item => { ... });
const doubled = array.map(x => x * 2);
const evens = array.filter(x => x % 2 === 0);
const sum = array.reduce((acc, x) => acc + x, 0);
```

JS developers often prefer `.map`/`.filter`/`.reduce` because they are
declarative and composable. They express "what" not "how."

**Odin has one loop keyword: `for`.** No array methods. No functional
iteration. Just loops. But `for` has several powerful forms.

---

## How Odin Does It

### Form 1: Infinite loop

```odin
for {
    // runs forever until break
    if done { break }
}
```

Like `while (true)` in JS.

### Form 2: Condition loop

```odin
for x < 10 {
    x += 1
}
```

Like `while (x < 10)` in JS.

### Form 3: Range loop

```odin
for i in 0..<10 {
    fmt.println(i)    // 0, 1, 2, ... 9
}

for i in 0..=10 {
    fmt.println(i)    // 0, 1, 2, ... 10 (inclusive)
}
```

`0..<10` means 0 up to but not including 10.
`0..=10` means 0 up to and including 10.

JS: `for (let i = 0; i < 10; i++)` → Odin: `for i in 0..<10`

### Form 4: Array/slice iteration

```odin
scores: [5]i32 = {10, 20, 30, 40, 50}

// Value only
for score in scores {
    fmt.println(score)
}

// Value + index
for score, i in scores {
    fmt.println(i, score)
}
```

Like `for (const [i, score] of scores.entries())` in JS.

### Form 5: Mutable iteration

```odin
// Modify elements in place
for &score in &scores {
    score *= 2
}
```

The `&` means "give me a mutable reference, not a copy."
Without `&`, you modify a temporary copy and changes are lost.

**This is the most important form for game dev.** You will use it
to update entities, particles, tiles — anything in an array.

### Form 6: Reverse iteration

```odin
#reverse for &entity, i in &entities {
    if entity.dead {
        ordered_remove(&entities, i)
    }
}
```

`#reverse` iterates from last to first. Essential when removing
elements from a dynamic array during iteration — removing from the
end does not shift indices of earlier elements.

### Form 7: C-style for (rare)

```odin
for i := 0; i < 10; i += 1 {
    fmt.println(i)
}
```

Exists but less common. Range form is preferred.

---

## Deep Dive

### Why no .map(), .filter(), .reduce()?

In JS:
```js
const alive = enemies.filter(e => e.health > 0);
const names = enemies.map(e => e.name);
```

These create new arrays. In a game running 60fps:
- `.filter()` allocates a new array every frame.
- `.map()` allocates a new array every frame.
- GC must clean up the old arrays.

Odin does not have these because:
1. Allocation is explicit, not hidden in convenience methods.
2. Most game iteration is in-place (modify existing data, do not create new arrays).
3. A simple `for` loop with an `if` is just as clear and zero-cost.

JS-style:
```js
const alive = enemies.filter(e => e.health > 0);
```

Odin-style:
```odin
for &e in &enemies {
    if e.health > 0 {
        // process alive enemy
    }
}
```

Same logic. Zero allocation. No GC pressure.

### `break` and `continue`

```odin
for item in items {
    if item.skip { continue }   // skip this iteration
    if item.done { break }      // exit loop entirely
    process(item)
}
```

Same as JS `break` and `continue`.

### Nested loops with labels

```odin
outer: for row in 0..<ROWS {
    for col in 0..<COLS {
        if grid[row][col] == .target {
            fmt.println("Found at", row, col)
            break outer   // breaks the OUTER loop
        }
    }
}
```

Like labeled loops in JS (which exist but are rarely used).

### The game loop is a for loop

At the highest level, the game itself is a loop:

```
for each frame:
    process input
    update game state
    draw everything
```

Sokol handles this loop for you, but conceptually every game tick is
one iteration of a loop. Understanding loops is understanding games.

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o12_for_loops_and_iteration/main.odin`

Line refs:
- range loops: lines 6-14
- array iteration: lines 16-26
- mutable iteration: lines 28-36
- reverse removal: lines 38-52
- nested with break: lines 54-68
- main: lines 70-end

---

## What Would Break If...

### You wrote `for (let i = 0; i < 10; i++)`?
```
Error: unexpected token
```
No `let`, no parentheses around condition, no `++` (use `+= 1`).

### You forgot `&` in mutable iteration?
Changes to the loop variable are lost. You modified a copy.

### You removed from a dynamic array while iterating forward?
Skipped elements. When you remove index 3, what was index 4 becomes
index 3, but the loop moves to index 4 — skipping the new index 3.
Use `#reverse for` to iterate backward when removing.

### You used `..` instead of `..<` or `..=`?
```
Error: expected '..<' or '..=' for range
```
Odin requires you to be explicit about whether the end is inclusive
(`..=`) or exclusive (`..<`).

---

## Common JS-Developer Mistakes

1. **Expecting `.forEach()` or `.map()` on arrays.**
   Does not exist. Write `for` loops.

2. **Using `for (let i ...)` syntax.**
   Drop the parentheses and `let`. Write `for i in 0..<N`.

3. **Writing `i++` instead of `i += 1`.**
   Odin does not have `++` or `--` operators.

4. **Forgetting `&` for mutable iteration.**
   Without `&`, you modify copies. This is the loop version of the
   struct copy trap from o04.

5. **Forward-removing from dynamic array.**
   Always `#reverse for` when removing during iteration.

6. **Expecting `for...in` to iterate object keys.**
   Odin `for x in array` iterates array elements, not keys/indices.
   For index, use `for x, i in array`.

---

## Mental Model

Think of `for` like a factory conveyor belt:

- `for item in items` — items pass by on the belt. You look at each
  one. The items on the belt are copies — touching them does not
  affect the originals.

- `for &item in &items` — the belt carries the REAL items. You can
  modify them in place as they pass by.

- `#reverse for` — the belt runs backward. Useful when you need to
  remove items without messing up the belt order.

- `break` — stop the belt entirely.
- `continue` — let this item pass, look at the next one.

---

## Exercises

### Exercise 1 — Range Print
Print numbers 1 to 10 using `for i in 1..=10`.

### Exercise 2 — Sum Array
Create `[5]i32 = {10, 20, 30, 40, 50}`. Sum them using a for loop.
Print the result.

### Exercise 3 — Mutable Doubling
Create `[4]f32 = {1, 2, 3, 4}`. Double every element using
`for &v in &array`. Print before and after.

### Exercise 4 — Filter Pattern
Create an array of 5 "entities" (structs with `active: bool`).
Set some active, some not. Loop and print only active ones.
Count how many are active.

### Exercise 5 — Nested Grid Search
Create a 3x3 grid. Set one cell to a special value. Use nested
`for` loops to find it and print the coordinates. Use `break outer`
to stop early.

---

## Exit Criteria

- [ ] You can use `for i in 0..<N` and `for i in 0..=N`
- [ ] You can iterate arrays by value and by index
- [ ] You can use `&` for mutable iteration
- [ ] You can use `#reverse for` for safe removal
- [ ] You can use `break` and `continue`
- [ ] You understand why there is no `.map()` / `.filter()`

---

## Why This Matters For Game Dev

Every frame, your game loops over:
- entities (update positions, check health)
- particles (move, kill dead ones)
- tiles (draw, check collision)
- cards in hand (check playability)

The `for &entity in &entities` pattern is the single most common
line in game code. Understanding all loop forms means you can read
and write any game update logic.

---

## Next Lesson

`learn/odin_for_js_devs/o13_strings_and_cstrings`
