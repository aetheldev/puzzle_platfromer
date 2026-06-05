# Parallel-Worlds Co-op — Project Lesson (the BOKURA trick)

## Goal

Build a local 2-player puzzle where both players stand in the SAME world but SEE
two different worlds: one tech/future (robots), one nature (animals). Prove to
yourself it is one simulation drawn twice, not two worlds.

---

## The Concept

The thing that confused you: it LOOKS like two worlds, so it feels like there
must be two of everything. There is not.

- One tile grid = the TRUTH (collision, positions, logic).
- A `Theme` chosen at DRAW time = the LOOK (which sprite/color you draw).

Draw the one grid once per player, each with that player's theme. Same wall, two
costumes. That is the whole illusion.

Full write-up: `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md`.

---

## If You Know JS/React...

You already do this. Same data, different render based on a flag:

```jsx
const sprite = theme === "tech" ? tileTechSprite : tileNatureSprite;
return <Tile sprite={sprite} />;
```

The DATA (which tile, where, solid or not) is shared state. Only the rendered
output forks on `theme`. A game does the exact same thing, every frame, on the
GPU instead of the DOM.

---

## Architecture

### Data model
```odin
Theme :: enum { tech, nature }

Visual :: struct { color: [Theme][3]u8 }   // same tile, two looks
visuals := [Tile]Visual{ ... }             // costume table = the illusion

tiles: [ROWS][COLS]Tile   // ONE shared grid (the truth)
player_a: Player          // theme = tech, WASD
player_b: Player          // theme = nature, arrows
```

### The key proc
```odin
draw_world :: proc(viewer: Theme, origin_x: f32) {
    for tile in grid {
        c := visuals[tile].color[viewer]   // pick costume by viewer theme
        draw_rect(..., c)
    }
    // characters themed the same way: robot in tech view, animal in nature view
}
```

Called twice per frame: `draw_world(.tech, leftHalf)` and
`draw_world(.nature, rightHalf)`. Split screen, one grid, two worlds.

### Two layers of fork
- **Cosmetic:** delete the `nature_only_ground` / `tech_only_ground` collision
  cases → both players collide identically, only the look forks.
- **Truth:** keep them → some ground is solid in one world, void in the other.

```odin
tile_blocks_player :: proc(tile: Tile, p: Player) -> bool {
    #partial switch tile {
    case .wall:               return true
    case .nature_only_ground: return p.theme == .tech    // void for tech
    case .tech_only_ground:   return p.theme == .nature   // void for nature
    case:                     return false
    }
}
```

---

## Read The Solution

Open:
- `learn/95_solutions/co_op/parallel_worlds_puzzle/prototype/main.odin`

Key sections:
- `Theme` enum + `visuals` costume table: the illusion lives here
- `draw_world`: the once-per-viewer draw
- `draw_player`: same entity, themed avatar (robot vs animal)
- `tile_blocks_player`: Layer 2 truth fork

---

## Exercises

### Exercise 1 — See The Cosmetic Fork
Run it. Notice the SAME grid looks like two worlds. Confirm a wall is in the same
spot on both halves but a different color.

### Exercise 2 — Prove It Is One World
Move Player A (WASD). Watch their square move on the LEFT view. Now find that
same player on the RIGHT view (drawn as the partner). One entity, two avatars.

### Exercise 3 — Break Cosmetic Into Truth
The `n` and `t` tiles already fork collision. Make a room where Player A must
walk a `t` path Player B sees as void, and guide Player B across `n` tiles A
cannot see as ground.

### Exercise 4 — Add A Theme Costume
Give `wall` a third visual idea (e.g. tech = neon, nature = flowers) by editing
the `visuals` table. Change look only — confirm gameplay is unchanged.

### Exercise 5 — New Room (Challenge)
Design a room solvable ONLY by one player describing their world to the other.

---

## Exit Criteria

- [ ] You can explain why this is one simulation, not two worlds
- [ ] You can point to the single line that forks the look (`visuals[tile].color[viewer]`)
- [ ] Cosmetic fork works (same collision, different look)
- [ ] Truth fork works (ground in one world, void in the other)
- [ ] You can name how split screen becomes networking without changing the trick

## Next

- Mood: run each view through `learn/45_shaders_postfx/` (fog, CRT, grading, bloom).
- Production: rebuild inside `sauce/` — `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`.
