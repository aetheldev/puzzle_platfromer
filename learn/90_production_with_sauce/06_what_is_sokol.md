# What Is Sokol

Sokol is small low-level cross-platform game/app libraries.

It is not full engine like Unity or Godot.
It gives you thin building blocks.

Think of it like this:
- Sokol opens window
- Sokol gives input
- Sokol gives graphics API wrapper
- Sokol gives audio helper modules
- you build game architecture on top

That is why this repo has `sauce/` on top of Sokol.
`sauce/` is your game blueprint layer.

## Main Sokol Pieces In This Repo

### `sokol_app`
Window, app lifecycle, input events.

Use for:
- window creation
- keyboard/mouse/gamepad events
- frame callbacks

Repo mapping:
- `sauce/core_main.odin`

### `sokol_gfx`
GPU abstraction layer.

Use for:
- buffers
- textures
- shaders
- pipelines
- render passes
- draw calls

Repo mapping:
- `sauce/core_render.odin`

### `sokol_glue`
Helper that connects app backend and gfx backend.

Use for:
- swapchain/environment hookup

Repo mapping:
- hidden inside render/app setup

### `sokol_log`
Debug logging callback bridge.

Use for:
- backend debug messages

### `sokol_gl`
Immediate mode helper layer.

Good for:
- learning
- debug drawing
- simple prototypes

Not ideal for:
- final production renderer once custom batching/sprites exist

### `sokol_shape`
Procedural mesh helpers.

Good for:
- debug shapes
- simple generated geometry

### `sokol_debugtext`
Cheap debug text.

Good for:
- dev HUD
- debug overlays

## What Sokol Does Not Give You

Not by itself:
- entity system
- scene graph
- physics
- level editor
- animation system
- audio design pipeline
- UI framework
- save system
- networking model

You build these.
That is why learning game architecture matters.

## How To Think About It

Sokol is foundation layer.

Stack for your repo:

1. Odin
2. Sokol
3. `sauce/core_*`
4. `sauce/game.odin` and game-specific systems
5. your actual game content

## If You Have A Game Idea

Ask these in order:

1. What is core loop?
2. What is camera type?
3. What is level representation?
4. What moves: tiles, entities, particles, light, UI?
5. What needs shader/render work?
6. What can stay game-side vs what needs engine-side support?

That is how you decide where to work.
