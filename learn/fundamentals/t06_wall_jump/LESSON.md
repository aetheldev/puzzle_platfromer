# T06 — Wall Jump And Wall Slide

## Goal

Detect wall contact, slow falling while touching a wall, and jump
away from walls. Combines spatial detection with movement rules.

---

## The Concept

Wall mechanics have three parts:

**1. Wall detection:** Check if the player is touching a wall by
probing a few pixels to the left and right. If probe overlaps a solid
object, player is touching that wall.

**2. Wall slide:** When airborne and touching a wall, cap downward
velocity to a small value. Player "sticks" and slides slowly instead
of falling at full speed.

**3. Wall jump:** When touching a wall and jump is pressed, launch the
player away from the wall at an angle. Brief input lock prevents the
player from immediately grabbing the same wall again.

---

## If You Know JS/React...

There is no direct web equivalent. But the concept maps to:
- **Intersection detection** — like checking if two DOM elements overlap
  (but with manual math, not `getBoundingClientRect`)
- **State machine** — player has states: grounded, airborne, wall-sliding
- **Timed lock** — like disabling a button for 200ms after click

---

## Key Concepts

### Wall probe
```odin
probe_left  := Rect{ player.x - 2, player.y + 4, 2, player.h - 8 }
probe_right := Rect{ player.x + player.w, player.y + 4, 2, player.h - 8 }
// Check each probe against all walls
```

Small rectangles beside the player. If they overlap a wall, player is
touching. The `+4` and `-8` trim the probe vertically to avoid
false-positive corner catches.

### Wall slide
```odin
if wall_dir != 0 && vel_y > WALL_SLIDE_VEL {
    vel_y = WALL_SLIDE_VEL   // cap fall speed
}
```

### Wall jump
```odin
if on_wall && jump_pressed {
    vel_x = -wall_dir * WALL_JUMP_X   // push away
    vel_y = WALL_JUMP_Y               // push up
    wall_jump_timer = WALL_JUMP_LOCK  // brief input lock
}
```

---

## Line-by-Line Breakdown

Open:
- `learn/solutions/fundamentals/t06_wall_jump/main.odin`

### Lines 92-117: `event`
Same held-key pattern. Jump buffer on space.

### Lines 119-234: `frame`
Wall probes → wall direction → slide cap → wall jump → gravity →
integration → AABB collision resolution. This is the most complex
fundamental lesson. Read it carefully.

---

## Common Mistakes

1. **Not locking input after wall jump** — player snaps back to wall.
2. **Wall probe too large** — false detections on floors.
3. **Not checking airborne** — wall slide activates on ground.
4. **Wall direction wrong sign** — player launches into wall.

---

## Exercises

### Exercise 1 — Wall Detection
Add wall probes. Draw them as colored rectangles. See them light up
when touching a wall.

### Exercise 2 — Wall Slide
Cap fall speed while touching wall. Adjust WALL_SLIDE_VEL.

### Exercise 3 — Wall Jump
Launch away from wall on jump. Adjust X and Y push values.

### Exercise 4 — Remove Input Lock
Remove WALL_JUMP_LOCK. Notice how player sticks to the wall.
Re-add it. Adjust the duration.

---

## Exit Criteria

- [ ] Wall detection works via probes
- [ ] Wall slide slows falling
- [ ] Wall jump launches away from wall
- [ ] Input lock prevents instant re-grab
- [ ] You understand AABB overlap testing

---

## Next Lesson

`learn/fundamentals/t07_tilemap`
