# S00 — Post-Processing Foundation

This is the most important lesson in the whole track. Everything else is a
small variation on it.

## The pattern

```
PASS 1 (offscreen): draw your game into a TEXTURE (not the window)
PASS 2 (display):   draw ONE fullscreen rectangle; a fragment shader reads
                    that texture per pixel and outputs the final color
```

The fragment shader in pass 2 is where every effect lives. Change it →
change the look. The game never knows.

## Pieces you set up (once)

1. An offscreen color image: `sg.make_image({ render_target = true, ... })`.
2. A sampler: how the post shader reads that image (`sg.make_sampler`).
3. Attachments: "the offscreen pass draws into this image"
   (`sg.make_attachments`).
4. A scene pipeline (draws quads, output pixel_format = `.RGBA8` to match the
   target).
5. A fullscreen quad (2 triangles, NDC -1..1, with uv 0..1).
6. A post pipeline whose shader declares: 1 uniform block, 1 image, 1 sampler,
   1 image_sampler_pair.

Then each frame:
```
begin_pass(attachments) -> draw scene -> end_pass      // into texture
begin_pass(swapchain)  -> draw fullscreen quad w/ post shader -> end_pass
commit()
```

## Read the solution

`learn/95_solutions/shaders/s00_foundation/main.odin` — read the WHOLE file
once; every block is commented. Pay attention to:
- `init`: the 6 setup pieces above
- `frame`: the two passes
- `POST_FS`: the (simple) vignette + scanline effect

## Write it yourself

Recreate it from memory in this folder's `main.odin`. Get a window where the
moving boxes are visibly darker at the edges. That proves both passes work.

## Exercises

1. Run it. Confirm edges are darker (vignette) and a faint scanline moves.
2. In `POST_FS`, comment out the vignette line — confirm the picture flattens.
3. Change the clear color of the SCENE pass vs the DISPLAY pass; see which
   one you actually see (the display pass covers the window).
4. Make the vignette stronger/weaker (the `smoothstep(0.75, 0.30, dist)`).

## Exit criteria

- [ ] Two passes working: scene → texture → post → window
- [ ] You can point to where the effect (vignette) is computed
- [ ] You changed the vignette strength and saw it

Next: `s01_darkness`.
