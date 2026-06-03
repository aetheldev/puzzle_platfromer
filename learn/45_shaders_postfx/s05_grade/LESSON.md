# S05 — Color Grading / Mood

This lesson reuses the EXACT plumbing from `s00_foundation`. Only the post
fragment shader (`POST_FS`) and its uniforms change. That is the point:
once you own the skeleton, effects are just shader maths.

## Effect
Remap colors to set a mood: contrast, saturation, split-toning (cool shadows,
warm highlights). Same scene can feel cinematic, cold, or sickly.

## New ideas
- Contrast: push values away from 0.5.
- Saturation: `mix(grey, color, sat)` where grey = luminance.
- Split toning: tint dark vs bright areas differently.

## Exercises
1. Set `sat` below 1.0 (desaturated, grim) then above 1.5 (punchy).
2. Change `shadow_tint` / `high_tint` to your game palette.
3. Raise contrast to 1.5; lower to 0.8.
4. Freeze the time-drift and lock in ONE mood you like.

## Read the solution

`learn/95_solutions/shaders/s05_grade/main.odin` — read the top comment and the
`POST_FS` block. The rest is identical to s00.

## Write it yourself

Copy your working s00 `main.odin` into this folder, then change only the
`POST_FS` (and `Post_Params` / per-frame uniform values if the effect needs
them). Build with `zsh build.sh`.

## Finish rule

Run it. Change one number in the shader. Break it on purpose. Fix it. Add one
tweak of your own. Then move on.

Next: `s06_bloom`
