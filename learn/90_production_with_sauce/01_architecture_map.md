# Architecture Map

This is mental map for `sauce/`.

## Frame Flow

1. `main` in `sauce/core_main.odin`
2. `sapp.run(...)`
3. `core_app_init`
4. `render_init`, `sound_init`, `entity_init_core`, `app_init`
5. each frame: `core_app_frame`
6. delta time set into `ctx.delta_t`
7. game state pointer set into `ctx.gs`
8. `core_render_frame_start`
9. `app_frame`
10. `core_render_frame_end`
11. input/temp allocator reset

## Responsibility Split

### `core_main.odin`
Owns:
- app startup/shutdown
- frame timing
- sokol callbacks
- top-level frame orchestration

Should change only when:
- timestep policy changes
- app boot order changes
- global callback model changes

### `core_render.odin`
Owns:
- GPU setup
- vertex/index buffer batching
- sprite atlas loading
- font loading
- shader pipeline binding
- pass begin/end/commit

Should change only when:
- you need new render capability
- new vertex data needed
- new post-process / shader feature needed

### `entity.odin`
Owns:
- handle validity
- create/destroy lifecycle
- free-list reuse

Should change only when:
- entity storage rules change
- lifecycle rules change

### `game.odin`
Owns:
- your actual game
- `Game_State`
- action mapping
- entity kinds
- game update and game draw
- puzzle rules
- camera behavior
- UI logic

This is main work file for real production gameplay.

## Current Blueprint Shape

`Game_State` already has:
- ticks
- game time
- camera position
- entity array
- free list
- player handle
- scratch arrays

Entity already has:
- kind
- update and draw procs
- transform-ish data
- sprite/anim fields
- scratch values for rendering

That means you already have enough to make:
- Sokoban entities
- switches/doors
- co-op players
- simple VFX entities
- UI entities if wanted

## Production Layers

Think in layers:

1. Core layer
`core_main`, `core_render`, `core_input`, `core_sound`

2. Blueprint layer
`entity.odin`, asset enums, shader flags, build script

3. Game layer
rules, levels, state transitions, entities, UI, camera

Most of your next game should stay in layer 3.
