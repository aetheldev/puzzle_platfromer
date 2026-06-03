# S04 — CRT / Old TV

This lesson reuses the EXACT plumbing from `s00_foundation`. Only the post
fragment shader (`POST_FS`) and its uniforms change. That is the point:
once you own the skeleton, effects are just shader maths.

## Effect
Fake an old tube TV by stacking cheap tricks: barrel curvature, chromatic
aberration (R/G/B sampled at offsets), scanlines, flicker, vignette.

## New ideas
- Distort uv BEFORE sampling = lens/curvature effects.
- Sampling channels at different offsets = color fringing.
- A real "look" is usually many tiny tricks layered, not one big idea.

## Exercises
1. Strengthen/weaken curvature (`0.12`).
2. Change aberration `off` (color fringing amount).
3. Change scanline count (`540.0`).
4. Remove the bezel early-return and see what curvature alone looks like.

## Read the solution

`learn/95_solutions/shaders/s04_crt/main.odin` — read the top comment and the
`POST_FS` block. The rest is identical to s00.

## Write it yourself

Copy your working s00 `main.odin` into this folder, then change only the
`POST_FS` (and `Post_Params` / per-frame uniform values if the effect needs
them). Build with `zsh build.sh`.

## Finish rule

Run it. Change one number in the shader. Break it on purpose. Fix it. Add one
tweak of your own. Then move on.

Next: `s05_grade`
