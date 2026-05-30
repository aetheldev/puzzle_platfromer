# T07 — Tilemap

## Goal

Represent a game level as a 2D grid of tiles. Load it from text.
Collide the player against solid tiles.

---

## The Concept

A tilemap is a 2D array where each cell represents a type of tile:
empty, wall, goal, spike, etc. This is the foundation of grid-based
games: Sokoban, puzzle rooms, many platformers, many roguelikes.

Instead of placing individual collision boxes, you define a grid.
Collision becomes: "which grid cell is the player overlapping? Is it
solid?" This is fast, simple, and very designer-friendly.

---

## If You Know JS/React...

In web dev, layout is done with CSS grid or flexbox:
```css
.grid { display: grid; grid-template-columns: repeat(10, 40px); }
```

A tilemap is the game equivalent — but you manage it yourself as a 2D
array, not CSS. You calculate positions: `x = col * TILE_SIZE`,
`y = row * TILE_SIZE`. You check collision with array lookups, not DOM
intersection.

Closest web analogy: a pixel art editor's grid model, or a spreadsheet
where each cell has a type.

---

## Key Concepts

### Level as text
```
##########################
#........................#
#........##..............#
#...........####.........#
#....#.......S...........#
##########################
```

`#` = wall, `.` = empty, `S` = spawn. Human-readable. Easy to edit.
Same format your editor (T11) exports.

### Array storage
```odin
tiles: [ROWS][COLS]u8   // 0=empty, 1=solid
```

Small, fast, cache-friendly. A 100x20 level = 2000 bytes.

### Tile index math
```odin
col := int(world_x / TILE_SIZE)
row := int(world_y / TILE_SIZE)
```

Convert world position to grid index. Core operation for collision.

### Collision resolution
Test player corners against grid. If any corner is inside a solid
tile, push the player out. Resolve X and Y separately to avoid
corner-catching bugs.

---

## Line-by-Line Breakdown

Open:
- `learn/95_solutions/fundamentals/t07_tilemap/main.odin`

### Lines 75-90: `load_level`
Iterates text string line by line. For each character, sets tile type
and records spawn position.

### Lines 92-95: `is_solid`
Returns true if tile at (col,row) is solid. Treats out-of-bounds as solid.

### Lines 147-186: `resolve_axis`
Tests all 4 player corners against tiles. Resolves by smallest overlap.
X and Y resolved in separate passes to prevent diagonal sticking.

---

## Exercises

### Exercise 1 — Load And Draw
Define a text level. Parse it into the tile array. Draw each tile as
a colored rectangle.

### Exercise 2 — Player Collision
Move the player. Collide against solid tiles using corner checks.

### Exercise 3 — New Tile Type
Add spike tiles (`!`). Draw them differently. Reset player on contact.

### Exercise 4 — Design A Room
Design a small platforming room as text. Test it plays well.

---

## Exit Criteria

- [ ] Level loads from text string
- [ ] Tiles draw correctly
- [ ] Player collides with walls
- [ ] You can add new tile types
- [ ] You understand tile index math

---

## Next Lesson

`learn/30_fundamentals/t08_camera`
