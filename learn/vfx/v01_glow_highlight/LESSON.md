# V01 — Glow Highlight

## Goal

Make selected or important objects glow using layered transparent quads.
Cheapest way to add visual importance without shaders.

---

## The Concept

Glow = several larger transparent copies of the object drawn behind it.
More layers and larger spread = stronger glow. This is "fake bloom" —
no render targets, no shaders, just alpha-blended quads.

Why glow matters:
- Shows which object is selected
- Draws attention to goals, interactables, exits
- Adds life to otherwise flat colored rectangles

---

## If You Know CSS...

In CSS: `box-shadow: 0 0 20px rgba(255, 200, 80, 0.5);`

In a game, you draw it manually:
```odin
for i in 0..<LAYERS {
    expand := f32(i) * spread
    alpha := base_alpha * (1 - f32(i)/f32(LAYERS))
    draw_rect_alpha(x-expand, y-expand, w+expand*2, h+expand*2, r, g, b, alpha)
}
```

Same visual result. Different implementation. Full control.

---

## Read The Solution

Open:
- `learn/solutions/vfx/v01_glow_highlight/main.odin`

Key section:
- `draw_glow_box`: lines 39-45

Notice how selected objects get more layers and wider spread.

---

## Exercises

### Exercise 1 — One Glowing Object
Draw a rectangle with 4 glow layers behind it.

### Exercise 2 — Selection
Left/right switches selection. Selected = stronger glow.

### Exercise 3 — Different Colors
Three objects with different glow colors.

### Exercise 4 — Pulse
Vary glow intensity with time using sine wave.

---

## Exit Criteria

- [ ] Layered glow visible
- [ ] Selection changes glow strength
- [ ] You can explain why many layers = better glow
- [ ] You understand this is "fake bloom"

---

## Next Lesson

`learn/vfx/v02_elemental_orbs`
