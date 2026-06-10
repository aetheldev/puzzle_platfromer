# O17 — Maps And Lookups

## Goal

Understand Odin's `map[Key]Value` type: how it replaces JS objects and
`Map`, how to insert, look up, delete, and iterate, and when a map is
the right tool in game code (and when an array is better).

---

## If You Know JS/TS...

In JavaScript, you reach for objects or `Map` constantly:

```js
// object as dictionary
const tileNames = {
  0: "empty",
  1: "wall",
  2: "goal",
};

// Map for non-string keys
const entityById = new Map();
entityById.set(42, { name: "goblin", hp: 10 });

const e = entityById.get(42);
if (e !== undefined) {
  console.log(e.name);
}

entityById.delete(42);

for (const [id, entity] of entityById) {
  console.log(id, entity.name);
}
```

JS objects/Maps are everywhere because JS has no other built-in
key-value container. They are heap-allocated, GC-tracked, and accept
almost anything as a key.

Odin has one built-in hash map type: `map[Key]Value`. It looks similar
but behaves differently in three important ways:

1. It is **typed**: one key type, one value type, checked at compile time.
2. It is **manually managed**: you must `delete()` it when done.
3. Lookups return an explicit **`(value, ok)`** pair — no `undefined`.

---

## How Odin Does It

### Declaring and creating a map

```odin
// declare a map from entity id (int) to name (string)
names: map[int]string

// maps must be initialized before use (or use make)
names = make(map[int]string)
defer delete(names)   // manual memory — clean up when scope ends
```

You can also create with a literal (needs `#+feature dynamic-literals`
at the top of the file, or build with the feature enabled):

```odin
tile_names := map[int]string{
    0 = "empty",
    1 = "wall",
    2 = "goal",
}
defer delete(tile_names)
```

### Insert and update

```odin
names[42] = "goblin"      // insert
names[42] = "hobgoblin"   // update — same syntax
```

Same as JS `map.set(42, "goblin")`, but with `[]` syntax.

### Lookup — the `(value, ok)` pattern

```odin
name, ok := names[42]
if ok {
    fmt.println("found:", name)
} else {
    fmt.println("no entity with id 42")
}
```

This is the same `(value, ok)` pattern from o11 (error handling).
There is no `undefined`. The `ok` bool tells you if the key exists.

If you index without capturing `ok`, a missing key gives you the
**zero value** (empty string, 0, false...):

```odin
name := names[999]   // "" — zero value, NOT a crash, NOT undefined
```

### Delete a key

```odin
delete_key(&names, 42)
```

### Check existence only

```odin
if 42 in names {
    fmt.println("entity 42 exists")
}
```

`in` reads much nicer than JS's `map.has(42)`.

### Iterate

```odin
for id, name in names {
    fmt.println(id, "->", name)
}
```

Like JS `for (const [k, v] of map)`. **Iteration order is random** —
do not rely on it (JS Maps keep insertion order; Odin maps do not!).

---

## Deep Dive

### Map memory: who owns it?

A map allocates memory on the heap as it grows. Like dynamic arrays
from o06, **you** are responsible for freeing it:

```odin
inventory := make(map[string]int)
defer delete(inventory)    // pairs with make — see o14 (defer)
```

Forget `delete` → memory leak. The tracking allocator from o09 will
catch this in debug builds.

### When to use a map vs an array — the game dev decision

This decision comes up constantly in game code:

| Situation | Use |
|-----------|-----|
| Tile at grid position (x, y) | **2D array** — positions are dense, bounded |
| Entity by slot index | **array** (`[MAX_ENTITIES]Entity`) — see `sauce/entity.odin` |
| Item counts by item name | **map[string]int** — sparse, unbounded keys |
| Config values by name | **map** — arbitrary string keys |
| Sound handle by sound name | **map[Sound_Name]Handle** — enum keys, sparse |
| Tile kind for a char in level text | small **map[u8]Tile_Kind** or a switch |

Rule of thumb: if keys are dense integers from 0..N, use an array —
it is faster (no hashing) and cache-friendly. If keys are sparse,
arbitrary, or strings, use a map.

Production engines (including `sauce/`) prefer arrays + indices for
hot paths (entities, particles, tiles) and maps for cold paths
(asset lookup by name, config).

### Enum keys — best of both worlds

A common game pattern: map keyed by enum.

```odin
Sound :: enum { jump, land, push, win }

volumes := map[Sound]f32{
    .jump = 0.8,
    .land = 1.0,
    .push = 0.5,
    .win  = 1.0,
}
```

(For dense enum keys, Odin actually has something even better:
`[Sound]f32` — an **enumerated array**. Every enum value gets a slot,
no hashing, no allocation:)

```odin
volumes := [Sound]f32{
    .jump = 0.8,
    .land = 1.0,
    .push = 0.5,
    .win  = 1.0,
}
// no make, no delete — it is a fixed array!
```

If your key is an enum, prefer the enumerated array. Use a map only
when keys are sparse or unbounded.

### Maps of structs — modify carefully

A map lookup returns a **copy** of the value (value semantics, o04!):

```odin
Entity :: struct { hp: int }

entities := make(map[int]Entity)
defer delete(entities)
entities[1] = Entity{ hp = 10 }

e := entities[1]
e.hp -= 5            // modifies the COPY
// entities[1].hp is still 10!
```

To modify in place, use the pointer returned by indexing through `&`:

```odin
if e, ok := &entities[1]; ok {
    e.hp -= 5        // modifies the value INSIDE the map
}
```

This trips up every JS developer once. In JS, `map.get(1)` returns a
reference. In Odin, plain indexing copies.

---

## Line-by-Line: Solution Reference

Open:
- `learn/95_solutions/odin_for_js_devs/o17_maps_and_lookups/main.odin`

Line refs:
- map creation + defer delete: lines 10-12
- insert/update/lookup with ok: lines 14-23
- `in` operator + delete_key: lines 25-32
- iteration: lines 34-37
- inventory (map[string]int) demo: lines 39-52
- enumerated array vs map: lines 54-69
- in-place mutation with &: lines 71-84

After reading, close it.

---

## What Would Break If...

### You forgot `make` and wrote to a nil map?
```
runtime error: assignment to entry in nil map
```
Maps must be initialized with `make` or a literal before insertion.

### You forgot `delete(m)` after `make`?
No error — a memory leak. The tracking allocator (o09) reports it:
```
=== Memory leaks detected: ===
main.odin(8:9): leaked 256 bytes
```

### You relied on iteration order?
No error — but order changes between runs. If you need stable order,
collect keys into a dynamic array and sort it.

### You modified a struct from a plain map lookup?
No error — silent bug. You modified a copy (see Deep Dive). Use
`&entities[id]` to get a pointer into the map.

---

## Common JS-Developer Mistakes

1. **Expecting `undefined` for missing keys.**
   Odin gives the zero value plus an `ok` bool. Always use
   `v, ok := m[k]` when "missing" matters.

2. **Forgetting manual cleanup.**
   JS GC frees Maps. Odin does not. `make` pairs with `delete`.

3. **Relying on insertion order.**
   JS Maps iterate in insertion order. Odin maps are unordered.

4. **Using a map where an array fits.**
   JS devs use objects for everything. In Odin, dense integer or enum
   keys want an array (`[N]T` or `[Enum]T`) — faster, no allocation.

5. **Mutating through a lookup copy.**
   `e := m[k]; e.hp -= 5` changes nothing in the map. Use `&m[k]`.

---

## Mental Model

A map is a **warehouse with a hashing clerk:**

```
you: "give me box for key 42"
clerk: hashes 42 -> shelf 7 -> "here is a PHOTOCOPY of box contents, and ok=true"
you: "give me box for key 999"
clerk: hashes 999 -> shelf empty -> "here is an EMPTY box, and ok=false"
```

The clerk never says `undefined`. He always hands you a box — the `ok`
flag tells you whether it came from the shelf or was conjured empty.

If you want to write into the real box on the shelf, you must ask for
its address: `&m[k]`.

An enumerated array `[Enum]T` is a **pigeonhole cabinet** — one slot
per enum value, no clerk, no hashing, instant access.

---

## Exercises

### Exercise 1 — Item Counts
Create `inventory := make(map[string]int)` (remember `defer delete`).
Add "potion" = 3, "key" = 1. Increment "potion" by 1.
Print the count of "potion" and the count of "sword" (missing key —
show both the zero value and the `ok` flag).

### Exercise 2 — Existence And Removal
Using the inventory from Exercise 1: check `"key" in inventory`,
print a message, then `delete_key` it and check again.

### Exercise 3 — Enumerated Array
Define `Sound :: enum { jump, land, win }`.
Create `volumes := [Sound]f32{ .jump = 0.8, .land = 1.0, .win = 0.6 }`.
Loop over the enum (o05!) and print each sound's volume.
Note in a comment why this needs no `make`/`delete`.

### Exercise 4 — Mutate In Place
Create `map[int]Entity` where `Entity :: struct { hp: int }`.
Insert entity 1 with hp 10. Damage it by 4 **through the map** using
`&`. Print the hp from the map to prove it changed.
Then do the same with a plain (copy) lookup and prove it did NOT change.

---

## Exit Criteria

- [ ] You can create a map with `make` and clean it up with `delete`
- [ ] You can insert, update, look up with `(value, ok)`, and `delete_key`
- [ ] You can iterate a map and explain why order is unreliable
- [ ] You can choose between map, fixed array, and enumerated array `[Enum]T`
- [ ] You can mutate a struct value inside a map using `&m[k]`
- [ ] You can explain why `e := m[k]; e.hp -= 5` is a silent bug

---

## Why This Matters For Game Dev

Maps appear in every game's cold paths:

```odin
// asset lookup
textures: map[string]Texture_Handle

// sound config
volumes: map[Sound_Name]f32

// save data
flags_seen: map[string]bool
```

And just as important — knowing when NOT to use them. `sauce/entity.odin`
stores entities in a flat array, not a map, because the entity loop runs
every frame and arrays are cache-friendly. Tile grids are 2D arrays.
Particles are pools. Maps are for sparse, name-keyed, low-frequency data.

Choosing the right container is half of data-oriented design.

---

## Next Lesson

`learn/10_odin_for_js_devs/o18_unions_and_variants`
