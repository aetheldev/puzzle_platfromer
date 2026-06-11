# P01 — Snake

**Unlocks after:** `t07 tilemap`. If you finished t07, you already
know everything this game needs.

## Goal

Complete, playable Snake: eat food, grow, speed up, die on wall or
self-bite, restart with R. A friend can pick it up and play.

---

## What You Are Combining

| Piece | Where you learned it |
|---|---|
| window, clear color | t01 |
| drawing rects | t02 |
| keyboard input | t03 |
| grid coordinates | t07 |
| `[dynamic]Cell` body | o06 |
| `Dir` enum + switch | o05 |
| `rand.int_max` food | o16 (you printed random values there) |

Nothing new. That is the point.

---

## The Three Insights (read, then build)

### 1. The snake moves on a tick, not every frame
60 moves/second is unplayable. Count frames; move every N:

```odin
frame_count += 1
if frame_count >= move_every {
    frame_count = 0
    move_snake()
}
```

Lower `move_every` as score grows = difficulty curve, free.

### 2. The body is a dynamic array; movement is head-insert + tail-pop

```odin
inject_at(&snake, 0, new_head)   // grow at front
pop(&snake)                       // shrink at back  -> net effect: moved
```

Eating = skip the pop. The snake grows by NOT shrinking. When this
clicks, you understand why the body is a list and not positions+math.

### 3. Input is buffered, applied on the tick
Player presses up-then-left between two ticks. If you apply instantly,
fast fingers reverse the snake into itself. Store `next_dir`, apply at
tick time, reject 180° turns:

```odin
opposite := [Dir]Dir{.up = .down, .down = .up, .left = .right, .right = .left}
if next_dir != opposite[dir] { dir = next_dir }
```

---

## Build Order (run after EVERY step)

1. Window + grid constants (steal your own t07 code)
2. Draw a 3-segment snake as rects (no movement)
3. Tick timer + move right only
4. Input + direction (feel the 180° bug, then fix it)
5. Walls kill + game over state + R restart
6. Food spawn (NOT on the snake!) + eat + grow
7. Self-bite kills
8. Speed up every 3 food + score display

## Solution

Full solution: `learn/95_solutions/practice_games/p01_snake/main.odin`
Try steps 1-5 WITHOUT it first. Open it when stuck or to compare after.

---

## Stretch Goals (each one a small design lesson)

- Wrap-around walls instead of deadly walls — which is more fun? Why?
- Golden food: appears for 3 seconds, worth 3, then vanishes
- Two snakes, one keyboard (WASD vs arrows) — p02's two-player idea, early
- Juice pass after t10: screen shake on death, particle burst on eat

## Done When

- [ ] A friend plays it without you explaining anything
- [ ] You can name which lesson each piece of your code came from
- [ ] You fixed at least one bug WITHOUT looking at the solution
