# GP09 — Normal Mapping [MATH]

## Goal

Understand how a flat surface fakes bumps, bricks, and detail without extra
geometry: a **normal map**. Learn what a surface normal is, how an RGB texture
stores normals, and tangent space. [MATH]: it needs per-pixel normals + light,
which is a 3D/lit-2D technique; ships a 2D demo that lights a flat quad with a
normal map so the trick is visible.

---

## The Concept

Lighting depends on the **surface normal** — the direction a surface faces.
`brightness = max(dot(N, L), 0)`: face the light → bright; face away → dark.

A flat quad has ONE normal everywhere, so it lights flatly. A **normal map** is
a texture that stores a DIFFERENT normal per pixel, so each pixel lights as if
the surface were bumpy — even though the geometry stays flat.

### How normals hide in RGB

A normal is a direction `(x, y, z)`, each `-1..1`. A texture stores `0..1`. So:

```
encoded_rgb = normal * 0.5 + 0.5        // pack
normal      = texture.rgb * 2.0 - 1.0   // unpack in the shader
```

That is why normal maps look mostly **bluish**: a flat-facing normal is
`(0, 0, 1)` → encoded `(0.5, 0.5, 1.0)` → light blue. Bumps push toward red/green.

### Tangent space

The stored normals are relative to the surface itself (tangent space), not the
world. To light correctly you build a **TBN basis** (Tangent, Bitangent,
Normal) from the mesh and rotate the sampled normal into world space:

```glsl
float3 n = normalize(normal_tex.rgb * 2.0 - 1.0);   // tangent-space normal
float3 world_n = normalize(TBN * n);                // rotate to world
float  light   = max(dot(world_n, L), 0.0);
```

For a flat 2D quad facing the camera, TBN is nearly identity, so the demo skips
the heavy mesh math and lights directly with the unpacked normal — enough to
SEE the bumps appear.

---

## If You Know JS/React...

No web analog. Closest: a CSS `box-shadow` that fakes depth on a flat element —
except a normal map fakes depth *per pixel* and reacts to a moving light, which
CSS cannot do.

---

## The Demo (2D, illustrative)

Open `learn/95_solutions/graphics_programming/gp09_normal_mapping/main.odin`. It
generates a simple procedural normal map (a grid of bumps) IN the shader (no
asset file needed), then lights a flat quad with a light you move with the
mouse/keys. Toggle the normal map on/off to see flat vs bumpy from the SAME
geometry.

---

## Exercises (math + demo)

1. Toggle the normal map off; confirm the quad lights flat. Why?
2. Move the light around; watch bump shading follow it. Which `dot` causes
   this?
3. Change the procedural bump frequency; finer vs coarser surface.
4. Explain why normal maps look blue and what `(0.5,0.5,1.0)` decodes to.

---

## Exit Criteria

- [ ] You can explain a surface normal and `dot(N, L)` lighting
- [ ] You know the pack/unpack `*2-1` for normal textures
- [ ] You can say what tangent space / TBN is for
- [ ] You ran the demo and saw flat geometry look bumpy

---

## Next Lesson

`learn/47_graphics_programming/gp10_bloom_depth`
