# Learn — Odin + Sokol Game Dev

Goal: learn Odin and Sokol in order, build small puzzle and co-op games as
practice, then rebuild them inside the real `sauce/` engine.

## New here? Do not read this file. Read this instead:

`learn/00_START_HERE.md`

`00_START_HERE.md` checks your setup, picks your starting track, and tells you
the one next thing to do. This README is only a folder map for reference.

## Folder Map

The numbers control the GitHub sort order. They do NOT all mean "do this
next". That is what confused you. Each folder has a **TYPE**:

| Tag | Meaning |
|-----|---------|
| **[DO]**  | A hands-on track. Write code here. Part of the main path. |
| **[READ]** | A reading path you visit LATER (after you can already build). Not code to write now. |
| **[REF]** | Reference. Open anytime you need it. Never "blocking" you. |

So the rule is simple: **follow the [DO] folders in number order. Ignore
[READ]/[REF] until something tells you to open them.** The high numbers on
[READ]/[REF] folders are just there to push them to the bottom of the list —
not because you do them late in the [DO] sequence.

```txt
learn/
  README.md                       [REF]  you are here (folder map)
  00_START_HERE.md                [DO]   open this first
  01_LEARNING_METHOD.md           [REF]  the write-from-memory daily loop
  02_MASTER_TICKET_LIST.md        [DO]   the full ordered checklist (your daily to-do)
  03_RESOURCES.md                 [REF]  external videos, docs, examples (by phase)
  04_COOP_LOVERS_ROADMAP.md       [REF]  personal roadmap for the asymmetric co-op lovers game

  10_odin_for_js_devs/            [DO]   o01..o16  learn Odin via JS/TS comparison
  20_game_thinking_for_web_devs/  [DO]   g01..g08  game mindset, no code
  30_fundamentals/                [DO]   t01..t11  window, input, physics, tilemap, camera, shaders
                                         t12       integration room: combine it all
  40_vfx/                         [DO]   v01..v04  glow, elemental orbs, fire, laser
  45_shaders_postfx/              [DO]   s00..s06  render-to-texture post-FX:
                                         darkness, fog, lights, CRT, grading, bloom
  50_advanced/                    [READ] production rendering/FX reading path (AFTER projects)
  55_pixel_art/                   [SIDE] Aseprite zero-to-hero (a01..a11): pixels, light,
                                         color, icons, character, animation, tiles, scene,
                                         export pipeline, Lua scripting — no code prerequisite
  60_projects/                    [DO]   juice_playground, sokoban, card game  first full games
  65_practice_games/              [SIDE] snake, pong, breakout, memory match, idle RPG —
                                         confidence builders, each unlocks after a specific
                                         lesson ("you learned up to X -> you can build this")
  70_co_op/                       [DO]   different_views_puzzle  asymmetric two-player
  75_sauce_bridge/                [DO]   visual-first ports: Snake/Tetris/Sokoban/Parallel Worlds in sauce style
  80_design/                      [REF]  puzzle_game_ideas idea bank; coop_lovers_puzzle YOUR game
  85_networking/                  [READ] online rooms / remote co-op (read LAST)
  90_production_with_sauce/       [DO]   build features inside the real sauce/ engine
  95_solutions/                   [REF]  runnable reference answers for every lesson

  templates/                      [REF]  ATTEMPT / REVIEW / SAUCE_MIGRATION templates
```

### The [DO] path, in true order

This is the ONLY sequence you follow. Everything else is support:

```
10 -> 20 -> 30 -> 40 -> 60 -> 70 -> 75 -> 90 -> sauce/
```

`50_advanced` and `85_networking` sit at those numbers only so they sort
near the bottom. You actually open `50` AFTER `60_projects` (it explains how
to redo your project with production FX), and `85` LAST of all. `80_design`
and `95_solutions` are lookup folders, open whenever a lesson points you in.

## How Lesson Folders Work

- The **[DO]** lesson folders (`10_odin_for_js_devs/`,
  `20_game_thinking_for_web_devs/`, `30_fundamentals/`, `40_vfx/`,
  `45_shaders_postfx/`, `60_projects/`, `70_co_op/`) contain
  **instructions only**.
- You write your own `main.odin` in the lesson folder, then `zsh build.sh`.
- Runnable answers live under `learn/95_solutions/...` — open only when a lesson
  tells you which exact lines to read.

## Big Picture Order

The [DO] path only (read the table above for what the other numbers mean):

```
10_odin_for_js_devs  ->  20_game_thinking_for_web_devs  ->  30_fundamentals
   ->  40_vfx  ->  45_shaders_postfx  ->  60_projects + 70_co_op
   ->  75_sauce_bridge  ->  90_production_with_sauce  ->  real sauce/ game
```

Side trips off that line, when a lesson sends you:
- `50_advanced/`  [READ] — open AFTER `60_projects`, to redo a project with
  production-grade FX. It is reading, not new code to write from scratch.
- `80_design/`    [REF]  — idea bank + your own co-op game plan. Browse anytime.
- `04_COOP_LOVERS_ROADMAP.md` [REF] — personal learning + production roadmap for your BOKURA/We Were Here-style game.
- `85_networking/`[READ] — open LAST, only once a LOCAL co-op game works.
- `95_solutions/` [REF]  — runnable answers; open the exact lines a lesson names.

Standalone lessons are practice. The destination is rebuilding your games
inside `sauce/`. Do not rush to `sauce/` early.

## Notes

- `t09_shaders_bloom` uses manual Metal shader source because the repo shader
  tool version does not match the checked-in Sokol bindings. Fine for learning.
- Main repo build works on latest Odin after compatibility fixes.
- Production `sauce/` build regenerates shaders; the build script normalizes
  current `sokol-shdc` output back into this repo's binding format.
