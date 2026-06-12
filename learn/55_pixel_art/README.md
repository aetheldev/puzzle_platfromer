# Pixel Art — Zero To Hero (Aseprite)

For someone who has NEVER drawn. Not "get good at art" — get good at
PIXEL art, which is closer to puzzle-solving than to drawing: few
pixels, hard constraints, learnable rules. If you can place rects in
code, you can place pixels on a canvas.

This is a SIDE TRACK like `65_practice_games/`. No code prerequisite.
Do one lesson per evening alongside the programming path. Your goal
asset list is known: detective sprites, room objects, items, tiles,
mood — everything here aims at that.

## The Ladder

| # | Lesson | You make | Time |
|---|--------|----------|------|
| a01 | Aseprite Cockpit | nothing — hands learn the tool | 1 evening |
| a02 | Pixels Have Rules | clean lines, no jaggies | 1 evening |
| a03 | Light Is Everything | shaded ball, cube, cylinder | 1-2 evenings |
| a04 | Color Without Fear | ramps, hue shift, stolen palettes | 1-2 evenings |
| a05 | Item Icons 16x16 | potion, key, sword, book (p06's BAG, real!) | 1-2 evenings |
| a06 | Your First Character | 32x32 detective, silhouette-first | 2-3 evenings |
| a07 | Make It Move | idle + walk cycle, onion skin | 2-3 evenings |
| a08 | Tiles That Repeat | floor + wall tileset, seamless | 2 evenings |
| a09 | The Rusty Lake Room | one full moody scene mockup | 3+ evenings |
| a10 | Export Pipeline | art flows into the game with one keybind | 1 evening |
| a11 | Script Aseprite (Lua) | your own tools — color swap, hotkeys | 2 evenings |

Order matters a01→a07. a08/a09 swappable. a10 whenever you have one
real asset. a11 any time after a04 (it is programming, your home turf).

## Rules For The Whole Track

1. **Small canvas always.** 16x16 or 32x32. Big canvas = drawing
   skill. Small canvas = decision skill. You have decision skill.
2. **Steal palettes.** Never invent colors early; pick from
   lospec.com/palette-list. Constraint = quality.
3. **Copy first, create second.** Studying good sprites pixel-by-pixel
   is THE method, not cheating. (Study = recreate, then change.)
4. **Daily ugly beats weekly pretty.** 20 bad sprites teach more than
   2 polished ones.
5. Same finishing rule as code lessons: run it (look at 100%+1000%
   zoom), change one thing, break one thing, fix it, add one extra.

## External Masters (free, curated)

- **Pedro Medeiros (saint11)** — saint11.org/blog — THE pixel art
  tutorial set, one-page-per-topic, made for game devs
- **Lospec tutorials + palette list** — lospec.com/pixel-art-tutorials
- **Brandon James Greer (YouTube)** — calm, fundamentals-first
- **Aseprite docs + Lua API** — aseprite.org/docs,
  github.com/aseprite/api (for a11)
- **carbscode itch.io extensions** — examples of what a11 builds
  toward (quick-color-hotkeys, color-swap)

## How This Feeds The Game

```
a05 icons      -> p06 idle widget items, detective inventory objects
a06+a07 chars  -> two detectives, walk cycles for sauce/ entities
a08 tiles      -> escape room floors/walls (t07 tilemap meets art)
a09 scene      -> the Rusty Lake mood target for the real game
a10 pipeline   -> asset_workbench/ -> res/images/ -> sauce/ sprites
a11 scripts    -> your personal tooling; faster art forever
```
