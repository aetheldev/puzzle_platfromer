# Sauce Bridge — Visual-First Practice Games

Goal: stop treating practice games as ugly throwaways. Rebuild small games inside
`sauce/` with production habits: entity/state split, atlas sprites, particles,
screen shake, post-FX, UI, and readable game feel.

This folder is the missing bridge:

```txt
standalone prototype -> sauce game mode -> polished vertical slice
```

## Why This Exists

Fundamentals teach one concept in one file. That is useful, but it does not feel
like making a real game.

`sauce/` teaches real structure, but jumping straight into it is too much.

This bridge teaches how to port simple games into `sauce/` while making them
look and feel good.

## Visual-First Rule

Every bridge game must include at least 3 polish systems:

- sprite/atlas usage instead of plain rectangles
- particles for hits, clears, pickups, footsteps, or puzzle feedback
- screen shake or hitstop for important events
- shader/post-FX mood (CRT, fog, bloom, color grade)
- UI text and state transitions
- audio hooks, even if temporary

Plain game first is allowed only for 1 short milestone. Then juice immediately.

## Bridge Lessons

| Lesson | Game | Why |
|---|---|---|
| `b01_visual_first_sauce_mindset.md` | mindset | how to avoid boring prototypes |
| `b02_snake_in_sauce.md` | Snake | tiny game, perfect for atlas/particles/CRT polish |
| `b03_tetris_in_sauce.md` | Tetris | grid game with strong visual/audio feedback loops |
| `b04_sokoban_in_sauce.md` | Sokoban | closest practice to puzzle game architecture |
| `b05_parallel_worlds_in_sauce.md` | your co-op target | one world, two views, themes, puzzle truth fork |

## Recommended Order

```txt
after t08/t10/s00 -> b01 -> b02 or b03
after sokoban/co-op prototype -> b04
when ready for your real game -> b05
```

If your goal is the co-op different-view puzzle, do:

```txt
70_co_op/different_views_puzzle
70_co_op/parallel_worlds_puzzle
75_sauce_bridge/b05_parallel_worlds_in_sauce.md
90_production_with_sauce/13_parallel_worlds_coop_in_sauce.md
```

## Core Rule

Do not ask: "Can I make this in one file?"

Ask: "Where does this belong in `sauce/`?"

- game-specific rule -> `game.odin`
- reusable draw/input/sound/tooling -> `core_*` or build pipeline
- objects needing lifetime/spawn/destroy -> `entity.odin` path
- tile grids, board states, puzzle truth -> `Game_State` arrays
