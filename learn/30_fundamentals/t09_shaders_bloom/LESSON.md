# T09 — Custom Shader And Glow Effect

## Goal

Write a custom GPU shader, pass data from CPU to GPU, and create a
glowing pulse effect. This is your first step into GPU programming.

---

## The Concept

Until now, sokol_gl handled all GPU work behind the scenes. Now you
interact with `sokol_gfx` directly:

1. Write shader source (Metal Shading Language on macOS)
2. Create a shader object
3. Create a pipeline (how to draw)
4. Create vertex/index buffers (what to draw)
5. Each frame: bind pipeline → bind buffers → send uniforms → draw

This is the production-style rendering path used in `sauce/core_render.odin`.

---

## If You Know JS...

WebGL is the closest equivalent:
```js
const vs = gl.createShader(gl.VERTEX_SHADER);
gl.shaderSource(vs, vertexShaderCode);
gl.compileShader(vs);
// ... repeat for fragment shader ...
// ... create program, link, set uniforms ...
```

Same concept. Sokol wraps it more cleanly but the ideas are identical:
vertex shader transforms positions, fragment shader outputs colors,
uniforms are per-frame CPU→GPU data.

---

## Key Concepts

### Uniform block
```odin
Glow_Params :: struct #align(16) {
    time: f32,
    _pad: [3]f32,
}
```
Data sent from CPU to GPU each frame. Must be 16-byte aligned for GPU.
The shader reads `time` and uses it to pulse effects.

### Pipeline
Combines shader + vertex layout + blend mode. Created once at startup.
Applied each frame before drawing.

### Additive blending
Normal blend: new pixels replace old.
Additive blend: new pixels are ADDED to old. Bright + bright = brighter.
This creates glow: draw many transparent layers additively.

---

## Line-by-Line Breakdown

Open:
- `learn/95_solutions/fundamentals/t09_shaders_bloom/main.odin`

### Lines 132-231: `init`
Shader source strings → `sg.make_shader()` → `sg.make_pipeline()` for
both normal and additive blend → vertex/index buffers.

### Lines 233-258: `draw_glowing_rect`
Draws core solid rect, then several expanding additive layers with
decreasing alpha. Layers stack = glow effect.

### Lines 260-289: `frame`
For each object: draw core + glow layers. Apply uniforms (time).

---

## Common Mistakes

1. **Forgetting 16-byte alignment on uniform structs** — GPU reads garbage.
2. **Not creating additive blend pipeline** — glow layers look opaque.
3. **Writing too many glow layers** — diminishing returns + slowdown.

---

## Exercises

### Exercise 1 — Basic Shader
Create a custom shader that pulses color based on time uniform.

### Exercise 2 — Additive Glow
Draw one object with 4-6 additive glow layers around it.

### Exercise 3 — Multiple Objects
Draw 3 objects with different glow colors.

### Exercise 4 — Pulse Speed
Change the pulse speed in the fragment shader. Make it faster, slower.

---

## Exit Criteria

- [ ] Custom shader runs
- [ ] Uniform updates every frame
- [ ] Additive glow visible
- [ ] You understand CPU → GPU data flow
- [ ] You can relate this to `sauce/shader.glsl`

---

## Next Lesson

`learn/30_fundamentals/t10_particles_screenshake`
