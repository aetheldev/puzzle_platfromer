# A02 Shader Pipeline And Post FX

Goal: understand the jump from one object shader to full-screen post-processing.

## Beginner Version

Beginner shader work:
- object pulses
- glow layers
- color tints

## Advanced Version

Advanced shader work:
- render scene to offscreen target
- run full-screen pass
- blur bright pixels
- composite bloom back onto main image

## Read

- `learn/90_production_with_sauce/09_visual_effects_roadmap.md`
- `sauce/core_render.odin`
- `sauce/build/build.odin`

## Learn These Terms

1. render target
2. post-process pass
3. full-screen quad
4. additive composite
5. uniform data
6. sampler/image binding

## Practice

- explain difference between object shader and post-process shader
- write down what new renderer data a bloom pass would need

## Production Hint

If you later add bloom in `sauce`, it likely belongs in `core_render.odin`, not in random game code.
