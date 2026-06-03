# S06 — Bloom / Glow

This lesson reuses the EXACT plumbing from `s00_foundation`. Only the post
fragment shader (`POST_FS`) and its uniforms change. That is the point:
once you own the skeleton, effects are just shader maths.

## Effect
Bright things bleed light into neighbors. Recipe: bright-pass (keep bright
pixels) → blur (average nearby samples) → composite (add glow back on top).

## New ideas
- Threshold with `smoothstep` to isolate bright areas.
- Blur = average a grid of offset samples.
- Additive composite = `base + glow`.

## Exercises
1. Change the bright threshold (`0.6`, `0.9`).
2. Change the blur range (loop `-3..3`) — bigger = softer, slower.
3. Change glow strength (`*1.6`).
4. Make the center cyan box much brighter and watch it bloom hardest.

## Production note
Real engines blur in separate downsampled passes for speed/quality. Same
idea, more passes — see `learn/50_advanced/a03_production_glow_and_bloom.md`.

## Read the solution

`learn/95_solutions/shaders/s06_bloom/main.odin` — read the top comment and the
`POST_FS` block. The rest is identical to s00.

## Write it yourself

Copy your working s00 `main.odin` into this folder, then change only the
`POST_FS` (and `Post_Params` / per-frame uniform values if the effect needs
them). Build with `zsh build.sh`.

## Finish rule

Run it. Change one number in the shader. Break it on purpose. Fix it. Add one
tweak of your own. Then move on.

Next: combine effects on your real game (sokoban / juice_playground), or `learn/50_advanced`
