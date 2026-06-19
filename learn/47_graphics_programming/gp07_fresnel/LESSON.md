# GP07 — Fresnel / Rim Light [RUN]

## Goal

Understand the Fresnel effect: surfaces get brighter/more reflective at
glancing angles (the edges facing away from you). It is the rim-light glow you
see on shields, bubbles, hologram edges, water. We fake it in 2D so you own the
formula before using it in 3D.

---

## The Concept

Real Fresnel: the more grazing your view angle to a surface, the more it
reflects. At edges (normal nearly perpendicular to your eye) reflectance is
high; head-on it is low. The famous approximation (Schlick):

```glsl
fresnel = pow(1.0 - max(dot(N, V), 0.0), power);
//        N = surface normal,  V = view direction,  power = sharpness
```

`dot(N, V)` is 1 when looking straight at the surface (→ fresnel 0) and 0 at
the edge (→ fresnel 1). `pow(.., power)` tightens the rim. Multiply by a glow
color and add it on top:

```glsl
color += fresnel * rim_color;
```

### Faking it in 2D

We have no real 3D normals, but for a circle the normal direction at any pixel
is just `normalize(uv - center)`, and "view" points at the camera (straight
out). The edge of the circle = grazing angle = bright rim. So:

```glsl
float2 n = (uv - 0.5);
float edge = length(n) * 2.0;           // 0 center .. 1 edge
float fres = pow(edge, power);          // bright toward edge
```

Same `pow(1 - facing)` shape, just expressed with distance. You SEE the rim
glow and you learn the curve `power` controls.

---

## If You Know JS/React...

That subtle bright outline on a frosted-glass / glassmorphism card is a
hand-tuned fake Fresnel. Here you compute it instead of eyeballing a
`box-shadow`.

---

## Key Concepts (MSL)

```metal
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float2 n   = in.uv - 0.5;
    float  r   = length(n) * 2.0;          // 0..1
    if (r > 1.0) discard_fragment();        // outside the disc
    float  fres = pow(clamp(r, 0.0, 1.0), p.power);
    float3 base = float3(0.05, 0.10, 0.25);
    float3 rim  = float3(0.4, 0.9, 1.0);
    return float4(base + fres * rim, 1.0);
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp07_fresnel/main.odin`.

- Read `SCENE_FS`: the distance→rim mapping and `pow(.., power)`.
- `power` is a uniform you can tweak; read where it is uploaded.

---

## Exercises

1. Tune `power`: low (1.5) = wide glow, high (6) = thin sharp rim.
2. Animate `power` or rim brightness with `time` for a pulsing shield.
3. Add the rim glow on top of a textured/colored fill instead of flat base.
4. Read the real Schlick form `pow(1 - dot(N,V), power)` and explain how the 2D
   distance version stands in for `1 - dot(N,V)`.

---

## Exit Criteria

- [ ] You can write the Schlick Fresnel approximation from memory
- [ ] You can explain why edges glow and centers do not
- [ ] You tuned `power` and saw the rim change
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp08_pbr`
