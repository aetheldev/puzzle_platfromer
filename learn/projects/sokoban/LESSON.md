# Sokoban — Project Lesson

## Goal

Build a complete grid-based push-puzzle game. This bridges fundamentals
into a real game with rules, win conditions, and level design.

---

## The Concept

Sokoban rules:
1. Player moves one grid step at a time
2. Player can push one box at a time
3. Boxes cannot be pulled
4. Goal: push all boxes onto goal tiles
5. Reset if stuck

This is one of the best first puzzle games because:
- Rules are simple and complete
- Level design is the creative challenge
- Grid logic is clean and debuggable
- Directly extends T07 (tilemap) knowledge

---

## If You Know JS/React...

In React, you might model this as:
```jsx
const [grid, setGrid] = useState(initialGrid);
const [playerPos, setPlayerPos] = useState({x: 3, y: 5});
const handleMove = (dx, dy) => {
  // Check walls, push boxes, update state...
  setGrid(newGrid);
  setPlayerPos(newPos);
};
```

In Odin, same logic but:
- Grid is a 2D fixed array, not React state
- Player position mutated directly
- No re-render needed — next frame draws latest state
- Input is polled per-frame, not event handlers

---

## Architecture

### Data model
```odin
cells: [ROWS][COLS]Cell        // wall, empty, goal
boxes: [ROWS][COLS]bool         // box presence
player_x, player_y: int         // grid coordinates
```

Walls and goals are static tile data. Boxes are dynamic overlay.
Player is a single grid position. Clean separation.

### Move logic
```odin
try_move :: proc(dx, dy: int) {
    nx, ny := player_x + dx, player_y + dy
    if is_wall(nx, ny) { return }
    if has_box(nx, ny) {
        bx, by := nx + dx, ny + dy
        if is_blocked(bx, by) { return }
        move_box(nx, ny, bx, by)
    }
    player_x, player_y = nx, ny
}
```

Check target cell. If box, check cell behind box. If clear, push.

### Win check
```odin
for each goal tile:
    if no box on it: return false
return true
```

---

## Read The Solution

Open:
- `learn/solutions/projects/sokoban/main.odin`

Key sections:
- `Cell` enum: lines 47-51
- `load_level`: lines 78-106
- `try_move`: lines 140-160
- `check_win`: lines 127-138

Read `levels/level_01.txt` to see level format.

---

## Exercises

### Exercise 1 — One Level
Load one level. Move player. Push one box.

### Exercise 2 — Win Detection
Check all goals covered. Print "Solved!" when done.

### Exercise 3 — Reset
Press R to reload current level.

### Exercise 4 — Multiple Levels
Load from array of level strings. N/P to switch.

### Exercise 5 — Design 3 Levels
Create 3 solvable levels. Test each one.

### Exercise 6 — Undo (Challenge)
Store history of moves. Press Z to step back one move.

---

## Exit Criteria

- [ ] Level loads from text
- [ ] Player moves on grid
- [ ] Box push works correctly
- [ ] Win detected
- [ ] Reset works
- [ ] You designed at least one original level

## Sauce Goal

When this works, read:
- `learn/production_with_sauce/03_sokoban_in_sauce.md`
- `learn/advanced/a11_sokoban_in_sauce_plus_fx.md`

Then rebuild inside `sauce/game.odin`.
