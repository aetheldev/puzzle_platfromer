# Sokol Header Map

If you want to learn Sokol well, learn what each header is for.

## Core Headers

### `sokol_app.h`
App/window/input layer.

Look here when you need:
- keyboard input
- mouse input
- frame callback lifecycle
- window size/fullscreen
- clipboard/drop events

Question example:
- "How do I detect mouse click?"

### `sokol_gfx.h`
Rendering API abstraction.

Look here when you need:
- create texture
- upload vertex/index data
- create shader
- create pipeline
- offscreen render target
- blend modes
- sampler/image binding

Question example:
- "How do I make post-process bloom pass?"

### `sokol_glue.h`
Glue between app backend and graphics backend.

Look here when you need:
- environment setup
- swapchain hookup

Usually you read this less.

### `sokol_log.h`
Backend logging.

Look here when you need:
- better debug messages from backend

## Helper Headers

### `sokol_gl.h`
Immediate-mode helper.

Look here when you need:
- fast debug draw
- simple lines/quads
- quick prototypes

### `sokol_shape.h`
Mesh generation helper.

Look here when you need:
- generated planes/boxes/spheres/etc

### `sokol_debugtext.h`
Debug text.

Look here when you need:
- simple dev text without full font system

### `sokol_time.h`
Timing helper.

Look here when you need:
- precise timing
- profiling helpers

### `sokol_audio.h`
Simple audio output.

In this repo you use FMOD instead, so this is not main path.

## Repo Mapping

### If question is about app lifecycle
Look at:
- `sauce/core_main.odin`
- `sauce/sokol/app/app.odin`

### If question is about rendering
Look at:
- `sauce/core_render.odin`
- `sauce/sokol/gfx/gfx.odin`
- `sauce/shader.glsl`
- `sauce/generated_shader.odin`

### If question is about gameplay architecture
Look at:
- `sauce/game.odin`
- `sauce/entity.odin`

### If question is about build/tooling
Look at:
- `sauce/build/build.odin`
- `build_mac.sh`
- `build_linux.sh`
- `build.bat`

## Learning Rule

Do not try to learn all Sokol headers at once.

Best order:
1. `sokol_app`
2. `sokol_gfx`
3. `sokol_glue`
4. `sokol_gl`
5. rest only when needed
