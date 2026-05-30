# T02 — Shapes And Colors

## Goal

Draw colored rectangles and lines on screen using `sokol_gl`, Sokol's
immediate-mode drawing helper. This is how you see your game before
you have sprites or textures.

---

## The Concept

Before sprites, animations, or textures, games start with colored shapes.
A rectangle can be a player, a wall, a health bar, a card. Lines can be
beams, grid borders, debug visualizations.

`sokol_gl` (imported as `sgl`) is an immediate-mode drawing layer that
sits on top of `sokol_gfx`. You tell it what to draw each frame, it
draws it, and forgets everything. Next frame, you tell it again.

This is the "immediate mode" concept from g03.

---

## If You Know JS/React...

HTML Canvas 2D is the closest web equivalent:

```js
const ctx = canvas.getContext("2d");
ctx.fillStyle = "rgb(220, 60, 60)";
ctx.fillRect(50, 50, 200, 120);    // draw rectangle
ctx.beginPath();
ctx.moveTo(0, 500);
ctx.lineTo(960, 500);
ctx.stroke();                       // draw line
```

`sokol_gl` works similarly but talks to the GPU instead of a 2D canvas
software renderer. The key concepts map directly:

| Canvas 2D | sokol_gl |
|-----------|----------|
| `fillRect(x,y,w,h)` | `sgl.begin_quads()` + 4 vertices |
| `fillStyle = color` | color per vertex via `sgl.v2f_c4b()` |
| `beginPath/lineTo/stroke` | `sgl.begin_lines()` + 2 vertices |
| Canvas state persists | Everything cleared each frame |

---

## Key Concepts

### `sgl.ortho()` — set up 2D projection
```odin
sgl.ortho(0, W, H, 0, -1, 1)  // left, right, bottom, top, near, far
```
Maps pixel coordinates: (0,0) = top-left, (W,H) = bottom-right.
Without this, coordinates would be in GPU clip space (-1 to +1),
which is useless for pixel-based 2D games.

This is like setting up the Canvas 2D coordinate system. The difference:
Canvas does it automatically. Sokol requires you to set it explicitly.

### `sgl.begin_quads()` — start drawing rectangles
```odin
sgl.begin_quads()
sgl.v2f_c4b(x,   y,   r, g, b, 255)   // top-left vertex
sgl.v2f_c4b(x+w, y,   r, g, b, 255)   // top-right
sgl.v2f_c4b(x+w, y+h, r, g, b, 255)   // bottom-right
sgl.v2f_c4b(x,   y+h, r, g, b, 255)   // bottom-left
sgl.end()
```

Each quad needs 4 vertices. Each vertex has position (x,y) and color
(r,g,b,a as u8 bytes 0-255). `v2f_c4b` = "2 floats + 4 bytes."

### `sgl.begin_lines()` — start drawing lines
```odin
sgl.begin_lines()
sgl.v2f_c4b(x0, y0, r, g, b, 255)
sgl.v2f_c4b(x1, y1, r, g, b, 255)
sgl.end()
```

Every 2 vertices = 1 line segment.

### `sgl.draw()` — flush to GPU
Call this INSIDE `sg.begin_pass` / `sg.end_pass` to actually render
everything you submitted.

---

## Line-by-Line Breakdown

Open:
- `learn/95_solutions/fundamentals/t02_shapes_colors/main.odin`

### Lines 64-72: `draw_rect` helper
```odin
draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
    sgl.begin_quads()
    sgl.v2f_c4b(x,   y,   r, g, b, 255)
    sgl.v2f_c4b(x+w, y,   r, g, b, 255)
    sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
    sgl.v2f_c4b(x,   y+h, r, g, b, 255)
    sgl.end()
}
```

4 vertices form a rectangle. Vertex order matters: counter-clockwise
from top-left. Color is the same for all vertices here, but you COULD
give each corner a different color for gradient effects.

### Lines 81-123: `frame`
Sets up projection, draws shapes, calls `sgl.draw()` inside the pass.
Notice: `sgl.defaults()` and `sgl.matrix_mode_projection()` reset
state each frame. Immediate mode = no leftover state from last frame.

---

## What Would Break If...

### You forgot `sgl.setup(...)`?
sokol_gl is not initialized. All sgl calls crash.

### You forgot `sgl.ortho(...)`?
Coordinates are in clip space (-1 to +1). Your rectangles at pixel
coordinates like (50, 50, 200, 120) would be off-screen.

### You forgot `sgl.draw()` inside the pass?
All submitted geometry is lost. Nothing appears.

### You submitted only 3 vertices for a quad?
Incomplete quad. Either missing triangle or garbage rendering.

### You called `sgl.draw()` OUTSIDE begin_pass/end_pass?
Undefined behavior. Draw must happen within a render pass.

---

## Common Mistakes

1. **Forgetting `sgl.setup()`** — must be called AFTER `sg.setup()`.
2. **Forgetting `sgl.draw()`** — geometry submitted but never rendered.
3. **Wrong vertex order** — quad looks wrong or does not appear.
4. **Using 0-1 floats for color in `v2f_c4b`** — `c4b` takes u8 (0-255).
   Use `v2f_c4f` for 0-1 float colors.
5. **Not resetting sgl state each frame** — call `sgl.defaults()` at
   start of frame.

---

## Performance Note

sokol_gl batches all your quads and lines into one or a few GPU draw
calls. Drawing 500 rectangles per frame is cheap. Drawing 50,000 might
start to matter. For learning and puzzle games, you will never hit
performance limits with sokol_gl.

---

## Exercises

### Exercise 1 — One Rectangle
Clear the screen. Draw one colored rectangle. That is your "player."

### Exercise 2 — Multiple Shapes
Draw a floor line, a player rectangle, and a health bar rectangle
with different colors.

### Exercise 3 — Moving Shape
Use `sapp.frame_count()` to make one rectangle slide horizontally.
Hint: `f32(sapp.frame_count()) * 0.5` gives a slow horizontal offset.

### Exercise 4 — Grid
Draw a 3x3 grid of rectangles with alternating colors. Use nested
loops and math to calculate positions.

### Exercise 5 — Health Bar
Draw a background bar (dark) and a foreground bar (bright) on top.
The foreground width should be a percentage of some "health" value.

---

## Exit Criteria

- [ ] You can draw rectangles with `draw_rect` or raw `sgl` calls
- [ ] You can draw lines
- [ ] You understand `sgl.ortho()` sets up 2D coordinates
- [ ] You understand the submit-then-flush pattern
- [ ] You can use `sapp.frame_count()` to animate position
- [ ] You relate this to Canvas 2D `fillRect`

---

## Why This Matters

Every game in this repo draws with colored quads. Sokoban tiles are
quads. Cards are quads. Players are quads. Particles are quads.

Before you have sprites, quads and lines give you everything you need
to prototype any game idea. The entire Sokoban, card game, and co-op
prototype in this repo use only `draw_rect`.

---

## Next Lesson

`learn/30_fundamentals/t03_movement`
