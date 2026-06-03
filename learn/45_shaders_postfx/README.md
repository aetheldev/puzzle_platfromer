# Shaders & Post-Processing — Make It Look Pro

[DO] track. Do this AFTER `30_fundamentals/t09_shaders_bloom` (your first
hand-written shader) and after `40_vfx` (sgl particle tricks).

## What you learn here

The single most important visual-programming pattern in games:

> **Render the whole game into a texture, then draw that texture to the
> screen through a fragment shader that changes how it looks.**

That one pattern (called *post-processing*) is how nearly every "great
looking" 2D/3D game does darkness, fog, lights, CRT/TV looks, color mood,
and glow. The game logic never changes — you just reinterpret the final
picture on the GPU.

## Why it matters

You said you don't want your games to look basic. Art takes years; post-FX
takes minutes and transforms the SAME scene. A flat box scene + a good post
shader looks like a real game. This is the highest-leverage visual skill.

## Lessons (in order)

| # | Folder | Effect | Core idea |
|---|--------|--------|-----------|
| s00 | `s00_foundation`   | (vignette) | render-to-texture + fullscreen quad. THE skeleton. |
| s01 | `s01_darkness`     | torch/fog-of-war | one moving light, ambient floor, smoothstep |
| s02 | `s02_fog`          | drifting fog | GPU noise (hash/fbm), mix toward fog color |
| s03 | `s03_lights`       | many 2D lights | uniform arrays, accumulate light |
| s04 | `s04_crt`          | old TV | curvature + chroma aberration + scanlines |
| s05 | `s05_grade`        | color mood | contrast, saturation, split-toning |
| s06 | `s06_bloom`        | glow | bright-pass + blur + composite |

## How these lessons work

Every solution shares the SAME render-to-texture plumbing. From s01 on,
**only the fragment shader (`POST_FS`) and its uniforms change**. That is the
whole lesson: learn the skeleton once (s00), then effects are just shader maths.

- Read each `LESSON.md`.
- Read only the `POST_FS` block of the matching solution under
  `learn/95_solutions/shaders/<folder>/main.odin`.
- Write your own `main.odin` in the lesson folder, then `zsh build.sh`.
- Finish rule: change a number, break it, fix it, add one tweak.

## Shader language note

These use **MSL (Metal Shading Language)** written directly as strings, same
as `t09`, because the bundled `sokol-shdc` version does not match these
bindings. Writing MSL by hand teaches you what a shader really is. The maths
(noise, smoothstep, mix, vignette) is identical in GLSL/HLSL — only syntax
differs.

## Where this goes next

- `learn/50_advanced/a02_shader_pipeline_and_postfx.md` — production multi-pass
  bloom and how this fits a real renderer.
- `learn/90_production_with_sauce/09_visual_effects_roadmap.md` — moving FX into
  `sauce/core_render.odin`.
- Combine: put your sokoban/juice game scene through s01 darkness + s02 fog.
