# GP12 — SSAO (Screen-Space Ambient Occlusion) [MATH]

## Goal

Understand SSAO: the soft contact shadows in corners, crevices, and where
objects meet. It makes 3D scenes look grounded and "expensive". [MATH]: it
needs a **depth buffer** and **normals**, which a flat 2D pipeline does not
produce, so this is theory + the algorithm + a 2D demo that fakes a depth map
so you see the darkening appear.

---

## The Concept

**Ambient occlusion** = how much surrounding geometry blocks the ambient
(sky/bounce) light reaching a point. Deep in a corner: lots blocked → darker.
Open flat wall: little blocked → bright. It is the subtle dirt-in-the-corners
shading that sells realism.

**Screen-space** AO computes it cheaply from buffers you already have after
rendering, instead of expensive ray tracing:

### Inputs (the G-buffer)

- **Depth** — distance from camera per pixel.
- **Normal** — surface direction per pixel (gp09).

### Algorithm (per pixel)

1. Read this pixel's view-space **position** (from depth) and **normal**.
2. Sample several random points in a hemisphere oriented along the normal.
3. For each sample, project it to screen and read the depth there.
4. If the stored depth is CLOSER than the sample (something is in front),
   that sample is **occluded**.
5. `occlusion = occluded_count / total_samples`. Darken ambient by it.
6. **Blur** the noisy result (the random sampling makes it grainy).

```
ao = 1.0;
for each sample s in hemisphere(normal):
    p = view_pos + s * radius;
    if (depth_at(project(p)) < p.z) ao -= 1.0/num_samples;   // occluded
ambient *= ao;
```

Key knobs: **radius** (how far to check), **sample count** (quality vs speed),
**bias** (avoid self-occlusion artifacts), **blur** (clean up noise).

---

## If You Know JS/React...

No web analog. Closest intuition: the soft inner shadow you'd manually paint in
the corners of a card stack to make it look layered — SSAO computes that
automatically from scene depth.

---

## The Demo (2D, illustrative)

Open `learn/95_solutions/graphics_programming/gp12_ssao/main.odin`. It builds a
fake "depth map" (some raised boxes on a floor) in the scene pass, then the post
shader does a simplified SSAO: for each pixel it samples neighbors and darkens
where neighbors are "higher" (closer). You will see soft dark halos appear
around the boxes — the SSAO look — with a togglable radius/strength.

It is NOT a real hemisphere-sampled G-buffer SSAO, but it demonstrates the core
idea: **compare neighbor depths, darken where blocked**.

---

## Exercises (math + demo)

1. Increase the sample radius; halos grow. Relate to the real `radius` knob.
2. Increase strength; corners get darker. Where would over-darkening look bad?
3. Toggle the blur step; see the noise it removes.
4. On paper, list the two G-buffer inputs real SSAO needs and why each matters.

---

## Exit Criteria

- [ ] You can explain ambient occlusion in one sentence
- [ ] You know SSAO uses depth + normals from screen space
- [ ] You can describe the sample-and-compare-depth loop
- [ ] You ran the demo and saw contact-shadow darkening

---

## Next Lesson

`learn/47_graphics_programming/gp13_color_grading`
