# D01 — Multi-Slot Inventory

## Goal

t13 had a one-slot "hand" (`held: Held_Item`). A detective collects MANY pieces
of evidence. Build a real multi-slot inventory: pick up several items, see them
in a bar, select one, and use the selected item on a hotspot.

---

## The Concept

An inventory is just **a list of item ids + a selected index**. Everything else
is drawing and a couple of helpers.

```odin
Item :: enum { none, magnifier, key, photo, note }   // what exists
inventory: [dynamic]Item     // what you are carrying (order = pickup order)
selected: int = -1           // index into inventory, -1 = nothing selected
```

Three operations cover 90% of adventure games:

1. **pick up**: append an item, remove it from the world (a flag).
2. **select**: click an inventory slot → set `selected`.
3. **use on target**: click a hotspot while something is selected → the
   `interact` switch checks `selected_item()` and decides what happens.

The crucial idea from t13 still holds: **the scene is a pure function of
state**. Now the state includes a list, not a single value.

---

## If You Know JS/React...

```jsx
const [items, setItems] = useState([]);       // inventory: [dynamic]Item
const [selected, setSelected] = useState(-1); // selected: int
// pick up:
setItems([...items, "key"]);
```

A toolbar of selectable chips. React re-renders the bar from `items`; you draw
it every frame from `inventory`. Same "state down" model, no DOM.

---

## Key Concepts

### Pick up (guard with a world flag so you can't take it twice)
```odin
pick_up :: proc(it: Item) {
    append(&inventory, it)
}
```

### Selected item helper
```odin
selected_item :: proc() -> Item {
    if selected < 0 || selected >= len(inventory) { return .none }
    return inventory[selected]
}
```

### Click resolution: bar first, then scene
A click might land on the inventory bar OR the scene. Test the bar first:
```odin
if slot, ok := slot_under_mouse(); ok {
    selected = (selected == slot) ? -1 : slot   // click again to deselect
} else if id, ok := hotspot_under_mouse(); ok {
    interact(id)
}
```

### Use selected item in `interact`
```odin
case .drawer:
    if selected_item() == .key {
        drawer_open = true
        remove_selected()       // consume it
    }
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/detective_coop/d01_multi_inventory/main.odin`.

- Read `inventory`, `selected`, `selected_item`, `remove_selected`.
- Read `slot_rect` / `slot_under_mouse`: the bar as data, like hotspots.
- Read `frame`'s click resolution (bar before scene) and the bar drawing
  (selected slot gets a highlight).

---

## Exercises

1. Add a fourth pickup (a `photo`) somewhere in the scene.
2. Make the drawer need the `key` AND consume it; confirm it leaves the bar.
3. Click a selected slot again to DESELECT it. Verify the highlight clears.
4. Add a simple "you can't carry more than 6" guard and a message.

---

## Exit Criteria

- [ ] You can pick up several items into a list
- [ ] You can select a slot and see it highlighted
- [ ] "Use selected on target" works and can consume the item
- [ ] Click resolution checks the bar before the scene
- [ ] It builds and runs with `zsh build.sh`

---

## Next Lesson

`learn/35_detective_coop/d02_inspect_combine`
