# D02 — Inspect & Combine Items

## Goal

Two more adventure staples: **inspect** an item up close (a modal zoom that can
reveal a hidden detail), and **combine** two items into a new one
(`torn_photo + tape = repaired_photo`). This is how detectives turn raw
evidence into clues.

---

## The Concept

### Inspect = a modal mode

A point-and-click usually has a *mode*: normal scene, or "inspecting item X".
You store the mode and draw differently:

```odin
Mode :: enum { scene, inspect }
mode: Mode
inspecting: Item
```

In inspect mode you draw the item big in the center, maybe with a clickable
detail hotspot ("there's writing on the back"). Clicking the detail can set a
flag or grant a clue. `Esc`/click background returns to `scene`.

### Combine = a tiny recipe table

Combining is a pure lookup: "item A + item B → result". Encode recipes as data,
not if-chains:

```odin
Recipe :: struct { a, b: Item, result: Item }
RECIPES := []Recipe{
    {.torn_photo, .tape, .repaired_photo},
    {.uv_light,   .note, .secret_message},
}
```

To combine: the player selects one item, then clicks another (or a "combine"
button). You look the pair up (order-independent), and if found, remove both
inputs and add the result.

```odin
try_combine :: proc(x, y: Item) -> (Item, bool) {
    for r in RECIPES {
        if (r.a == x && r.b == y) || (r.a == y && r.b == x) {
            return r.result, true
        }
    }
    return .none, false
}
```

This recipe-table approach scales: a 30-item adventure is just a bigger table.

---

## If You Know JS/React...

Inspect mode = a modal/lightbox component toggled by state. Combine = a lookup
in a `Map` of `"a+b" -> result`. You already think this way; here it is plain
data + a loop, no framework.

---

## Key Concepts

### Two-step combine UI
```odin
combine_first: int = -1   // first selected slot for combining
// click slot once -> combine_first = slot
// click another slot -> try_combine(inv[combine_first], inv[slot])
```

### Consume inputs, add result
```odin
if res, ok := try_combine(a, b); ok {
    // remove both inputs (remove the higher index first!), then:
    append(&inventory, res)
}
```
Remove the higher index first so the lower index stays valid.

### Inspect detail hotspot
```odin
case .inspect:
    if point_in_rect(mx, my, BACK_OF_PHOTO) {
        found_address = true   // a clue is revealed
    }
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/detective_coop/d02_inspect_combine/main.odin`.

- Read `Mode`, `inspecting`, and how `frame` branches on mode.
- Read `RECIPES` + `try_combine`.
- Read the combine flow in the click handler (first slot, then second slot).
- Read the inspect view: big item + a detail hotspot that reveals something.

---

## Exercises

1. Add a recipe: `key + file = filed_key` (a fake key that opens nothing —
   feedback matters).
2. In inspect mode, add a second detail hotspot that needs the `magnifier` in
   your bag to be visible.
3. Make combining the wrong pair print a witty "those don't go together".
4. Right-click a slot to inspect it; left-click to select. Two verbs, one bar.

---

## Exit Criteria

- [ ] You can enter/leave an inspect modal cleanly
- [ ] Inspecting can reveal a hidden detail (a flag/clue)
- [ ] Combine works from a data-driven recipe table, order-independent
- [ ] Combining consumes inputs and yields the result item
- [ ] It builds and runs

---

## Next Lesson

`learn/35_detective_coop/d03_dialog_system`
