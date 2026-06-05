# Parallel-Worlds Co-op Puzzle (the BOKURA trick)

> This is the lesson that answers: "how can two players be in the same world but
> see two totally different worlds — robots/tech vs animals/nature?" Full design
> explanation: `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md`.

Core idea: there are NOT two worlds. There is ONE world, drawn twice, with a
different costume each time.

- One tile grid, one set of entities, one collision truth (the simulation).
- A `Theme` enum (`tech`, `nature`) chosen at DRAW time picks each tile's and
  each character's costume.
- Same wall → metal panel for one viewer, mossy log for the other. Same partner
  → a robot to one, an animal to the other.

## Relationship To `different_views_puzzle`

`different_views_puzzle` taught **asymmetric collision on one shared screen**
(red/blue bridges). This lesson adds the missing piece: **forking the LOOK per
player** so the same world reads as two worlds. It reuses the same per-player
collision idea for its harder "truth fork" layer.

Do `different_views_puzzle` first. Then this.

## Two Layers (build in order)

1. **Cosmetic fork** — every tile exists for both, collision identical, only
   sprite + palette differ per theme. Co-op comes from describing what you see.
2. **Truth fork** — some tiles are solid ground in one theme and empty void in
   the other. Co-op comes from guiding each other across gaps you cannot see.

## Run The Prototype

```sh
cd learn/95_solutions/co_op/parallel_worlds_puzzle/prototype
zsh build.sh
```

Split screen: left = tech world (Player A, WASD), right = nature world
(Player B, arrows). Same grid, two themes. Both reach your exit to win. `R` resets.

Runnable answer: `learn/95_solutions/co_op/parallel_worlds_puzzle/prototype/main.odin`.

## Design Warning

The two-worlds LOOK is a costume. It is empty without a puzzle under it. Build
the gameplay (Milestones 1–5 in `learn/80_design/coop_lovers_puzzle/README.md`)
first; reskin into two worlds after it is already fun.
