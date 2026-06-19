# GP06 — Fragment Shader [RUN]

## Goal

Write a real fragment shader and understand it is a tiny program the GPU runs
**once per pixel** to decide that pixel's final color. This is where 90% of
"how does it look" lives.

---

## The Concept

After rasterization, every pixel covered by your triangle runs the fragment
shader:

```
input:  interpolated data (uv, color, world pos) for THIS pixel
output: one RGBA color
```

You get `uv` (0..1 across the shape) and any `vs_out` fields, smoothly
interpolated from gp05. From those you compute color with math — no texture
needed to make something interesting:

```glsl
// radial gradient + animated rings, purely procedural
float d = length(uv - 0.5);
float rings = 0.5 + 0.5 * sin(d * 40.0 - time * 3.0);
return float4(rings * float3(0.2, 0.7, 1.0), 1.0);
```

### The mental shift

Fragment shaders are **per-pixel and parallel**. You do not loop over pixels —
you write the formula for ONE pixel and the GPU runs it for all of them at
once. Think "given this uv, what color?" not "for each pixel...".

### Your toolbox

`length`, `dot`, `mix(a,b,t)` (lerp), `smoothstep(a,b,x)` (soft step),
`step`, `fract`, `sin/cos`, `pow`, `clamp`. Almost every effect is these
combined. You already used them in `45_shaders_postfx`.

---

## If You Know JS/React...

A `<canvas>` shader (`gl_FragColor`) or a CSS `radial-gradient` is the idea:
"position in → color out". The fragment shader is that, programmable, running
on thousands of cores at once.

---

## Key Concepts (MSL)

```metal
struct fs_in { float2 uv; float4 color; };
struct Params { float time; float pad0, pad1, pad2; };

fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float d = length(in.uv - 0.5);
    float rings = 0.5 + 0.5 * sin(d * 40.0 - p.time * 3.0);
    float3 col = mix(float3(0.05,0.1,0.2), float3(0.2,0.7,1.0), rings);
    return float4(col, 1.0);
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp06_fragment_shader/main.odin`.

- The vertex shader just passes `uv` and `color` (gp05 covered it).
- Read `SCENE_FS`: procedural rings driven by `uv` and `time`. That is the
  whole lesson.

---

## Exercises

1. Change `d * 40.0` to control ring density.
2. Replace rings with `step(0.5, fract(uv.x * 10.0))` for stripes.
3. Use `smoothstep` to make a soft circle mask, then multiply the color by it.
4. Mix two colors by `uv.x` to make a horizontal gradient. Now make the mix
   factor animate with `time`.

---

## Exit Criteria

- [ ] You can explain "runs per pixel, returns one color"
- [ ] You wrote a procedural color from `uv` + `time`
- [ ] You used at least `mix`, `length`, and `sin`
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp07_fresnel`
