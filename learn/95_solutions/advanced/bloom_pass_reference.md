# Bloom Pass Reference

Goal: understand what a real bloom path needs in `sauce`.

## Where It Belongs

- mostly `sauce/core_render.odin`
- shader files and generated shader binding
- maybe small game-side flags for emissive objects

## Minimum Architecture

1. Render normal scene to offscreen color target
2. Extract bright/emissive pixels
3. Blur them
4. Composite blurred image back over main scene

## New Renderer Pieces

You would likely need:
- offscreen `sg.Image`
- optional second blur image
- pass/attachments for scene render target
- full-screen composite quad
- bloom shader uniform struct

## Data Split

Game code should decide:
- which objects are emissive
- how strong they should glow

Renderer should decide:
- render target creation
- post-process passes
- blur/composite pipeline

## Suggested Sauce Files To Read

- `sauce/core_render.odin`
- `sauce/shader.glsl`
- `sauce/generated_shader.odin`

## Practical First Version

Do this before full bloom:
1. add emissive tint support per object
2. add additive glow sprites on important objects
3. only then move to render-target bloom

## Production Check

Ask before building bloom:
- do I really need full bloom?
- or is additive glow enough for this game?

For Sokoban-like puzzle game, additive glow is often enough.
For lasers, magic, elemental altars, full bloom is more justified.
