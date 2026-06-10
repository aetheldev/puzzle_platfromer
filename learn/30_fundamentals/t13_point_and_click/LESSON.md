# T13 — Point And Click

## Goal

Build a one-room Rusty-Lake-style escape scene: click a painting to
reveal a key, unlock a drawer, read a color code, press door buttons
in order, escape. This is the core tech of every point-and-click
adventure and escape-room game.

---

## The Concept

A point-and-click game is three small ideas glued together:

1. **Hit-testing** — "which object is under the mouse?"
   One function: point-in-rect. That is the entire engine.
2. **Hotspots as data** — clickable regions live in an array/table,
   not scattered in code. Adding an object = adding a table entry.
3. **State flags drive everything** — `painting_moved`, `drawer_open`,
   `held == .key`. What you SEE and what clicks DO both read the same
   flags. The scene is a pure function of state.

No physics, no gravity, no collision response. Technically SIMPLER
than the platformer lessons — which is why escape-room games are a
great first shipped game.

---

## If You Know JS/React...

In the browser, the DOM does hit-testing for you:

```jsx
<img src="painting.png" onClick={() => setPaintingMoved(true)} />
{paintingMoved && !keyTaken &&
  <img src="key.png" onClick={takeKey} />}
```

The browser figures out what you clicked. React re-renders from state.

In a game you own both halves:

- Hit-testing: YOU loop over hotspot rects and test the mouse point.
- Rendering: YOU draw the scene from state flags every frame.

Same architecture — state down, events up — but no DOM in the middle.
Notice the conditional render `{paintingMoved && !keyTaken && ...}`
maps 1:1 to the `hotspot_active` proc in the solution.

---

## Key Concepts

### Point-in-rect — the whole "engine"

```odin
point_in_rect :: proc(px, py: f32, r: Rect) -> bool {
    return px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h
}
```

### Hotspots as a table (enumerated array — o17!)

```odin
Hotspot_Id :: enum { painting, key, drawer, btn_red, btn_green, btn_blue, door }

HOTSPOTS := [Hotspot_Id]Rect{
    .painting = {120, 120, 140, 110},
    .key      = {150, 250, 60, 26},
    // ...
}
```

### Click resolution — topmost first

Objects overlap (the key sits in front of the painting). Test in
front-to-back order, first hit wins:

```odin
ids := [?]Hotspot_Id{ .door, ..., .key, .painting }  // front -> back
for id in ids {
    if hotspot_active(id) && point_in_rect(mouse_x, mouse_y, HOTSPOTS[id]) {
        return id, true
    }
}
```

### State flags + one-slot inventory

```odin
painting_moved, key_taken, drawer_open, door_open: bool
held: Held_Item   // .nothing or .key — "what is in your hand"
```

Click logic is a switch on the hotspot, reading/writing these flags.
Click drawer: locked unless `held == .key`. Classic adventure logic,
a few lines each.

### Ordered sequence win condition

```odin
CODE := [3]Hotspot_Id{.btn_green, .btn_red, .btn_blue}
code_progress: int   // resets to 0 on wrong press
```

The exact pattern behind SAW-style "do these in the right order"
puzzles.

---

## Line-by-Line Breakdown

Solution: `learn/95_solutions/fundamentals/t13_point_and_click/main.odin`

### Lines 42-44: `point_in_rect`
The single most important proc in the genre.

### Lines 47-66: `Hotspot_Id` + `HOTSPOTS` table
Clickable world as data. `[Hotspot_Id]Rect` is the enumerated array
from o17 — no map, no allocation.

### Lines 68-88: state flags, `Held_Item`, `CODE`
The entire game state. Note how small it is.

### Lines 100-143: `press_button` + `interact`
All gameplay. A switch per hotspot, guarded by flags. This is where
"use key on drawer" lives.

### Lines 145-165: `hotspot_active` + `hotspot_under_mouse`
Visibility rules + front-to-back click resolution.

### Lines 186-205: `event`
Mouse move + one-frame `clicked` flag. Compare t11: same shape.

### Lines 213-...: `frame`
Resolve click, then draw scene purely from flags: door, buttons,
drawer + note, key (only if revealed and not taken), painting
(slides when moved), hover outline, inventory bar, progress pips.

---

## Exercises

### Exercise 1 — Run And Escape
Run it. Escape the room without reading the code spoiler in main.odin.
Then press R and speedrun it.

### Exercise 2 — Add A Hotspot
Add a rug. Clicking it toggles `rug_moved`. Under it: a coin that can
be picked up (inventory shows it). You will touch: enum, HOTSPOTS
table, `hotspot_active`, `interact`, drawing. Notice how mechanical
adding content is — that is the point of hotspots-as-data.

### Exercise 3 — Two-Step Lock
Make the drawer need the key AND the painting still moved (the keyhole
is only reachable while the painting is aside). One extra condition in
`interact`. Feel how flags compose into puzzle logic.

### Exercise 4 — Randomize The Code
On `init`, shuffle `CODE` (use `core:math/rand`). Print nothing.
The note is now the ONLY way to learn the order — like a real
escape room. (Bonus: draw the note colors from `CODE` instead of
hard-coding them, so the note never lies.)

### Exercise 5 — Describe, Partner Solves
Co-op preview: cover the right half of your screen. Have a friend
look only at the note and tell you the order while you press buttons.
You just played your detective game's core loop with zero networking.

---

## Exit Criteria

- [ ] You can write point-in-rect hit-testing from memory
- [ ] You can add a new hotspot end-to-end in under 5 minutes
- [ ] You can explain why hotspots are a data table, not if-chains
- [ ] You can explain how state flags drive both visuals and click logic
- [ ] You can build an ordered-sequence puzzle with reset-on-mistake

---

## Why This Matters

This is the genre tech for your two-detective escape game:

- Every room = a `HOTSPOTS` table + a handful of flags
- Every puzzle = conditions over flags (`o19 bit_set` when they grow)
- "One player sees the hint, the other acts" = Exercise 5, formalized
- The `interact` switch becomes your `Player_Intent` verb list when
  networking arrives (Ticket 075): a click is just an intent
  `{action = .interact, target = .drawer}` — trivially serializable

A platformer needs feel-tuning to be good. A point-and-click needs
puzzle DESIGN to be good. Code-wise, you now have everything.

---

## Next Lesson

`learn/60_projects/sokoban/LESSON.md`
(and when you wonder how this becomes two windows / online:
`learn/85_networking/06_two_windows_local_to_network.md`)
