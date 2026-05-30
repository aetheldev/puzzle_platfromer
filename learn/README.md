# Learn — Odin + Sokol Game Dev

Goal: learn Odin and Sokol in order, build small puzzle and co-op games as
practice, then rebuild them inside the real `sauce/` engine.

## New here? Do not read this file. Read this instead:

`learn/START_HERE.md`

`START_HERE.md` checks your setup, picks your starting track, and tells you the
one next thing to do. This README is only a folder map for reference.

## Folder Map

```txt
learn/
  START_HERE.md             <- open this first
  MASTER_TICKET_LIST.md     <- the full ordered checklist (your daily to-do)
  LEARNING_METHOD.md        <- the write-from-memory daily loop
  RESOURCES.md              <- external videos, docs, examples (by phase)
  ATTEMPT_TEMPLATE.md       <- template for submitting code for review
  REVIEW_TEMPLATE.md        <- template for reviewing code
  SAUCE_MIGRATION_TICKETS.md<- how to move a standalone game into sauce/

  odin_for_js_devs/         o01..o16  learn Odin via JS/TS comparison
  game_thinking_for_web_devs/ g01..g08  game mindset, no code
  fundamentals/             t01..t11  window, input, physics, tilemap, camera, shaders
                            t12       integration room: combine it all (bridge to projects)
  vfx/                      v01..v04  glow, elemental orbs, fire, laser
  projects/                 sokoban, turn_based_card_game  first full games
  co_op/                    different_views_puzzle  asymmetric two-player
  design/                   puzzle_game_ideas  idea bank
                            coop_lovers_puzzle  YOUR two-lovers game design + build plan
  advanced/                 production-style rendering/FX reading path
  production_with_sauce/    how to build features inside the real sauce/ engine
  solutions/                runnable reference answers for every lesson
```

## How Lesson Folders Work

- Lesson folders (`odin_for_js_devs/`, `game_thinking_for_web_devs/`,
  `fundamentals/`, `vfx/`, `projects/`, `co_op/`) contain **instructions only**.
- You write your own `main.odin` in the lesson folder, then `zsh build.sh`.
- Runnable answers live under `learn/solutions/...` — open only when a lesson
  tells you which exact lines to read.

## Big Picture Order

```
odin_for_js_devs  ->  game_thinking_for_web_devs  ->  fundamentals  ->  vfx
   ->  projects + co_op  ->  production_with_sauce  ->  real sauce/ game
```

Standalone lessons are practice. The destination is rebuilding your games
inside `sauce/`. Do not rush to `sauce/` early.

## Notes

- `t09_shaders_bloom` uses manual Metal shader source because the repo shader
  tool version does not match the checked-in Sokol bindings. Fine for learning.
- Main repo build works on latest Odin after compatibility fixes.
- Production `sauce/` build regenerates shaders; the build script normalizes
  current `sokol-shdc` output back into this repo's binding format.
