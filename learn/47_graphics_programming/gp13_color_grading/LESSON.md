# GP13 — Color Grading [RUN]

## Goal

You touched this in `45_shaders_postfx/s05`. Go deeper: the full grading
toolkit — contrast, saturation, lift/gamma/gain (shadows/mids/highlights), and
the **LUT** idea that real games and films use. Mood is a post shader, not
repainted art.

---

## The Concept

Color grading reinterprets the final image's colors to set MOOD: cold horror,
warm sunset, bleak desaturated war film. Same scene, different feeling. The
operations, applied in order:

### 1. Exposure / brightness
```glsl
c *= exposure;
```

### 2. Contrast (push around mid-gray 0.5)
```glsl
c = (c - 0.5) * contrast + 0.5;
```

### 3. Saturation (mix toward luma gray)
```glsl
float l = dot(c, float3(0.2126, 0.7152, 0.0722));
c = mix(float3(l), c, saturation);   // 0 = grayscale, 1 = normal, >1 = punchy
```

### 4. Lift / Gamma / Gain (the colorist's three dials)
- **Lift** — shifts SHADOWS (add a color to darks).
- **Gamma** — shifts MIDTONES (`pow`).
- **Gain** — shifts HIGHLIGHTS (multiply brights).
```glsl
c = pow(c * gain + lift, float3(1.0/gamma));
```
Tint lift blue + gain orange = the classic teal-and-orange blockbuster look.

### 5. LUT (Lookup Table) — how production ships grades

A **LUT** is a precomputed cube of "input color → output color". An artist
grades a screenshot in Photoshop/DaVinci, exports the transformation as a
small 3D texture, and the shader just *looks up* the result per pixel:
```glsl
graded = sample_lut(lut_texture, scene_color);   // one texture read
```
Cheap, and any complex grade an artist can imagine works with no shader edits.
Production uses LUTs; this lesson does the math live so you understand what a
LUT bakes.

---

## If You Know JS/React...

Instagram filters are LUTs. CSS `filter: contrast() saturate() sepia()` is a
fixed grading chain. Here you build and tune the chain yourself.

---

## Key Concepts (MSL)

```metal
float3 grade(float3 c, constant Params& p) {
    c *= p.exposure;
    c = (c - 0.5) * p.contrast + 0.5;
    float l = dot(c, float3(0.2126, 0.7152, 0.0722));
    c = mix(float3(l), c, p.saturation);
    c = pow(max(c * p.gain + p.lift, 0.0), float3(1.0/p.gamma));
    return clamp(c, 0.0, 1.0);
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp13_color_grading/main.odin`.

- Read `POST_FS` `grade()`: the ordered chain above.
- Keys cycle presets (neutral, teal/orange, horror desaturate, warm sunset).

---

## Exercises

1. Build a "horror" grade: low saturation, cool lift, crushed contrast.
2. Build "teal & orange": blue lift, orange gain.
3. Set saturation to 0; full grayscale. To 1.5; punchy.
4. Explain what a LUT bakes and why production prefers it over live math.

---

## Exit Criteria

- [ ] You can name the grading chain order
- [ ] You can explain lift/gamma/gain (shadows/mids/highlights)
- [ ] You can explain what a LUT is and why games use it
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp14_blender`
