# P03 — Breakout (Solo Flight — no solution)

**Unlocks after:** `t10 particles & screen shake`. Build p02 Pong
first — Breakout is Pong rotated 90° plus a brick wall.

## Goal

Paddle at the bottom, ball, grid of bricks. Clear the wall, lose a
life when the ball drops. Then — the actual lesson — make it FEEL good.

## Spec

- Paddle: mouse-follows-x or A/D, your choice (you have both skills)
- Brick grid: `[ROWS][COLS]int` where value = hits remaining
  (0 = gone, 2 = tough brick). t07 grid thinking, reused.
- Ball bounces off walls/paddle (with p02's slice rule), destroys
  bricks on contact
- 3 lives, lose ball below paddle, win when all bricks dead
- Brick rows have different colors; bottom rows worth less than top

## Phase Two — The Juice Pass (this is why the gate is t10)

Build it plain first. Play it. Boring, right? Now add, ONE AT A TIME,
playing between each:

1. Particles burst in the brick's color when it dies
2. Tiny screen shake on brick death; bigger on losing a life
3. Ball squash on paddle hit (draw it 1.4x wide, 0.6x tall for 4 frames)
4. Paddle flash when hit
5. Speed up ball every 10 bricks

Same game. Completely different feel. THIS gap — plain vs juiced — is
the most valuable thing you take from this project, straight into the
juice_playground lesson and your detective game's feedback design.

## Hints

1. Ball vs brick grid: convert ball position to grid cell
   (`col = int(x / BRICK_W)`) — only check that cell and neighbors,
   never loop all bricks. t07 again.
2. Which side did the ball hit? Compare overlap depths on x vs y;
   flip the velocity of the SMALLER overlap axis. (Get this wrong and
   the ball tunnels along brick rows — you will see it, you will fix it.)
3. Steal your own particle pool from t10. Verbatim. Reuse is a skill.

## Stretch

- Powerup drops: wider paddle, multi-ball (a `[dynamic]Ball`!)
- Level 2 with a different brick layout (text format, t11 export trick)

## Done When

- [ ] Win and lose both work, 3 lives
- [ ] Juice pass done — and you can say which single addition changed the feel most
- [ ] A friend says "one more try" unprompted (the real metric)
