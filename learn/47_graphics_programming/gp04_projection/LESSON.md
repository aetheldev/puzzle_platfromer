# GP04 — Projection [MATH]

## Goal

Understand the last matrix in the MVP chain: **projection**. It maps your
world onto the flat screen and defines **NDC** (normalized device coordinates).
This is where 3D gets its sense of depth. No 3D engine here, so this is a
[MATH] lesson — theory, the actual matrices, and a tiny 2D demo of NDC.

---

## The Concept

After model and view, vertices live in **view space** (relative to the camera).
The GPU does not draw in your units — it wants **NDC**: a cube where every axis
runs `-1 .. +1`. Whatever lands in that cube is on screen; the rest is clipped.

The **projection matrix** maps view space into that `-1..1` cube. Two kinds:

### Orthographic (what 2D uses)

No perspective. Parallel lines stay parallel. Far things are NOT smaller. You
already use this every time you call `sgl.ortho` or map pixels to NDC:

```
ndc_x = (x / W) * 2 - 1
ndc_y = 1 - (y / H) * 2     // y flipped: screen y grows down, NDC up
```

As a matrix, ortho just scales+offsets each axis into `-1..1`.

### Perspective (what makes 3D look 3D)

Far objects shrink. The trick: divide x and y by depth z. The projection matrix
stuffs `z` into the 4th coordinate `w`, and the GPU does the **perspective
divide** `(x/w, y/w, z/w)` automatically after the vertex shader.

```
clip = projection * view * model * point      // vertex shader outputs clip (xyzw)
ndc  = clip.xyz / clip.w                       // GPU divides -> perspective
```

That single divide-by-w is *the* reason a hallway converges to a vanishing
point. Parameters of a perspective matrix:

- **fov** — field of view (zoom-ish; wide angle = fish-eye).
- **aspect** — width/height, so circles are not ovals.
- **near / far** — clip planes; anything outside is discarded.

`core:math/linalg` has both: `matrix4_perspective_f32` and
`matrix_ortho3d_f32`. You would use them once you build a 3D renderer.

---

## If You Know JS/React...

CSS `perspective: 800px` plus `transform: rotateY(40deg)` is literally a
perspective projection matrix. `perspective: none` (the default for layout) is
orthographic. Same math, hidden by the browser.

---

## The Demo (tiny, 2D)

Open `learn/95_solutions/graphics_programming/gp04_projection/main.odin`. It is
small on purpose. It draws a grid of points in "world" units and lets you
toggle between:

- **ortho mapping** — points keep even spacing (2D look).
- **fake perspective** — each point's distance from a center is divided by a
  fake depth, so far points crowd toward a vanishing point.

This is NOT a real 3D pipeline; it shows the *divide-by-depth* idea so the math
is concrete. Build it with `zsh build.sh` in that folder; SPACE toggles
ortho/perspective.

---

## Exercises (mostly thinking + the demo)

1. In the demo, change the fake depth scale; watch the vanishing point tighten.
2. Write out the ortho mapping math for a 1280×720 window by hand.
3. Explain in one sentence why perspective needs a `w` divide but ortho does
   not.
4. Look up `linalg.matrix4_perspective_f32`'s parameters; write what fov, near,
   and far each control.

---

## Exit Criteria

- [ ] You can explain NDC and the `-1..1` cube
- [ ] You can write the pixel→NDC ortho mapping from memory
- [ ] You can explain the perspective divide-by-w in plain words
- [ ] You know when you'd use ortho vs perspective

---

## Next Lesson

`learn/47_graphics_programming/gp05_vertex_shader`
