# Learn — Odin + Sokol Game Dev

Goal: learn Odin and Sokol in order, build small puzzle and co-op games as
practice, then rebuild them inside the real `sauce/` engine.

## New here? Do not read this file. Read this instead:

`learn/00_START_HERE.md`

`00_START_HERE.md` checks your setup, picks your starting track, and tells you
the one next thing to do. This README is only a folder map for reference.

## Folder Map

The folders and files are numbered so GitHub lists them in the exact order you
should work through them, top to bottom.

```txt
learn/
  README.md                       <- you are here (folder map)
  00_START_HERE.md                <- open this first
  01_LEARNING_METHOD.md           <- the write-from-memory daily loop
  02_MASTER_TICKET_LIST.md        <- the full ordered checklist (your daily to-do)
  03_RESOURCES.md                 <- external videos, docs, examples (by phase)

  10_odin_for_js_devs/            o01..o16  learn Odin via JS/TS comparison
  20_game_thinking_for_web_devs/  g01..g08  game mindset, no code
  30_fundamentals/                t01..t11  window, input, physics, tilemap, camera, shaders
                                  t12       integration room: combine it all (bridge to projects)
  40_vfx/                         v01..v04  glow, elemental orbs, fire, laser
  50_advanced/                    production-style rendering/FX reading path
  60_projects/                    sokoban, turn_based_card_game  first full games
  70_co_op/                       different_views_puzzle  asymmetric two-player
  80_design/                      puzzle_game_ideas  idea bank
                                  coop_lovers_puzzle  YOUR two-lovers game design + build plan
  85_networking/                  online rooms / remote co-op (read LAST)
  90_production_with_sauce/       how to build features inside the real sauce/ engine
  95_solutions/                   runnable reference answers for every lesson

  templates/                      ATTEMPT / REVIEW / SAUCE_MIGRATION templates
```

## How Lesson Folders Work

- Lesson folders (`10_odin_for_js_devs/`, `20_game_thinking_for_web_devs/`,
  `30_fundamentals/`, `40_vfx/`, `60_projects/`, `70_co_op/`) contain
  **instructions only**.
- You write your own `main.odin` in the lesson folder, then `zsh build.sh`.
- Runnable answers live under `learn/95_solutions/...` — open only when a lesson
  tells you which exact lines to read.

## Big Picture Order

```
10_odin_for_js_devs  ->  20_game_thinking_for_web_devs  ->  30_fundamentals
   ->  40_vfx  ->  60_projects + 70_co_op  ->  90_production_with_sauce
   ->  real sauce/ game
```

Standalone lessons are practice. The destination is rebuilding your games
inside `sauce/`. Do not rush to `sauce/` early.

## Notes

- `t09_shaders_bloom` uses manual Metal shader source because the repo shader
  tool version does not match the checked-in Sokol bindings. Fine for learning.
- Main repo build works on latest Odin after compatibility fixes.
- Production `sauce/` build regenerates shaders; the build script normalizes
  current `sokol-shdc` output back into this repo's binding format.
