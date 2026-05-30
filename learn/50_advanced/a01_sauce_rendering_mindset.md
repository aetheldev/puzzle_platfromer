# A01 Sauce Rendering Mindset

Goal: stop thinking only in terms of "draw something cool" and start thinking in terms of render architecture.

## Read First

- `sauce/core_render.odin`
- `sauce/shader.glsl`
- `sauce/generated_shader.odin`

## What To Learn

1. current draw path
2. what data each quad carries
3. where shader params come from
4. what would need to change for advanced effects

## Questions To Ask

1. Can this effect be faked with existing quads and colors?
2. Does it need a new per-instance shader param?
3. Does it need a new texture or atlas entry?
4. Does it need an offscreen render pass?
5. Does it belong in game code or renderer code?

## Practice

- list 3 effects that can stay game-side only
- list 3 effects that would probably need `core_render` work

Examples:
- game-side only: hit flash, shadow sprite, simple additive glow sprite
- renderer-side: bloom pass, blur pass, render target chain, dynamic light mask
