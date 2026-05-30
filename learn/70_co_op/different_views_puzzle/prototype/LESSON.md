# Co-op Asymmetric Puzzle — Project Lesson

## Goal

Build a local 2-player puzzle where each player has different collision
rules. One sees bridges the other cannot walk on. Communication is the
core mechanic.

---

## The Concept

Good co-op puzzle design is NOT "two players do the same thing."
It is "each player has incomplete information or incomplete ability."

This prototype:
- Red player (WASD) can walk on red bridges, not blue
- Blue player (arrows) can walk on blue bridges, not red
- Both must stand on their pressure plates to open a door
- Both must reach goal tiles to win

The FUN comes from communication: "I can see a path on my side, can
you reach the plate on yours?"

---

## If You Know JS/React...

In React, you might render different views per user with conditional
rendering:
```jsx
{player.role === "red" && <RedBridges />}
{player.role === "blue" && <BlueBridges />}
```

In this game prototype, both players see everything on one screen.
The asymmetry is in collision, not visibility:

```odin
tile_blocks_player :: proc(tile: Tile, p: Player) -> bool {
    switch tile {
    case .bridge_red:  return !p.uses_red    // blocks blue
    case .bridge_blue: return p.uses_red     // blocks red
    case .door:        return !door_open
    }
}
```

Same world. Different rules per player. Simple code, deep puzzle design.

---

## Architecture

### Data model
```odin
tiles: [ROWS][COLS]Tile    // wall, bridge_red, bridge_blue, plate, door, goal
red: Player                // WASD
blue: Player               // arrows
door_open: bool
```

### Collision
Each player checks tiles against their role. Red passes through
red bridges, blocked by blue. Vice versa.

### Win condition
```odin
won = door_open && red.on_goal && blue.on_goal
```

Both plates pressed → door opens. Both on goal → win.

---

## Read The Solution

Open:
- `learn/95_solutions/co_op/different_views_puzzle/prototype/main.odin`

Key sections:
- `Tile` enum: lines 33-41
- `tile_blocks_player`: lines 114-127
- `try_move`: lines 129-137
- `update_game_state`: lines 139-147

---

## Exercises

### Exercise 1 — Two Players
WASD for red, arrows for blue. Both move independently.

### Exercise 2 — Asymmetric Bridges
Red-only and blue-only bridges with per-player collision.

### Exercise 3 — Shared Door
Both on plates → door opens.

### Exercise 4 — Win Condition
Both reach goal after door opens.

### Exercise 5 — New Room (Challenge)
Design a room where red must guide blue verbally.

---

## Exit Criteria

- [ ] Two players move with separate controls
- [ ] Per-player collision rules work
- [ ] Shared puzzle state (door) works
- [ ] Win condition requires both players
- [ ] You can explain what makes this asymmetric

## Sauce Goal

When this works, read:
- `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`
- `learn/50_advanced/a13_coop_game_in_sauce_plus_fx.md`

Then rebuild inside `sauce/game.odin`.
