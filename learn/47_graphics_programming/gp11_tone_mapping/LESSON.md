# GP11 — Tone Mapping [RUN]

## Goal

Understand why bright scenes need **tone mapping**: the GPU lights in HDR (high
dynamic range, values way above 1.0) but your screen only shows 0..1. Tone
mapping squeezes HDR into displayable range without ugly white blowout. Learn
Reinhard and ACES.

---

## The Concept

After lighting (and bloom), pixel values can exceed 1.0 — a bright sky might be
8.0, a lamp 20.0. If you just clamp to 1.0, everything bright turns flat white
and you lose detail. **Tone mapping** is a curve that maps `[0, ∞)` into
`[0, 1]` gracefully, keeping highlight detail and a filmic roll-off.

### Operators

**Reinhard** — simplest, slightly washed out:
```glsl
float3 reinhard(float3 c) { return c / (1.0 + c); }
```
Never reaches 1.0, so highlights compress smoothly. Cheap, fine for stylized.

**Reinhard (luma) / exposure** — scale by exposure first:
```glsl
c *= exposure;            // control overall brightness BEFORE the curve
c = c / (1.0 + c);
```

**ACES (filmic)** — the film-industry curve most games use; rich contrast,
pleasing highlights:
```glsl
float3 aces(float3 x) {
    float a=2.51, b=0.03, c=2.43, d=0.59, e=0.14;
    return clamp((x*(a*x+b)) / (x*(c*x+d)+e), 0.0, 1.0);
}
```

### Gamma / sRGB

Monitors are not linear. After tone mapping you usually convert linear → sRGB
(`pow(color, 1/2.2)`) so midtones look right. Order: **light → bloom → tone map
→ gamma**.

---

## If You Know JS/React...

A photo app's "exposure" + "highlights" sliders are tone mapping. HDR phone
photos shown on an SDR screen go through exactly this kind of curve.

---

## Key Concepts (MSL)

```metal
fragment float4 _main(..., constant Params& p [[buffer(0)]]) {
    float3 hdr = scene.sample(smp, uv).rgb * p.exposure;
    float3 mapped = (p.mode < 0.5) ? hdr/(1.0+hdr) : aces(hdr);  // Reinhard or ACES
    mapped = pow(mapped, float3(1.0/2.2));                        // gamma
    return float4(mapped, 1.0);
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp11_tone_mapping/main.odin`.

- The scene pushes some **HDR-bright** quads (color > 1.0) so there is real
  range to map.
- Read `POST_FS`: exposure, then Reinhard/ACES toggle, then gamma.
- A key toggles the operator and adjusts exposure.

---

## Exercises

1. Disable tone mapping (just clamp); see bright quads blow out to white.
2. Toggle Reinhard vs ACES; compare highlight feel and contrast.
3. Sweep exposure; note tone mapping keeps it from clipping.
4. Remove the gamma line; explain why midtones look wrong.

---

## Exit Criteria

- [ ] You can explain HDR → display and why clamping is bad
- [ ] You can write Reinhard from memory
- [ ] You know the order light→bloom→tonemap→gamma
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp12_ssao`
