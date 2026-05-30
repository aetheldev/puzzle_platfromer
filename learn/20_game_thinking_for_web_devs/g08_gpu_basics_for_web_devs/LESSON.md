# G08 — GPU Basics For Web Developers

## Goal

Understand what the GPU does, why games use it, and how the render
pipeline works at a very high level — enough to make the fundamentals
code make sense.

---

## What You Know From The Web

On the web, the browser handles rendering:
- HTML → DOM tree
- CSS → style computation → layout → paint → composite
- The browser decides when to use the GPU (compositing layers, transforms)
- You write CSS, the browser draws pixels

You might have used `<canvas>` or WebGL:
```js
const ctx = canvas.getContext("2d");
ctx.fillRect(100, 200, 50, 50);  // draw a rectangle
```

This is closer to game rendering. But the browser still manages the
GPU context, the swap chain, and the display pipeline.

---

## What The GPU Actually Does

The GPU is a separate processor designed for one thing: drawing many
things in parallel, very fast.

The CPU (your game code) prepares data:
- Vertex positions (corners of rectangles, triangles)
- Colors
- Texture coordinates (which part of an image to use)
- Shader programs (small programs that run on the GPU)

The CPU sends this data to the GPU. The GPU processes it:

```
CPU: "Here are 1000 rectangles with positions and colors."
GPU: "Done. All 1000 drawn in 0.1ms."
```

The GPU can draw thousands of triangles simultaneously because it has
thousands of tiny cores working in parallel. The CPU has 4-16 powerful
cores. The GPU has 1000-10000 simple cores.

---

## The Render Pipeline (Simplified)

```
1. VERTEX DATA       → positions of corners
2. VERTEX SHADER     → transforms positions (camera, projection)
3. RASTERIZATION     → converts triangles to pixels
4. FRAGMENT SHADER   → decides color of each pixel
5. OUTPUT            → final image on screen
```

### Vertex data
Your game sends positions: "the rectangle has corners at (100,200),
(150,200), (150,250), (100,250)."

### Vertex shader
A tiny program running on the GPU that transforms positions. For 2D
games, this usually just applies the camera offset and scales to
screen coordinates.

### Rasterization
The GPU figures out which pixels are inside the triangle/rectangle.

### Fragment shader
A tiny program running on the GPU that decides the color of each pixel.
For simple games: "use this solid color." For advanced: "sample this
texture, apply this glow, mix with this light."

### Output
The final colored pixels are sent to the screen.

---

## What Sokol Does For You

Sokol (`sokol_gfx`) wraps this pipeline so you do not deal with raw
GPU API (Metal, DirectX, OpenGL, WebGPU). It provides:

- `sg.setup()` — initialize the GPU
- `sg.make_image()` — upload a texture
- `sg.make_shader()` — compile shader programs
- `sg.make_pipeline()` — configure how geometry is drawn
- `sg.begin_pass()` / `sg.end_pass()` — start/end a render frame
- `sg.apply_bindings()` — connect textures and buffers
- `sg.draw()` — actually draw geometry
- `sg.commit()` — present to screen

`sokol_gl` (used in fundamentals) is a higher-level helper that hides
most of this behind `sgl.begin_quads()` / `sgl.v2f_c4b()` / `sgl.end()`.

---

## Key Concepts

### Buffer
A block of data on the GPU: vertex positions, colors, indices.
Your game fills buffers and the GPU reads them.

### Texture / Image
A 2D image stored on the GPU. Used for sprites, fonts, backgrounds.
`sg.make_image()` uploads pixel data to GPU memory.

### Shader
A small program written in a shading language (Metal, GLSL, HLSL).
Runs on the GPU per-vertex and per-pixel. Controls appearance.

### Pipeline
Configuration: which shader, what vertex layout, what blend mode.
Created once at startup, applied each frame before drawing.

### Pass
One "round" of rendering. Clear screen → draw stuff → done.
Most 2D games have one pass. Advanced effects (bloom) need multiple.

### Uniform
A value sent from CPU to shader each frame. Example: time, camera
position, color tint.

---

## Why This Matters

When you see in T01:
```odin
sg.setup(...)           // init GPU
sg.begin_pass(...)      // start render frame
sg.end_pass()           // end render frame
sg.commit()             // present
```

You now know: this is setting up the GPU, running one render pass,
and presenting the result. No DOM, no CSS, no browser pipeline.

When you see in T09:
```odin
sg.make_shader(...)     // compile shader on GPU
sg.make_pipeline(...)   // configure how things are drawn
sg.apply_uniforms(...)  // send time value to shader
```

You now know: you are configuring the GPU's tiny programs and sending
them data.

---

## Mental Model

**Web rendering:** A print shop. You give them a document (HTML/CSS).
They handle layout, fonts, images, printing. You do not control the
presses.

**Game rendering:** You ARE the print shop. You load the ink (textures),
set the plate (pipeline), position the paper (vertex data), and run
the press (draw call) 60 times per second. Fast, direct, total control.

---

## Exercises (Thinking, Not Coding)

1. In your own words, explain what vertex data, fragment shader, and
   pipeline mean.

2. Why is the GPU faster than the CPU for drawing 10,000 rectangles?

3. Explain what `sg.begin_pass()` and `sg.commit()` do in terms of
   the render pipeline.

---

## Exit Criteria

- [ ] You can explain CPU→GPU data flow at a high level
- [ ] You know what buffer, texture, shader, pipeline, and pass mean
- [ ] You understand why games use the GPU directly instead of CSS
- [ ] You are ready for T01 because the Sokol calls will make sense

---

## Congratulations

You completed Game Thinking for Web Developers.

You now understand:
- The game loop vs React's render cycle
- Game state as a struct vs useState/Redux
- Immediate mode vs retained mode rendering
- Synchronous frames, no async/await
- Pixel coordinates, no CSS layout
- Polled input, not event-driven
- Delta time for frame-rate independence
- GPU basics and the render pipeline

**Next step:** `learn/30_fundamentals/t01_hello_window`

The code will make sense now.
