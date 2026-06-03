# S01 — Darkness / Torch

This lesson reuses the EXACT plumbing from `s00_foundation`. Only the post
fragment shader (`POST_FS`) and its uniforms change. That is the point:
once you own the skeleton, effects are just shader maths.

## Effect
Everything dim except a circle of light around the mouse (a torch / fog of
war). Keep a small **ambient** floor so dark areas are not pure black.

## New ideas
- `smoothstep(a, b, x)`: soft 0..1 ramp. Makes the light edge soft.
- Aspect-correct the distance (`d.x *= 960/540`) so the light is round, not oval.
- Pass the mouse position into the shader as a uniform (uv 0..1).

## Exercises
1. Change the light radius (`0.45`, `0.05`).
2. Raise/lower `ambient`.
3. Add flicker: multiply light by `0.9 + 0.1*sin(time*20)`.
4. Make the torch warm-tinted (add a little orange inside the light).

## Read the solution

`learn/95_solutions/shaders/s01_darkness/main.odin` — read the top comment and the
`POST_FS` block. The rest is identical to s00.

## Write it yourself

Copy your working s00 `main.odin` into this folder, then change only the
`POST_FS` (and `Post_Params` / per-frame uniform values if the effect needs
them). Build with `zsh build.sh`.

## Finish rule

Run it. Change one number in the shader. Break it on purpose. Fix it. Add one
tweak of your own. Then move on.

Next: `s02_fog`
