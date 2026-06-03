# Juice Playground — Make Movement Feel Good

## Goal

Small platformer. Not a full game. A sandbox to learn the cheap tricks that
make a basic-looking thing look alive. You will add:

1. **Jump dust** — a puff kicks off your feet the instant you jump.
2. **Landing dust** — a wide flat burst when you hit the ground.
3. **Run dust** — small puffs trailing behind while running on the ground.
4. **Squash & stretch** — the body squishes on land, stretches on jump.
5. **Screen shake** — tiny jolt on a hard landing.

Everything is rectangles + particles. No sprites needed yet. The point is
that "looks good" is mostly motion and feedback, not art.

---

## Why This Matters

You said making things look basic kills the fun. The fix is rarely "draw
better art first". It is **game feel**: small reactions to player actions.

A white square that squashes when it lands, kicks dust, and shakes the
screen reads as more polished than a detailed sprite that just slides
around stiffly. Feel first, art later.

---

## The Core Idea: A Particle Is Nothing Special

```odin
Particle :: struct {
    active:   bool,
    x, y:     f32,
    vx, vy:   f32,
    size:     f32,
    life:     f32,   // counts down
    max_life: f32,   // to compute fade 1 -> 0
    r, g, b:  u8,
}
```

You keep a fixed array `[MAX]Particle`. To spawn, find an inactive slot and
fill it. Every frame: `life -= dt`, move by velocity, and when `life <= 0`
mark it inactive. Drawing fades alpha by `life / max_life`.

That is the entire system. Dust, sparks, confetti — all the same struct,
just different spawn parameters.

---

## Spawn Functions (the only real "design" work)

- **Jump dust**: spawn at the feet, velocity points DOWN + sideways (dust
  pushed away as you launch up). Short life.
- **Landing dust**: spawn at the feet, velocity mostly SIDEWAYS and flat,
  more particles the harder you land. This is what sells weight.
- **Run dust**: one or two small particles behind the player every few
  frames while grounded and moving.

Tuning these numbers IS the craft. Change counts, speeds, life, colors.

---

## Squash & Stretch

Track a `scale_x, scale_y`. On jump set `scale_y = 1.3, scale_x = 0.7`
(stretch up). On land set `scale_y = 0.6, scale_x = 1.4` (squash flat).
Each frame ease both back toward `1.0`. Draw the body using those scales
around its center. Cheap, hugely effective.

---

## Read The Solution

Open:
- `learn/95_solutions/projects/juice_playground/main.odin`

Key sections (read in this order):
- `Particle` struct + `emit` pool: top of file
- `spawn_jump_dust`, `spawn_land_dust`, `spawn_run_dust`
- `update_particles` / `draw_particles` (alpha fade + blend pipeline)
- squash/stretch in `frame`

---

## Controls

- A/D or arrows: move
- Space / W / Up: jump
- R: reset

---

## Exercises

1. Run it. Jump, land, run. Watch the dust.
2. Change `LAND_DUST` count and speeds. Make landings feel heavier.
3. Make run dust spawn faster, then slower. Find what feels right.
4. Add a short jump (release space early = lower jump).
5. Add a double jump that spawns a ring of dust mid-air.
6. Tint dust by speed: faster landing = brighter/whiter.

## Exit Criteria

- [ ] Jump spawns dust at feet
- [ ] Landing spawns a wider burst + screen shake on hard landings
- [ ] Running spawns trailing dust
- [ ] Body squashes on land, stretches on jump
- [ ] You retuned at least 3 numbers and can say what each does

## Where This Goes Next

These exact functions transfer straight into Sokoban (`60_projects/sokoban`)
and later into `sauce/`. Juice is portable. Learn it once here.
