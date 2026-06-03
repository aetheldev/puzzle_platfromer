# S02 — Animated Fog

This lesson reuses the EXACT plumbing from `s00_foundation`. Only the post
fragment shader (`POST_FS`) and its uniforms change. That is the point:
once you own the skeleton, effects are just shader maths.

## Effect
Drifting fog = blend the scene toward a grey color by a NOISE value that
scrolls over time. Thicker near the ground.

## New ideas
- `hash` / `noise` / `fbm`: make organic randomness on the GPU, no texture needed.
- `mix(scene, fog_color, density)`: fog is literally a blend.
- Bias density by `uv.y` for heavier ground fog.

## Exercises
1. Change the noise scale (`uv * 3.0`) — bigger vs smaller fog clumps.
2. Change scroll speed (the `time*0.06`).
3. Change `fog_color` to a spooky green or warm dusty orange.
4. Make fog heavier at the TOP instead of the bottom.

## Read the solution

`learn/95_solutions/shaders/s02_fog/main.odin` — read the top comment and the
`POST_FS` block. The rest is identical to s00.

## Write it yourself

Copy your working s00 `main.odin` into this folder, then change only the
`POST_FS` (and `Post_Params` / per-frame uniform values if the effect needs
them). Build with `zsh build.sh`.

## Finish rule

Run it. Change one number in the shader. Break it on purpose. Fix it. Add one
tweak of your own. Then move on.

Next: `s03_lights`
