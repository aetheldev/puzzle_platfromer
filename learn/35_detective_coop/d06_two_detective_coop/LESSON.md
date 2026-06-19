# D06 — Two-Detective Co-op Case

## Goal

Put it ALL together into your milestone game: a single-screen, split-role
two-detective case. Detective A (mouse, left) works the crime scene — collects
and inspects evidence. Detective B (keyboard, right) works the notebook —
reviews clues and runs the deduction that cracks the case. Neither can finish
alone.

This is the capstone of d01–d05. No new engine — it's the systems you built,
wired together with **asymmetric roles**.

---

## The Concept

### One screen, two roles, two input devices

```
+----------------------------+---------------------------+
| FIELD (Detective A, mouse) | DESK (Detective B, keys)  |
|  crime scene + inventory   |  notebook + deduction     |
+----------------------------+---------------------------+
```

A's clicks discover clues (d02/d03 → `discover`, d04 catalog). B can ONLY see
and act on what A has discovered. B selects clues and deduces (d05). The win
requires a deduction that needs a clue only A can find — that's the forced
co-op.

### Everything is an "intent"

Each action is a tiny record:

```odin
Intent :: struct {
    who:    Role,           // .field or .desk
    action: Action,         // .pick, .inspect, .toggle_clue, .deduce
    target: int,            // index/id meaning depends on action
}
```

Both players write intents into the SAME game state. Today both come from one
keyboard+mouse; when networking arrives (Ticket 075), an intent is what you
send over the wire — no gameplay code changes. **Design for that now.**

### Asymmetric gating = real co-op

The final deduction's `needs` includes `photo_address`, which only appears when
A inspects the repaired photo. B sees the locked conclusion but can't reach it
until A does the field work and announces it. That information gap is the game.

---

## If You Know JS/React...

Two panels reading one shared store (like Redux), each dispatching actions
(`Intent`). One reducer applies them. Splitting input by device = two
"controllers" feeding one store. Networking later = the same actions, sent
remotely.

---

## Key Concepts

### Shared state, role-scoped input
```odin
// A (mouse) only touches the left half; B (keys) only the right.
case .MOUSE_DOWN: if mx < W/2 { field_click(mx, my) }
case .KEY_DOWN:   desk_key(e.key_code)   // 1-5 select clues, SPACE = deduce
```

### Reuse the subsystems
- inventory + inspect/combine → from d01/d02
- `discover` + notebook catalog → from d04
- `bit_set` deduction → from d05

### Win condition
```odin
if reached[.killer_identified] { state = .solved }
```

### A handoff prompt (teach communication)
When A discovers a clue, flash "Tell your partner!" — the game literally coaches
the table-talk that makes co-op fun.

---

## Line-by-Line Breakdown

Open `learn/95_solutions/detective_coop/d06_two_detective_coop/main.odin`.

- Read `Role`, `Intent`, and how `event` routes mouse→field, keys→desk.
- Read the FIELD half: scene hotspots, pickups, inspect → `discover`.
- Read the DESK half: clue chips (only discovered), `try_deduce`, win.
- Read `frame`: the screen split, both panels, the "tell your partner" nudge.

---

## Exercises

1. Add a clue only B's side can reveal (e.g. a phone B answers with a key),
   forcing the handoff BOTH directions.
2. Add a fail timer; if the deduction isn't reached in N seconds, the suspect
   walks. (Pressure makes co-op talk.)
3. Add a second room A can travel to (a hotspot that swaps the scene table).
4. Replace direct mutation with an `Intent` queue both halves push to, then a
   single `apply_intent` step — this is the exact shape networking needs.

---

## Exit Criteria

- [ ] One screen, two roles, two input devices, one shared state
- [ ] A's field work is the ONLY way to unlock B's final deduction
- [ ] Reuses inventory, inspect, discover, notebook, and bit_set deduction
- [ ] The case can be solved only by the two roles cooperating
- [ ] Every action is expressible as an `Intent` (networking-ready)
- [ ] It builds and runs

---

## Where This Goes Next

You shipped your milestone's core loop. From here:

- **Mood**: run the crime scene through `45_shaders_postfx` (darkness, fog,
  grading) — instant noir.
- **Art**: pre-render props in Blender (`47_graphics_programming/gp14-17`).
- **Online**: turn `Intent`s into network messages —
  `learn/85_networking/06_two_windows_local_to_network.md` (LAST, after this
  local version is fun).
- **Production**: rebuild inside the real engine —
  `learn/90_production_with_sauce/` and design notes in
  `learn/80_design/coop_lovers_puzzle/`.
