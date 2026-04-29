# Sokol Learning Roadmap

Goal: learn Odin + Sokol in order, then turn fundamentals into puzzle games and co-op ideas.

Main long-term goal:
- use standalone lessons/projects only as practice
- then remake the same ideas inside `sauce/`
- that is the production-ready path for your real game

## Structure

```txt
learn/
  MASTER_TICKET_LIST.md
  LEARNING_METHOD.md
  fundamentals/
    t01_hello_window
    ...
    t11_level_editor_basics
  solutions/
    fundamentals/
    projects/
    co_op/
  production_with_sauce/
  projects/
    sokoban/
    turn_based_card_game/
  design/
    puzzle_game_ideas/
  co_op/
    different_views_puzzle/
```

## First Run

If macOS Sokol static libs are missing, build once:

```sh
cd sauce/sokol
zsh build_clibs_macos.sh
```

Then run any lesson/project:

```sh
cd learn/fundamentals/t04_gravity_jump
zsh build.sh
```

## Master Path

If you want one big ordered checklist, start with:

`learn/MASTER_TICKET_LIST.md`

## Learning Method

If you want exercise-first learning, read:

`learn/LEARNING_METHOD.md`

Important:
- `learn/fundamentals/` now contains lesson instructions only
- `learn/projects/` now contains lesson instructions only
- `learn/co_op/` prototype folders now contain lesson instructions only
- runnable answers moved to `learn/solutions/fundamentals/`
- runnable project/co-op answers moved to `learn/solutions/...`
- lesson folders will not run until you write your own `main.odin`

## Fundamentals Order

1. `learn/fundamentals/t01_hello_window`
Window, frame loop, clear color.

2. `learn/fundamentals/t02_shapes_colors`
2D drawing with `sokol_gl`.

3. `learn/fundamentals/t03_movement`
Keyboard input, held keys, delta time.

4. `learn/fundamentals/t04_gravity_jump`
Gravity, velocity, jump, floor collision.

5. `learn/fundamentals/t05_coyote_jump_buffer`
Game feel: coyote time, jump buffer, variable jump.

6. `learn/fundamentals/t06_wall_jump`
Wall slide, wall jump.

7. `learn/fundamentals/t07_tilemap`
Level grid, tile collision.

8. `learn/fundamentals/t08_camera`
Camera follow, world vs screen space.

9. `learn/fundamentals/t09_shaders_bloom`
Manual shader pipeline and cheap glow.

10. `learn/fundamentals/t10_particles_screenshake`
Particles and camera shake.

11. `learn/fundamentals/t11_level_editor_basics`
Mouse painting, tile editing, spawn placement, console export.

## Projects

`learn/projects/sokoban`

`learn/projects/turn_based_card_game`

First full puzzle game using what you learned.

First turn-based state-machine game path.

Suggested next upgrades:
1. Undo
2. Many levels
3. Better visuals
4. Editor import/export
5. New tile rules

## Production Path

`learn/production_with_sauce`

This folder explains how to stop writing isolated lesson code and start building real game features inside `sauce/`.

Use it when you want:
- production architecture
- real game state integration
- entity-based gameplay in blueprint
- renderer/input/build pipeline understanding
- Sokoban and co-op puzzle implemented the repo-native way

## Design Paths

`learn/design/puzzle_game_ideas`

Use this when you want to branch into new puzzle types after Sokoban.

## Co-op Path

`learn/co_op/different_views_puzzle`

This folder explains asymmetric co-op puzzle design where both players share one level but do not share the same information or collision rules.

## Recommended Learning Flow

1. Finish `t01` through `t08`
2. Build small experiments in each
3. Study `t09` and `t10` for juice
4. Build levels in `t11`
5. Make `projects/sokoban`
6. Branch into co-op prototype

## Notes

- Lessons intentionally stay small.
- `t09_shaders_bloom` uses manual Metal shader source because repo shader tool version does not match checked-in Sokol bindings.
- That mismatch is fine for learning; later you can upgrade/pin versions together.
- Main repo build now works on latest Odin after compatibility fixes.
- Production `sauce/` build now regenerates shaders again, but the build script normalizes current `sokol-shdc` output back into the binding format used by this repo.
