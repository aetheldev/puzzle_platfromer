# T10 — Particles And Screen Shake

## Goal

Add particle bursts and camera shake for game feel / "juice."
Understand fixed pools, lifetime management, and feedback systems.

---

## The Concept

Juice makes games feel alive:
- **Particles:** small short-lived objects that communicate impact,
  motion, or status. Dust on landing, sparks on hit, embers on fire.
- **Screen shake:** brief camera offset that sells impact force.

Both are feedback systems. They do not change gameplay — they make
gameplay FEEL better.

---

## If You Know JS/React...

In React, transient visual feedback might be:
```jsx
const [shake, setShake] = useState(false);
const triggerShake = () => { setShake(true); setTimeout(() => setShake(false), 200); };
<div className={shake ? "shake" : ""}>
```

In a game, screen shake is:
```odin
shake_timer -= dt
if shake_timer > 0 {
    offset_x = sin(t) * strength * (shake_timer / SHAKE_TIME)
}
sgl.translate(offset_x, offset_y, 0)
```

No CSS animations. No setTimeout. Just math in the frame loop.

---

## Key Concepts

### Particle pool
```odin
MAX_PARTICLES :: 256
particles: [MAX_PARTICLES]Particle
```

Fixed array. No heap allocation. Reuse dead slots. This is the pool
pattern from o08 in action.

### Particle lifecycle
```odin
p.life -= dt
if p.life <= 0 { p.active = false }
```

Each particle has a timer. When it runs out, the particle dies and its
slot can be reused by the next burst.

### Screen shake
```odin
shake_timer -= dt
strength := SHAKE_STRENGTH * (shake_timer / SHAKE_TIME)
offset := sin(frame_count * frequency) * strength
```

Strength decays over time. Sine wave creates oscillation. Frequency
controls jitter speed.

---

## Line-by-Line Breakdown

Open:
- `learn/95_solutions/fundamentals/t10_particles_screenshake/main.odin`

### Lines 57-65: `Particle` struct
Position, velocity, life, max_life, size, color. All the data one
particle needs. No methods, no inheritance — just data.

### Lines 79-110: `spawn_burst`
Creates N particles in a fan pattern. Reuses first inactive slot.

### Lines 153-250: `frame`
Detects landing → spawns burst + starts shake. Updates particles.
Applies shake offset. Draws everything.

---

## Common Mistakes

1. **Allocating particles on heap per burst** — use fixed pool.
2. **Too many particles** — 20-30 per burst is usually enough.
3. **Too much shake** — subtle is better. 8-15 pixels max.
4. **Shake without decay** — screen shakes forever. Always decay.

---

## Exercises

### Exercise 1 — Burst On Key Press
Press X → spawn 20 particles at player center.

### Exercise 2 — Landing Dust
Detect landing (was airborne, now grounded). Spawn upward particles.

### Exercise 3 — Screen Shake
On landing or explosion, shake camera briefly.

### Exercise 4 — Particle Colors
Make particles fade from bright to transparent as they die.

---

## Exit Criteria

- [ ] Particles spawn, move, and die
- [ ] Pool pattern: no heap allocation
- [ ] Screen shake decays over time
- [ ] You can explain why pool + lifetime is used

---

## Next Lesson

`learn/30_fundamentals/t11_level_editor_basics`
