# P08 — Platformer Juice (the same game, twice)

**Unlocks after:** `t10` (particles). Combines `t04` gravity/jump,
`t05` coyote/jump buffer, `t07` tilemap, `t08` camera, `t10` juice,
and the s-track post-fx pattern. Nothing new — that is the point.

## Goal

A small platformer level: run, jump, collect coins, dodge spikes,
reach the flag. Here is the trick: build it PLAIN first. Tilemap,
AABB collision, a rectangle that jumps. It will work perfectly and
feel completely dead. Then spend the rest of the lesson making the
EXACT SAME GAME feel alive — without changing a single rule of the
simulation. That gap between "correct" and "good" is what this
lesson teaches. It is the platformer version of what p03 Breakout
hinted at, taken all the way.

## What You Are Combining

| Piece | Lesson |
|---|---|
| gravity, jump velocity, variable jump height | t04 |
| coyote time + jump buffer | t05 |
| string-array tilemap, axis-separated AABB resolve | t07 |
| smooth camera follow with lerp + clamp | t08 |
| particle pool, screen shake | t10 |
| render-to-texture, fullscreen post shader | s00 / s06 |
| fixed-size pools with `active` flags | t10 / o06 |

## Design Pillars (decide these BEFORE coding)

1. **Input forgiveness is invisible.** Coyote time and the jump
   buffer never appear on screen. Players will say your game has
   "tight controls" and will not be able to tell you why. The best
   juice is the kind nobody can point at.
2. **Squash & stretch is scale-only.** The draw scale animates; the
   collision box NEVER changes. The moment visuals feed back into
   physics you have bugs disguised as art. One-way street: sim →
   visuals.
3. **Effects are proportional to cause.** Landing dust scales with
   fall speed. A hop gets a puff; a plummet gets a burst and a
   shake. Constant-size effects read as noise, proportional ones
   read as physicality.
4. **Time itself is a juice channel.** Hitstop (a few frozen
   milliseconds on coin pickup) and slow-mo (the win moment) cost
   one `dt` multiplier each and punch far above their weight.
5. **The post pass touches no game code.** Vignette and color grade
   live entirely in one fragment shader reading the scene texture.
   You can delete the whole pass and the game is untouched — that
   separation is the s00 lesson, applied.

## Build Order (run after EVERY step — and FEEL each one)

1. Tilemap loads, player rect runs and jumps on it (t04+t07). Plain.
2. Coyote + buffer + variable jump height (t05). Feel the controls
   tighten.
3. Camera lerp + clamp (t08). The level can now be wide.
4. Coins (pool, pickup, counter) and spikes (death → respawn at
   start). The GAME is now done. Note how dead it feels.
5. Squash on land, stretch on jump, ease back to 1. First life.
6. Dust: landing burst scaled by fall speed, run trickle on ground,
   coin sparkle. Screen shake on hard landings and death.
7. Hitstop on coin pickup, confetti + slow-mo on reaching the flag.
8. Parallax background layers (fractional camera speed).
9. Post pass: vignette + subtle color grade (s00 skeleton, your
   fragment shader).

## Solution

`learn/95_solutions/practice_games/p08_platformer_juice/main.odin`
(~1000 lines). This one HAS a full solution because it is a juice
showcase — every effect is a pattern worth stealing for the real
game. Build through step 4 yourself first, then compare your juice
to its juice one effect at a time.

## Stretch Goals

- Wall jump (t06) — wall-slide dust trickle included, obviously
- Moving platforms (player inherits platform velocity — harder than
  it sounds)
- Double jump with a distinct mid-air particle ring so it reads
- Trail ghosting: store the last N player rects, draw them fading
- A timer + best-time display using the 7-segment digits you
  already have

## Done When

- [ ] A friend says the controls feel "tight" without prompting
- [ ] You can toggle juice off (one bool) and everyone immediately
      prefers it on
- [ ] Landing from a big fall FEELS heavier than a hop
- [ ] The collision box never changed size during any animation
- [ ] You shipped the flag celebration without a single word of text
