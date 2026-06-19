# Graphics Programming — Deep Dive

[READ + DO] track. Open this AFTER `30_fundamentals` and `45_shaders_postfx`.
Those two teach the *minimum* to ship a 2D game. This folder explains the
*why* underneath — the math and GPU theory that make every effect make sense.

## Who this is for

You can already open a window, draw quads, move a camera, and write a simple
post shader. Now you want to understand:

- Why a "matrix" moves/rotates/scales everything.
- What the vertex shader and fragment shader actually compute.
- The math names you keep hearing (projection, Fresnel, PBR, normal mapping,
  tone mapping, SSAO, color grading).
- How real game assets get made (Blender → UV → texture → lighting).

## Honest scope note

This engine (`sauce/`) and these lessons are **2D, Odin + sokol**. Half the
topics on this list (PBR, normal mapping, SSAO, projection matrices) are
*3D* techniques. You cannot fully run them in a flat 2D pipeline without
building a 3D renderer first — that is a separate, much bigger project.

So each lesson is tagged:

- **[RUN]** — full working Odin + sokol program in this 2D engine. Build it.
- **[MATH]** — theory + the actual shader/CPU math, with a small 2D demo that
  shows the *idea* even if the real use is 3D. You will understand it and could
  port it to a 3D engine later.
- **[GUIDE]** — tool walkthrough (Blender, etc.). No Odin code; step-by-step
  exercises in external tools.

Do not skip the [MATH] ones. Knowing the math is the point of this folder.

## Lessons (in order)

### A. Graphics math — the coordinate machine

| #    | Folder              | Tag    | What you learn |
|------|---------------------|--------|----------------|
| gp01 | `gp01_matrices`     | [RUN]  | what a matrix IS; identity, translate, scale, rotate; multiply order |
| gp02 | `gp02_transform`    | [RUN]  | model matrix = translate × rotate × scale; local vs world space |
| gp03 | `gp03_camera`       | [RUN]  | view matrix = inverse of camera transform; 2D and the 3D idea |
| gp04 | `gp04_projection`   | [MATH] | ortho vs perspective; NDC; the projection matrix; why 3D looks 3D |

### B. Shaders — programs that run on the GPU

| #    | Folder                | Tag    | What you learn |
|------|-----------------------|--------|----------------|
| gp05 | `gp05_vertex_shader`  | [RUN]  | per-vertex program; MVP transform; passing data to fragment stage |
| gp06 | `gp06_fragment_shader`| [RUN]  | per-pixel program; uv, interpolation, time, procedural color |
| gp07 | `gp07_fresnel`        | [RUN]  | edge glow / rim light; `pow(1 - dot(N,V), k)`; faked in 2D |
| gp08 | `gp08_pbr`            | [MATH] | physically based rendering: albedo, metallic, roughness, the BRDF |
| gp09 | `gp09_normal_mapping` | [MATH] | fake surface bumps with a normal texture; tangent space; lighting |

### C. Post-processing — change the final picture

| #    | Folder               | Tag    | What you learn |
|------|----------------------|--------|----------------|
| gp10 | `gp10_bloom_depth`   | [RUN]  | bloom done properly: bright-pass, multi-tap blur, additive composite |
| gp11 | `gp11_tone_mapping`  | [RUN]  | HDR → display; Reinhard & ACES; why bright scenes do not blow out |
| gp12 | `gp12_ssao`          | [MATH] | screen-space ambient occlusion: contact shadows from depth+normals |
| gp13 | `gp13_color_grading` | [RUN]  | mood: contrast, saturation, lift/gamma/gain, LUT idea |

### D. Asset production — making the things you draw

| #    | Folder                  | Tag     | What you learn |
|------|-------------------------|---------|----------------|
| gp14 | `gp14_blender`          | [GUIDE] | Blender from zero: navigation, modeling a prop, exporting |
| gp15 | `gp15_uv`               | [GUIDE] | UV unwrapping: flattening a 3D surface so a texture can sit on it |
| gp16 | `gp16_texture`          | [GUIDE] | making/baking textures: albedo, roughness, normal maps |
| gp17 | `gp17_lighting_setup`   | [GUIDE] | lighting a scene: key/fill/rim, HDRI, baking, color temperature |

## How to use this folder

Same loop as the rest of `learn/`:

1. Read the `LESSON.md`.
2. For [RUN] lessons: read only the marked block of the solution under
   `learn/95_solutions/graphics_programming/<folder>/main.odin`, then write your
   own `main.odin` in the lesson folder and `zsh build.sh`.
3. For [MATH] lessons: do the pen-and-paper / shader-reading exercises. Some
   ship a tiny 2D demo to build.
4. For [GUIDE] lessons: follow the steps in Blender (or your DCC tool).
5. Finish rule: change one thing, break one thing, fix it, add one tweak.

## Shader language note

Same as `45_shaders_postfx`: shaders are written in **MSL (Metal Shading
Language)** as strings, because the bundled `sokol-shdc` does not match these
bindings. The math (dot, pow, mix, smoothstep, matrix multiply) is identical
in GLSL/HLSL — only syntax differs.

## Where this goes next

- `learn/50_advanced/a02_shader_pipeline_and_postfx.md` — production renderer.
- `learn/90_production_with_sauce/` — moving effects into `sauce/`.
