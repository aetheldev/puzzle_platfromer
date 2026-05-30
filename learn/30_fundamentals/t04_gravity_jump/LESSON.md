# T04 — Gravity And Jumping

## Goal

Add gravity and a jump mechanic. Understand velocity-based motion
and why it creates natural-feeling movement.

---

## The Concept

In the real world, gravity accelerates objects downward. Games simulate
this by adding a constant value to vertical velocity each frame:

```
each frame:
    vel_y += GRAVITY * dt       ← velocity increases (falls faster)
    pos_y += vel_y * dt         ← position changes by velocity
```

Jumping works by setting `vel_y` to a large negative value (upward).
Gravity then slows the rise, stops it, and pulls the player back down.
This creates a natural arc without any animation curves or easing
functions — pure physics.

---

## If You Know JS/React...

In CSS/React, you might animate a jump with:
```js
element.animate([
  { transform: "translateY(0)" },
  { transform: "translateY(-100px)" },
  { transform: "translateY(0)" }
], { duration: 500, easing: "ease-out" });
```

This is a canned animation. It looks the same every time. You cannot
interrupt it mid-air. You cannot change gravity.

In a game, the jump is SIMULATED, not animated. The code computes
physics each frame. This means:
- You can change gravity mid-jump
- You can add wind or knockback
- You can interrupt with wall collision
- Variable jump height works naturally (release key early = shorter jump)

---

## Key Concepts

### Velocity vs position
- **Position** (`y`) = where the player IS
- **Velocity** (`vel_y`) = how fast the player is MOVING

Position changes by velocity. Velocity changes by acceleration (gravity).
This two-level system creates smooth natural motion.

### Gravity formula
```odin
player.vel_y += GRAVITY * dt    // accelerate downward
player.y += player.vel_y * dt   // integrate position
```

GRAVITY is positive (screen Y goes down). Typical value: 1200-2000 px/s^2.

### Jump
```odin
if jump_pressed && player.on_ground {
    player.vel_y = JUMP_VEL      // negative = upward
    player.on_ground = false
}
```

JUMP_VEL is negative (upward). Typical value: -500 to -700 px/s.

### Floor collision
```odin
if player.y + player.h >= FLOOR_Y {
    player.y = FLOOR_Y - player.h
    player.vel_y = 0
    player.on_ground = true
}
```

When bottom of player reaches floor: snap to surface, stop falling,
mark as grounded so jump is allowed again.

---

## Line-by-Line Breakdown

Open:
- `learn/95_solutions/fundamentals/t04_gravity_jump/main.odin`

### Lines 77-90: `event`
Single-frame jump flag. Key-down sets `jump_pressed = true`. Frame
consumes it. This prevents holding jump from re-triggering.

### Lines 92-147: `frame`
1. Horizontal movement
2. Jump check (only when grounded)
3. Gravity accumulation
4. Position integration
5. Floor collision
6. Drawing

---

## What Would Break If...

### You set vel_y directly to position instead of accumulating?
Player teleports instead of arcing. No natural fall.

### You forgot `on_ground` check?
Infinite air jumps. Player flies away.

### You forgot to reset vel_y on landing?
Velocity accumulates. Next frame, player launches through the floor.

### You made GRAVITY negative?
Player falls upward. Actually useful for gravity-puzzle games later.

---

## Common Mistakes

1. **Setting Y directly for jump** — use velocity, not teleportation.
2. **Allowing jump in mid-air** — check `on_ground`.
3. **Not consuming jump flag** — jump triggers every held frame.
4. **Too high GRAVITY** — player slams down instantly.
5. **Too low JUMP_VEL** — player barely leaves ground.

---

## Tuning Guide

| Feel | GRAVITY | JUMP_VEL |
|------|---------|----------|
| Floaty (Celeste-like) | 1000 | -500 |
| Normal platformer | 1800 | -620 |
| Heavy (hard game) | 2500 | -750 |
| Moon gravity | 600 | -400 |

Experiment. Game feel is subjective. The right values are the ones
that feel good to YOU.

---

## Exercises

### Exercise 1 — Basic Jump
Implement gravity + one jump. Player should arc naturally.

### Exercise 2 — Tune The Feel
Try 5 different GRAVITY/JUMP_VEL combinations. Write down which
feels best and why.

### Exercise 3 — Add A Platform
Add a second "floor" higher up. Detect collision with it.

### Exercise 4 — Variable Jump Height (Preview)
When jump key is released mid-air, cut `vel_y` in half.
This makes taps give short jumps and holds give tall jumps.
(T05 expands on this.)

---

## Exit Criteria

- [ ] Gravity pulls player down naturally
- [ ] Jump creates a natural arc
- [ ] Player lands on floor correctly
- [ ] You can explain velocity vs position
- [ ] You can tune gravity and jump feel
- [ ] You understand single-frame jump input

---

## Next Lesson

`learn/30_fundamentals/t05_coyote_jump_buffer`
