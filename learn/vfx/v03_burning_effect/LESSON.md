# V03 — Burning Effect

## Goal

Create a burning status effect with heat glow, upward embers, and a
timer. Teaches readable status feedback.

---

## The Concept

A burning target needs instant readability: "this thing is on fire."
Three layers communicate this:
1. Color overlay on the target (hot orange tint)
2. Ember particles rising upward
3. Radial glow expanding around the target

The burn timer ticks down. When it ends, effects stop.

This pattern applies to any status effect: poison, freeze, shock, buff.
Different colors and motion, same structure.

---

## Read The Solution

Open:
- `learn/solutions/vfx/v03_burning_effect/main.odin`

Key sections:
- `ignite`: lines 37-39
- `spawn_ember`: lines 41-53
- Burn update + ember spawning: lines 75-124

---

## Exercises

### Exercise 1 — Ignite
Press Space → start burn timer.

### Exercise 2 — Embers
While burning, spawn upward particles.

### Exercise 3 — Glow
While burning, add expanding glow behind target.

### Exercise 4 — Another Status (Challenge)
Add a "frozen" effect: blue tint, slow drifting frost particles.

---

## Exit Criteria

- [ ] Ignite trigger works
- [ ] Burn timer counts down and stops
- [ ] Embers spawn upward
- [ ] Target shows visual burn state
- [ ] You can explain layered status readability

---

## Next Lesson

`learn/vfx/v04_laser_beam`
