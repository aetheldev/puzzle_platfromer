# G05 — Pixels, Not Divs

## Goal

Understand that games position everything in pixel coordinates with
math, not CSS layout. There is no flexbox, no grid, no margin, no
padding, no auto-sizing.

---

## How The Web Does Layout

CSS handles positioning:

```css
.container { display: flex; gap: 16px; }
.player { position: absolute; left: 100px; top: 200px; }
.health-bar { width: 80%; height: 20px; }
```

You describe relationships ("center this," "fill remaining space,"
"stack vertically"). The browser calculates final pixel positions.

You rarely think in exact pixel coordinates. `margin: auto` centers
things. `flex-grow: 1` fills space. Responsive design adjusts to any
screen size automatically.

---

## How Games Do Layout

You calculate pixel positions manually:

```odin
// Player position in world
player_x: f32 = 340.0
player_y: f32 = 220.0

// Draw at exact pixel position
draw_rect(player_x, player_y, 32, 48, 255, 200, 100)

// Health bar: positioned relative to screen
bar_x: f32 = 20
bar_y: f32 = 20
bar_width: f32 = f32(health) / f32(max_health) * 200
draw_rect(bar_x, bar_y, bar_width, 16, 255, 80, 80)

// Center something on screen
centered_x := f32(SCREEN_W) / 2 - box_w / 2
centered_y := f32(SCREEN_H) / 2 - box_h / 2
```

No CSS. No layout engine. No auto-sizing. Just math.

---

## Coordinate Systems

### Screen space (0,0 = top-left)

```
(0,0) ────────────────── (960, 0)
  │                          │
  │                          │
  │     (480, 270)           │
  │        center            │
  │                          │
(0,540) ──────────────── (960, 540)
```

- X increases rightward
- Y increases downward (opposite of math class!)
- (0,0) is top-left corner

### World space (game coordinates)

If your level is bigger than the screen, you have a separate world
coordinate system. The camera transforms world → screen:

```
screen_x = world_x - camera_x
screen_y = world_y - camera_y
```

This is covered in T08 (Camera). For now, know that "world position"
and "screen position" are different things.

---

## Common Layout Tasks

### Center on screen
```odin
x := f32(W)/2 - width/2
y := f32(H)/2 - height/2
```

### Position relative to edge
```odin
// Top-right corner HUD
x := f32(W) - hud_width - margin
y := margin
```

### Grid layout (tilemap)
```odin
tile_x := f32(col * TILE_SIZE)
tile_y := f32(row * TILE_SIZE)
```

### Fan layout (card hand)
```odin
total_width := CARD_W + f32(card_count - 1) * spacing
start_x := f32(W)/2 - total_width/2
for card, i in hand {
    draw_card(start_x + f32(i) * spacing, hand_y, card)
}
```

All explicit math. All under your control.

---

## Why Manual Layout?

### Games need pixel-perfect control
An animation moving 2.5 pixels per frame needs exact positioning.
CSS rounding and layout reflow would interfere.

### Performance
CSS layout recalculation (reflow) is expensive. Games avoid it by
computing positions directly. No DOM, no reflow, no style cascade.

### Flexibility
You can position anything anywhere at any time. No layout constraints
to fight against. Want a card to fly across the screen? Just change
its x/y every frame.

---

## Mental Model

**CSS:** An architect draws floor plans with measurements like "center
this room" and "leave 2m from the wall." The builder figures out
exact positions.

**Game rendering:** You are the builder. You place every brick at exact
coordinates. No architect. No automatic spacing. You calculate
everything. But you can put bricks anywhere you want, any time.

---

## Exercises (Thinking, Not Coding)

1. Given a 960x540 screen, calculate where to place a 100x50 rectangle
   so it is perfectly centered.

2. Calculate the pixel positions for a 3x3 grid of 48px tiles, starting
   at (100, 100).

3. Explain why games use "Y increases downward" (hint: it matches how
   screens scan pixels).

---

## Exit Criteria

- [ ] You understand screen coordinates (0,0 = top-left)
- [ ] You can center objects with math
- [ ] You understand there is no CSS, no layout engine
- [ ] You can calculate grid, fan, and edge-relative positions

---

## Next Lesson

`g06_input_every_frame`
