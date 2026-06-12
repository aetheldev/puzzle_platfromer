# A08 — Tiles That Repeat

Goal: floor + wall tiles that don't look like a checkerboard of
sadness when repeated 100 times. Direct feed into t07 (tilemap code)
— you wrote the renderer, now you feed it.

## The Seamless Problem

A tile meets ITSELF on all four edges. Two failure modes:

1. **Edge seams:** visible lines where tiles join → edges must match
   (left edge continues right edge, top continues bottom)
2. **Grid glare:** pattern so distinct your eye sees the 16px grid
   forever → interior must be BORING (yes, boring is correct)

## Aseprite's Killer Feature: Tiled Mode

View → Tiled Mode → "Both Axes". Canvas now previews as an infinite
repeat WHILE you draw. Every pixel you place updates the whole field.
This single feature makes tile work 5x easier — leave it on for the
entire lesson.

## Recipe: Floor Tile (16x16)

1. Fill with base color (mid tone — floors recede, keep contrast LOW)
2. Tiled Mode ON. Add sparse noise: 4-8 pixels one ramp-step darker,
   3-5 one step lighter. NOT in a pattern. Avoid corners (corners
   repeat 4x as visibly).
3. Optional: 1-2 crack/plank lines — and BREAK them at tile edges
   consistently (a line exiting right must enter the next tile's left)
4. Stare at the tiled field. Any pixel cluster your eye keeps
   returning to = delete it. Boring = correct.

## Recipe: Wall Tile + Variants

Same, but: darker/desaturated vs floor (walls = background mood),
horizontal banding ok (bricks/panels), and make a TOP-EDGE variant
(1-2px highlight line where wall meets ceiling/light).

Then the pro move — **the 10% variant:** duplicate your floor tile,
change 5 pixels (a crack, a stain). Scatter it as every ~10th tile in
a map. Repetition disappears for nearly zero work. (Your t07/t11 level
format: floor `.` and floor-variant `,` — code side is one enum entry.)

## Mini Set For The Escape Room

- [ ] floor base + 1 variant
- [ ] wall base + top-edge variant
- [ ] floor↔wall transition tile (baseboard/skirting — 2px dark band)
- [ ] one PROP tile that breaks the grid: crate or barrel (a05 recipe
      on a tile-sized object, sits ON floor tiles)

Export the set as one horizontal strip (a10 handles it) and ACTUALLY
LOAD IT in your t07 tilemap lesson build. Seeing your art scrolled by
your own camera (t08) is the payoff of this whole track.

## Exit Criteria

- [ ] Tiled Mode field shows no seams, no grid glare
- [ ] Variant tile kills visible repetition
- [ ] Your tiles rendered by your t07 code

## Next

`a09_rusty_lake_room` — composition + mood: a full scene mockup.
