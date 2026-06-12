# P07 — Match-3 Juice

**Unlocks after:** `t10` (particles & screen shake) + `t13` (point and
click). Optional spice: the `45_shaders_postfx` track (s00+) for the
animated background — skippable, the game works without it.

## Goal

A complete match-3: click a gem, click a neighbor, swap. Three-in-a-row
clears, gems fall, new ones rain in, cascades chain into combos. Then —
and this is the real lesson — make it FEEL incredible: easing, bounces,
particle bursts, screen shake, floating score popups, a living
background. Same logic, completely different game in the hands.

```
+--------------------------------+
|  score 1280            x3      |
|   . o # ^ * o . #              |
|   o ^ [O] o . * # .   <- selected gem pulses
|   # . o o ^ . * o     <- 3 o's about to POP
|       +150  (rises, fades)     |
+--------------------------------+
```

## What You Are Combining (nothing new!)

| Piece | Lesson |
|---|---|
| 8x8 grid thinking, pixel <-> cell math | t07 |
| mouse hit-testing, click-to-select | t13 |
| particle pool + screen shake | t10 |
| dt movement, easing toward a target | t03 |
| `Phase` enum + exhaustive switch (board state machine) | o05 |
| fixed-size pools with `active` flags | t10 |
| hand-written fragment shader, time uniform | s00 (optional) |

## Design Pillars (decide these BEFORE coding)

1. **Grid state and visual state are SEPARATE — logic snaps, visuals
   lerp.** The `[8][8]` array of gem kinds is authoritative and updates
   INSTANTLY (swap, clear, gravity). Each gem also carries a visual
   position that eases toward its cell every frame. All animation is
   visual-only; the logic never waits for a tween to "finish moving" a
   gem. This one separation kills 90% of match-3 bugs.
2. **The board is a state MACHINE.** `idle -> swapping -> clearing ->
   falling -> (cascade? clearing again : idle)`. One phase at a time,
   one switch in the frame proc. No overlapping-animation spaghetti.
3. **Juice is a LAYER, not a foundation.** The game must be fully
   playable in ugly instant-snap mode first. Every effect after that is
   additive and deletable. Build plain, then feel the gap — same lesson
   as p03 breakout, bigger payoff.
4. **Everything is a fixed pool.** Particles, popups: arrays with
   `active` flags, zero per-frame allocation. The gem grid itself is a
   fixed `[8][8]` — match-3 never allocates.

## Build Order (run after EVERY step)

1. Grid filled with random kinds, drawn as flat colored quads. Done
   when the board looks like a quilt.
2. Mouse -> cell math + click to select (draw a highlight border).
3. Swap with INSTANT snap (no animation): click adjacent, kinds swap.
4. Match detection (3+ in row/col) + instant remove + instant gravity
   + refill. Congratulations: a complete, ugly, working match-3.
   Everything from here is juice.
5. Visual layer: give each gem a `vis_x/vis_y` that eases to its cell.
   Swaps now glide; invalid swaps swap-and-revert automatically (swap
   logic, no match found, swap logic back — visuals chase both times).
6. Clear animation (shrink + whiten over ~0.25s) + particle burst in
   the gem's color (lift the t10 pool wholesale).
7. Gravity becomes a fall: per-gem velocity + gravity + small bounce on
   landing. New gems spawn above the board and fall in. Cascades chain.
8. Combo counter: each cascade step increments it. Combo >= 2 shakes
   the screen, scaled by combo. Score = 10 x gems x combo.
9. Floating "+150" popups: 7-segment digits from plain rects (no font!)
   that rise and fade. Score + combo HUD the same way.
10. Animated background: fullscreen quad + hand-written fragment shader
    with a time uniform (the s00 pattern). Slow waves under the board.

## Solution

`learn/95_solutions/practice_games/p07_match3_juice/main.odin` (~900 lines)

This one HAS a full solution on purpose: it is a juice showcase, not a
solo flight. The logic you can build yourself after p04; the value is
seeing how all the t10 tricks compose into one cohesive feel — and that
the visual layer never touches the logic grid. Build through step 4
yourself first, then compare freely while juicing.

## Stretch Goals

- **No-more-moves detection**: try every adjacent swap on a scratch
  copy of the grid; if none yields a match, auto-shuffle with a "board
  shuffled!" popup.
- Special gems: a 4-match spawns a bomb that clears a 3x3.
- Hint system: after 5 idle seconds, sparkle a valid move.
- Vignette/bloom post-pass via render-to-texture (the s06 pattern).
- Swap the background shader per "level" (every 1000 points).

## Done When

- [ ] A friend plays without you explaining the controls
- [ ] An invalid swap visibly tries and politely returns
- [ ] A 3-cascade combo makes you grin every time (the shake helps)
- [ ] You can delete the entire juice layer and the game still works —
      prove pillar 3 to yourself
