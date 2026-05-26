# T08 — Camera Follow

## Goal

Implement a smooth-following camera so levels can be larger than the
screen. Understand world space vs screen space.

---

## The Concept

When a level is bigger than the window, the player needs to see only
part of the world. A camera defines which part.

**World space:** coordinates in the full level (can be any size).
**Screen space:** what you see (0,0 to SCREEN_W, SCREEN_H).

The camera is simply an offset: subtract camera position from world
position to get screen position.

### Smooth follow with lerp
```odin
cam.x = lerp(cam.x, target_x, SPEED * dt)
```

Lerp (linear interpolation) moves toward the target. Fast when far,
slow when close. Creates an "elastic" feel. Higher SPEED = snappier.

---

## If You Know JS/React...

In CSS, `transform: translate()` or `scroll-to` moves the viewport.
In a game, you translate all draw coordinates manually:

```odin
sgl.translate(-cam.x, -cam.y, 0)
// Now all draw calls are offset by camera position
```

This is like setting `scrollLeft`/`scrollTop` on a container — but you
do it every frame with exact math.

---

## Key Concepts

### Camera target
```odin
target_x := player.x + player.w/2 - SCREEN_W/2
target_y := player.y + player.h/2 - SCREEN_H/2
```

Center camera on player.

### Camera clamping
```odin
cam.x = clamp(cam.x, 0, WORLD_W - SCREEN_W)
cam.y = clamp(cam.y, 0, WORLD_H - SCREEN_H)
```

Prevent showing outside the level bounds.

### sgl.push/pop matrix
```odin
sgl.push_matrix()
sgl.translate(-cam.x, -cam.y, 0)   // world-space drawing
// ... draw tiles, entities ...
sgl.pop_matrix()                     // back to screen-space
// ... draw HUD (not affected by camera) ...
```

---

## Line-by-Line Breakdown

Open:
- `learn/solutions/fundamentals/t08_camera/main.odin`

### Line 149: `lerp`
Simple formula: `a + (b - a) * t`. Core of smooth following.

### Lines 179-246: `frame`
Camera lerp → clamp → push matrix → draw world → pop → draw HUD.

---

## Exercises

### Exercise 1 — Wide Level
Make a level wider than the screen. Implement camera follow.

### Exercise 2 — Tune Lerp Speed
Try `LERP_SPEED = 2` (sluggish) and `LERP_SPEED = 30` (instant).
Find a value that feels good.

### Exercise 3 — HUD Element
Draw a progress bar in screen space (not affected by camera).

### Exercise 4 — Camera Bounds
Clamp camera so level edges are never visible.

---

## Exit Criteria

- [ ] Camera follows player smoothly
- [ ] Level is larger than screen
- [ ] World space and screen space differ
- [ ] HUD draws in screen space (unaffected by camera)
- [ ] Camera clamps to world bounds

---

## Next Lesson

`learn/fundamentals/t09_shaders_bloom`
