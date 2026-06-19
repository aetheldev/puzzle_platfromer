# GP08 — PBR (Physically Based Rendering) [MATH]

## Goal

Understand the model behind every modern 3D engine's lighting: PBR. What
albedo / metallic / roughness mean, what a BRDF is, and why PBR makes
materials look consistent under any light. This is [MATH]: 3D-only, so theory +
the actual equations + a 2D demo that shows roughness changing a highlight.

---

## The Concept

PBR says: light reflecting off a surface should obey (approximately) real
physics, so the same material looks right in sunlight, a dark cave, or a
showroom. A material is described by a few intuitive textures:

- **Albedo (base color)** — the raw color, no lighting baked in.
- **Metallic** — 0 = dielectric (plastic/wood/stone), 1 = metal. Changes how
  reflections and color behave.
- **Roughness** — 0 = mirror-smooth (tiny sharp highlight), 1 = rough/matte
  (wide dull highlight).
- **Normal** — surface bumps (see gp09).
- (optional) **AO**, **emissive**, **height**.

### BRDF — the lighting equation

A **BRDF** (Bidirectional Reflectance Distribution Function) answers: given a
light direction and a view direction, how much light bounces toward the eye?
The standard real-time BRDF (Cook-Torrance) splits light into:

```
outgoing = diffuse  +  specular
```

- **Diffuse**: matte scatter, roughly `albedo * max(dot(N, L), 0)` (Lambert).
- **Specular**: the shiny highlight, built from three terms:
  - **D** (distribution) — how microfacets spread the highlight → driven by
    **roughness**.
  - **F** (Fresnel) — edge reflectance → the gp07 `pow(1 - dot(H,V))` Schlick.
  - **G** (geometry) — self-shadowing of microfacets at grazing angles.

```
specular = (D * F * G) / (4 * dot(N,L) * dot(N,V))
```

You do not need to memorize the terms today. The takeaways:

1. **Roughness** widens/dulls the highlight (the `D` term).
2. **Fresnel** (gp07) is literally the `F` inside PBR — you already learned a
   piece of PBR.
3. **Metallic** decides whether the surface tints reflections by albedo
   (metal) or keeps them white-ish (dielectric).
4. **Energy conservation**: a surface never reflects more light than it
   receives, so diffuse and specular trade off — that is why PBR "just looks
   right".

---

## If You Know JS/React...

Old web 3D demos hand-tuned shininess per light and broke when you moved the
light. PBR is the design-system version: define the material once with
physical params, and it stays correct everywhere — like tokens vs hardcoded
hex values.

---

## The Demo (2D, illustrative)

Open `learn/95_solutions/graphics_programming/gp08_pbr/main.odin`. It draws a
lit "ball" (shaded disc) with a movable light and a **roughness** slider key.
It implements only the highlight-shape part (Lambert diffuse + a roughness-
controlled specular blob + Fresnel rim). It is NOT full Cook-Torrance, but you
will FEEL roughness widen the highlight and Fresnel brighten the edge — the two
ideas that matter most.

---

## Exercises (math + demo)

1. In the demo, sweep roughness 0→1; describe what happens to the highlight.
2. Move the light; confirm the highlight tracks the half-vector, not the light
   directly.
3. On paper, label which BRDF term (D/F/G) each of roughness and Fresnel feeds.
4. Explain in one sentence why PBR materials survive a lighting change but
   ad-hoc shininess does not.

---

## Exit Criteria

- [ ] You can define albedo, metallic, roughness in one line each
- [ ] You know diffuse vs specular and what controls highlight width
- [ ] You can point to where gp07 Fresnel lives inside the PBR BRDF
- [ ] You ran the demo and saw roughness change the highlight

---

## Next Lesson

`learn/47_graphics_programming/gp09_normal_mapping`
