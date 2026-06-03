# S03 — Multiple 2D Lights

This lesson reuses the EXACT plumbing from `s00_foundation`. Only the post
fragment shader (`POST_FS`) and its uniforms change. That is the point:
once you own the skeleton, effects are just shader maths.

## Effect
Many lights at once. Pass an ARRAY of lights as uniforms; the shader loops,
adding each light contribution to a brightness value (ambient + sum).

## New ideas
- Uniform arrays: `float4 lights[4]` packs xy=pos, z=radius, w=intensity.
- Light accumulation: start at ambient, add each falloff, clamp, multiply scene.

## Exercises
1. Add a 5th light (grow the array + loop bound + Post_Params).
2. Give each light a color (multiply a tint per light instead of a scalar).
3. Pulse one light intensity with `sin(time)`.
4. Make light 4 follow the mouse faster/slower.

## Read the solution

`learn/95_solutions/shaders/s03_lights/main.odin` — read the top comment and the
`POST_FS` block. The rest is identical to s00.

## Write it yourself

Copy your working s00 `main.odin` into this folder, then change only the
`POST_FS` (and `Post_Params` / per-frame uniform values if the effect needs
them). Build with `zsh build.sh`.

## Finish rule

Run it. Change one number in the shader. Break it on purpose. Fix it. Add one
tweak of your own. Then move on.

Next: `s04_crt`
