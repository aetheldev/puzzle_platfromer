# GP10 — Bloom, Done Properly [RUN]

## Goal

You met cheap bloom in `45_shaders_postfx/s06`. Now do it the way real engines
do: a clean **bright-pass → blur → additive composite** pipeline, and
understand WHY production splits the blur into separable, downsampled passes.

---

## The Concept

Bloom = bright things bleed light into neighbors. Three stages:

1. **Bright-pass**: keep only pixels above a brightness threshold; zero the
   rest. Brightness = `dot(color, vec3(0.2126, 0.7152, 0.0722))` (luma) or
   `max(r,g,b)`. Isolate with `smoothstep(threshold, threshold+knee, b)`.
2. **Blur**: spread the bright pixels. A box/Gaussian average of nearby
   samples. Bigger radius = softer, slower.
3. **Composite**: add the blurred glow back onto the original.
   `final = scene + glow * strength`.

### Why production does it differently

A wide blur done in one pass needs a huge sample grid (slow: cost grows with
radius²). Real engines instead:

- **Separable blur**: blur horizontally, then vertically. Two cheap 1D passes
  give the same result as one expensive 2D pass (cost grows linearly, not
  squared).
- **Downsample**: blur at half/quarter resolution. The glow is soft anyway, so
  low-res is invisible — and 4× fewer pixels = 4× faster.
- **Mip chain**: downsample several times, blur each, add them back up for a
  big soft glow cheaply (this is the modern "dual-filter"/COD bloom).

This lesson's runnable version does a single-pass multi-tap blur (clear, in one
file) but the LESSON explains the production path so you know the upgrade.

---

## If You Know JS/React...

CSS `filter: blur()` + a bright duplicate layer in `screen` blend mode is
hand-made bloom. The browser also blurs in separable, downsampled passes under
the hood — same optimization you are learning here.

---

## Key Concepts (MSL, single-pass version)

```metal
float3 bright_pass(float3 c, float thresh, float knee) {
    float b = max(c.r, max(c.g, c.b));
    float k = smoothstep(thresh, thresh + knee, b);
    return c * k;
}
// blur: average an N x N grid of texel-offset samples of the bright-pass
// composite: scene + glow * strength
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp10_bloom_depth/main.odin`.

- Read `POST_FS`: bright-pass, then the blur loop, then `scene + glow*strength`.
- Note the uniforms: `threshold`, `knee`, `strength`, blur `radius`.

---

## Exercises

1. Raise/lower `threshold`; watch which pixels bloom.
2. Increase blur `radius`; note it gets softer AND slower (this is why
   production downsamples).
3. Sketch how you would split this loop into a horizontal then vertical pass.
4. Make a few scene quads HDR-bright (color > 1.0) and confirm only they bloom.

---

## Exit Criteria

- [ ] You can name the three bloom stages
- [ ] You can explain separable + downsampled blur and why it is faster
- [ ] You tuned threshold/strength/radius and saw each change
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp11_tone_mapping`
