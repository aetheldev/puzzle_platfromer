# V02 — Elemental Orbs

## Goal

Create visually distinct elements (fire, ice, poison) through different
particle motion, color, and behavior. Element identity comes from
movement language, not only color.

---

## The Concept

Fire rises fast and flickers. Ice drifts slowly and sideways. Poison
hangs in the air and pulses. Same particle system, different parameters.

This teaches you that VFX personality comes from:
- Direction bias (up, sideways, down)
- Speed
- Lifetime
- Size
- Color
- Gravity influence

---

## Read The Solution

Open:
- `learn/95_solutions/vfx/v02_elemental_orbs/main.odin`

Key sections:
- `Element` enum: line 15
- `emit_particle`: lines 48-74 (notice per-element behavior branches)
- Particle update: lines 89-118 (per-element motion modifiers)

---

## Exercises

### Exercise 1 — Two Elements
Create fire and ice with different colors and particle motion.

### Exercise 2 — Third Element
Add poison: slower, wobbling, greenish.

### Exercise 3 — Glow Per Element
Add element-colored glow behind each orb.

### Exercise 4 — Particle Fade
Make particles shrink and fade as they die.

---

## Exit Criteria

- [ ] At least 2 elements feel visually different
- [ ] Particles update and die correctly
- [ ] You can explain what makes each element distinct beyond color

---

## Next Lesson

`learn/40_vfx/v03_burning_effect`
