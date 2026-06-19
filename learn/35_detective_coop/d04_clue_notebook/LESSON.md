# D04 — Clue Notebook

## Goal

Evidence is useless until it's recorded. Build a **shared notebook**: clues
discovered (by inspecting items in d02, or dialog choices in d03) get logged as
entries you can open, browse, and **pin** for later deduction (d05). This is the
detective's memory and the bridge between the two players.

---

## The Concept

A notebook is a **catalog of all possible clues + a "discovered" flag each**.
This is the single most reusable trick in this genre: define every clue up
front as data; "finding" a clue just flips its flag.

```odin
Clue :: enum { none, shaky_alibi, knife_weapon, photo_address, muddy_boots }

Clue_Entry :: struct {
    title:    string,
    body:     string,   // shown when the entry is opened
}
CLUES := [Clue]Clue_Entry{ ... }   // the catalog (data)

discovered: [Clue]bool             // runtime: which are found
pinned:     [Clue]bool             // runtime: which are pinned for deduction
```

The notebook UI is then just:
- a **list** of discovered entries (skip undiscovered),
- click an entry → open it (show `body`),
- a **pin** toggle per entry (used by d05's deduction).

### Why a fixed catalog + flags?

Same pattern as hotspots, recipes, dialog nodes: **content is data, runtime is
flags**. It makes save/load trivial (`discovered` is just a bit-set), makes the
co-op handoff clean (B reads the same catalog A fills), and lets you query
"do we have clue X?" anywhere.

### One source of truth

Both the inspect system (d02) and the dialog system (d03) call ONE function:
`discover(clue)`. The notebook reads `discovered`. No clue lives in two places.

---

## If You Know JS/React...

A catalog of clues = a constant array. `discovered`/`pinned` = two `Set`s in
state. The notebook = a list view that filters by `discovered.has(id)`, with a
detail pane and a pin toggle. Plain data + flags, no framework needed.

---

## Key Concepts

### Discover (the single entry point)
```odin
discover :: proc(c: Clue) {
    if c != .none && !discovered[c] {
        discovered[c] = true
        // (later: also push a notification / sound)
    }
}
```

### Open notebook + select entry
```odin
notebook_open: bool
opened_clue: Clue = .none   // which entry's body is shown
```

### Pin for deduction
```odin
pinned[c] = !pinned[c]
```

### List only discovered, stable order
```odin
for c in Clue {
    if c == .none || !discovered[c] { continue }
    // draw a row for c
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/detective_coop/d04_clue_notebook/main.odin`.

- Read `Clue`, `Clue_Entry`, `CLUES` catalog + `discovered`/`pinned`.
- Read `discover` — the one place clues enter the system.
- Read `frame`: TAB toggles the notebook; the entry list draws only
  discovered clues; clicking a row opens its body; the pin box toggles `pinned`.
- This demo "discovers" clues with number keys to simulate d02/d03 feeding it.

---

## Exercises

1. Add a clue `muddy_boots` with a body; discover it with a key for testing.
2. Show a small badge count "3/5 clues found" computed from `discovered`.
3. Sort pinned clues to the top of the list.
4. Add a search/filter: only show clues whose title starts with a typed letter.

---

## Exit Criteria

- [ ] Clues are a fixed catalog (data) + `discovered`/`pinned` flags
- [ ] One `discover` function is the only way a clue enters
- [ ] The notebook lists only discovered clues and opens their body
- [ ] You can pin/unpin a clue
- [ ] It builds and runs

---

## Next Lesson

`learn/35_detective_coop/d05_clues_deduction`
