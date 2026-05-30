# V04 — Laser Beam

## Goal

Draw a beam with core, glow, and impact sparks. Directly useful for
mirror/laser puzzle games.

---

## The Concept

A good beam has three layers:
1. **Thin bright core** — the beam itself
2. **Wider soft glow** — additive, lower opacity
3. **Impact sparks** — particles where beam hits

The beam can pulse in width or brightness to feel alive.
Impact sparks sell the idea that energy is hitting something.

This is directly the visual layer for mirror/laser puzzle mechanics.
Gameplay traces beam segments; VFX draws them pretty.

---

## Read The Solution

Open:
- `learn/95_solutions/vfx/v04_laser_beam/main.odin`

Key sections:
- `draw_beam_segment`: lines 36-47
- `spawn_spark`: lines 49-61
- Frame update + rendering: lines 71-111

---

## Exercises

### Exercise 1 — One Beam
Draw a horizontal beam from left to right.

### Exercise 2 — Pulse
Vary beam width over time using sine wave.

### Exercise 3 — Impact Sparks
At the beam endpoint, spawn small particles in random directions.

### Exercise 4 — Multiple Segments (Challenge)
Draw beam as 2 segments: emitter → mirror → target.
Add impact at both endpoints.

---

## Exit Criteria

- [ ] Beam visible with core and glow
- [ ] Beam pulses or feels alive
- [ ] Impact sparks at endpoint
- [ ] You can explain the 3-layer beam model
- [ ] You see how this maps to mirror puzzle gameplay

---

## Congratulations

You completed the VFX practice path.

You now know how to:
- Fake glow with layered quads
- Give elements visual identity through motion
- Create readable status effects
- Draw beams with impact feedback

These skills directly apply to:
- Sokoban goal glow
- Card game highlights
- Co-op role clarity
- Mirror/laser puzzle visuals

Next: rebuild these inside `sauce/` using `learn/50_advanced/` guides.
