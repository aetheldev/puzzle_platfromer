# GP05 — Vertex Shader [RUN]

## Goal

Write a real vertex shader. Understand that it is a tiny program the GPU runs
**once per vertex**, whose job is to output the final clip-space position and
hand interpolated data to the fragment stage.

---

## The Concept

You have corners (vertices). For each one, the GPU runs your vertex shader:

```
input:  one vertex (position, color, uv, ...)
output: clip-space position  +  any extras to pass down
```

The classic body is the MVP multiply from gp01-gp04:

```glsl
clip_position = projection * view * model * vec4(local_position, 1.0);
```

Everything you write to a `vs_out` field (color, uv) gets **interpolated**
across the triangle and arrives at the fragment shader smoothly varying. That
interpolation is free and automatic — it is why a gradient quad works.

### What the vertex shader is good for

- Placing geometry (MVP).
- Cheap per-vertex animation: wobble grass, wave a flag, bob a coin — move the
  position with a `sin(time + position.x)` before output.
- Passing data down (uv, world position, a vertex color) to the fragment stage.

It runs far fewer times than the fragment shader (vertices ≪ pixels), so
per-vertex work is cheap.

---

## If You Know JS/React...

There is no web equivalent that runs per-vertex on the GPU. Closest mental
model: `Array.map` over the corners, where the GPU does all the maps in
parallel and then smoothly blends the returned values across each triangle.

---

## Key Concepts (MSL)

```metal
struct vs_in  { float2 position [[attribute(0)]]; float4 color [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float4 color; float time; };

struct Params { float time; float pad0, pad1, pad2; };

vertex vs_out _main(vs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    vs_out o;
    float2 pos = in.position;
    pos.y += sin(p.time + in.position.x * 8.0) * 0.05;   // per-vertex wobble
    o.position = float4(pos, 0.0, 1.0);                  // (no MVP here; already NDC)
    o.color = in.color;
    return o;
}
```

The wobble proves the vertex shader is running and that it moves geometry, not
pixels.

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp05_vertex_shader/main.odin`.

- Read `SCENE_VS`: the wobble + pass-through color.
- Read where `time` is uploaded as a uniform each frame.
- The fragment shader is trivial here on purpose — focus on the vertex stage.

---

## Exercises

1. Increase the wobble amplitude (`0.05` → `0.2`).
2. Change the wobble to depend on `position.y` instead of `position.x`.
3. Add a `scale` uniform and multiply position by it in the vertex shader.
4. Pass a new `vs_out` field and confirm it interpolates (set it from
   `position.x` and read it in the fragment shader as a color).

---

## Exit Criteria

- [ ] You can explain "runs once per vertex, outputs clip position"
- [ ] You moved geometry from inside the vertex shader
- [ ] You know outputs are interpolated to the fragment stage
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp06_fragment_shader`
