# T11 — Level Editor Basics

## Goal

Build a simple in-game tile editor with mouse input. Paint tiles,
place spawns, export level text. First step toward your own tools.

---

## The Concept

Making content should be easy. A tile editor lets you click to paint
walls, goals, boxes, and spawn points. Pressing Enter prints the level
as text you can paste into level files.

This is the bridge between "I can program a game" and "I can design
levels for my game." Every shipped puzzle game needs tools.

---

## If You Know JS/React...

In React, you might build a tile editor with:
```jsx
<div className="grid" onClick={handlePaint}>
  {tiles.map((row, r) => row.map((cell, c) =>
    <div key={`${r}-${c}`} className={`tile tile-${cell}`} />
  ))}
</div>
```

Click handler updates state, React re-renders the grid. CSS styles
each tile type.

In a game:
- Mouse position from `sapp.Event`
- Convert mouse position → grid cell: `col = mouse_x / TILE`
- Set tile directly in array: `tiles[row][col] = selected_tool`
- Draw grid every frame (immediate mode)
- No React re-render. No DOM. Direct array manipulation.

---

## Key Concepts

### Mouse input
```odin
event :: proc "c" (e: ^sapp.Event) {
    mouse_x = e.mouse_x
    mouse_y = e.mouse_y
    if e.type == .MOUSE_DOWN && e.mouse_button == .LEFT {
        left_down = true
    }
}
```

### Screen → grid conversion
```odin
col := int(mouse_x / TILE)
row := int(mouse_y / TILE)
```

### Paint logic
```odin
if left_down {
    tiles[row][col] = selected_tool
}
if right_down {
    tiles[row][col] = .empty
}
```

### Export
```odin
print_level :: proc() {
    for row in 0..<ROWS {
        for col in 0..<COLS {
            switch tiles[row][col] {
            case .empty: // print '.'
            case .solid: // print '#'
            case .spawn: // print 'P'
            case .goal:  // print 'G'
            case .box:   // print 'B'
            }
        }
    }
}
```

---

## Line-by-Line Breakdown

Open:
- `learn/solutions/fundamentals/t11_level_editor_basics/main.odin`

### Lines 47-52: `Tile` enum
Defines all paintable tile types.

### Lines 90-106: `print_level`
Loops grid, maps enum to character, prints to terminal.

### Lines 108-133: `event`
Mouse tracking + tool selection (1-4 keys) + Enter to export.

### Lines 148-241: `frame`
Paint logic + grid drawing + hover highlight + toolbar indicators.

---

## Exercises

### Exercise 1 — Paint And Erase
Left click paints. Right click erases. Implement both.

### Exercise 2 — Multiple Tools
Keys 1-4 switch between wall, spawn, goal, box.

### Exercise 3 — Export To Terminal
Press Enter → print level text. Copy it. Use it in Sokoban.

### Exercise 4 — Grid Visual
Draw grid lines. Add hover highlight on mouse cell.

---

## Exit Criteria

- [ ] Mouse paint works
- [ ] Multiple tile tools selectable
- [ ] Export prints valid level text
- [ ] You understand screen → grid math
- [ ] You can explain why text export is a useful first tool

---

## Why This Matters

This is the bridge to level design. Every puzzle game needs content.
The faster you can make levels, the faster you can test ideas.

Later in `sauce/`, this becomes a real editor mode inside your game.

---

## Next Lesson

`learn/fundamentals/t12_integration_room` — combine everything you learned in
t01–t11 into one playable room. This is the bridge into building full games.
