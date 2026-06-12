# A03 — Light Is Everything

Goal: flat shapes become objects. One concept: WHERE IS THE LIGHT.
Everything else is bookkeeping.

## The Whole Theory In One Box

1. Pick a light direction. Default forever: **top-left.**
2. Faces toward light = lighter. Faces away = darker.
3. You need only a 3-5 color RAMP per material:
   `shadow / base / light` (+optional darkest / highlight)

That is it. Talent = applying this consistently. Consistency is a
programmer skill.

## The Three Forms (draw all three)

On 24x24 canvas, 3-color gray ramp (dark `#3a3a44`, base `#7a7a88`,
light `#b8b8c4`):

1. **Ball:** light color top-left cluster, base middle, shadow
   bottom-right crescent. Curved shadow boundary = roundness.
2. **Cube:** top face = light, left face = base, right face = shadow.
   HARD edges between faces. Hard boundary = hard form.
3. **Cylinder:** vertical bands light→base→shadow. Vertical
   boundaries, slightly curved.

Every object you will ever draw = these three glued together. A potion
bottle = cylinder + ball. A detective's head = ball. A desk = cubes.

## Two Cheap Tricks That Read As Pro

- **Pillow shading = the #1 beginner tell.** Shading INWARD from the
  outline on all sides (bright center, dark rim all around) = no light
  direction = mush. If your shadow hugs the whole outline, stop.
- **One highlight pixel.** Single lightest pixel at the brightest
  point of a ball/eye/gem = instant material. Don't sprinkle ten.

## Dithering (use sparingly)

Checkerboard pixels between two ramp colors = fake midtone:

```
A A D A A
A D A D A   <- 50% dither band between color A and D regions
D A D A D
```

Good for: large gradients (sky, walls, vignette). Bad for: tiny
sprites (reads as noise at 16x16). Your scenes (a09) will use it;
your icons (a05) mostly will not.

## Drills

1. Ball/cube/cylinder, top-left light, 3-gray ramp
2. SAME three, light from top-RIGHT (re-decide every pixel — proves
   you shaded by rule, not by copying)
3. Combine: draw a tin can (cylinder) on a box (cube) with a marble
   (ball) on top. One light source. Cast a simple floor shadow
   (flattened dark ellipse, offset away from light).
4. Find pillow shading in your own a02 shape. Fix it.

## Exit Criteria

- [ ] Three forms read as 3D at 100% zoom
- [ ] You can flip light direction on demand
- [ ] You can define pillow shading and spot it

## Next

`a04_color_without_fear` — replace gray ramps with real color (the
step where everything suddenly looks GOOD).
