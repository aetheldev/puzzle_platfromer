# Production With Sauce

Goal: learn how to turn your small Sokol lessons into a real game built on this repo's `sauce/` blueprint.

This is the destination folder.
Everything you practice in fundamentals, projects, and co-op should eventually be reproducible inside `sauce/`.

This folder is not about basics.
This folder is about:
- how `sauce/` is structured
- where gameplay code really lives
- how to port your small prototypes into production-style code
- how to build Sokoban or co-op puzzle game using existing blueprint pieces

## Read This First

Relevant real files in this repo:
- `sauce/core_main.odin`: app loop, callbacks, frame timing, context
- `sauce/core_render.odin`: renderer, atlas, font, shader pipeline
- `sauce/core_input.odin`: input abstraction
- `sauce/core_sound.odin`: FMOD integration
- `sauce/game.odin`: game-specific state and gameplay logic
- `sauce/entity.odin`: entity handles, create/destroy, free list
- `sauce/build/build.odin`: build script, shader generation, output packaging

## What Sauce Is

`sauce/` is not small teaching code.
It is blueprint code for making one real game.

That means:
- core systems already exist
- rendering already exists
- sound pipeline already exists
- entity structure already exists
- build pipeline already exists
- game-specific code goes into `game.odin` and nearby helpers

So production path is different from fundamentals:

Fundamentals path:
1. learn one concept in isolation
2. write direct small code
3. keep everything local and simple

Production path:
1. understand existing structure
2. fit mechanic into existing loop/state/render/input flow
3. add only game-specific pieces you need
4. keep core files stable unless new engine capability is required

## Best Order

1. Read `01_architecture_map.md`
2. Read `02_fundamentals_to_sauce.md`
3. Read `03_sokoban_in_sauce.md`
4. Read `04_coop_puzzle_in_sauce.md`
5. Use `05_production_tickets.md` as working roadmap
6. Read `06_what_is_sokol.md`
7. Read `07_sokol_header_map.md`
8. Read `08_how_to_make_a_game.md`
9. Read `09_visual_effects_roadmap.md`
10. Read `10_genre_roadmap.md`
11. Save `11_sokol_upgrade_checklist.md` for future refresh
12. Read `12_turn_based_card_game_in_sauce.md` if you want card/turn-based path

## Important Mindset

Do not rewrite `sauce/` into your fundamentals examples.
Do opposite.

Bring lessons into blueprint gradually:
- first keep `core_*` mostly untouched
- add game state in `game.odin`
- add entity kinds if needed
- add sprites and shader params only when needed
- change renderer only if design truly needs it

## Good Rule

If feature is specific to your game, put it in game code.
If feature is reusable engine/tooling capability, put it in `core_*` or build pipeline.

Examples:
- Sokoban push rules: game code
- Pressure plate logic: game code
- Shared camera puzzle logic: game code
- New render texture pass for bloom: core render
- New shader asset pipeline: build/core render
- Steam achievements wrapper: core/platform integration

## What Not To Do First

Do not begin with:
- Steamworks
- advanced shader rewrite
- custom editor inside engine
- networking
- full ECS rewrite

Begin with one playable loop inside `game.odin` first.

## Latest Odin Note

This repo has been ported enough to build with current Odin on macOS.

One remaining tooling caveat:
- checked-in `sokol/gfx` bindings are older than current `sokol-shdc` generated Odin format
- production build now regenerates shaders and then normalizes the generated file back into the repo binding format
- if you do a full future Sokol upgrade, you can remove that normalization step and keep pure generated output
