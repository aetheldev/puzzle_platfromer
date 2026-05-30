/*
TICKET 09 — Custom Shader & Glow Effect
=========================================
GOAL: Write a Metal shader by hand, compile it at runtime via sokol_gfx,
      and use it to draw glowing rectangles with pulsing color.

WHY NOT USE SOKOL-SHDC HERE?
  sokol-shdc is a great tool, but the version bundled with this project
  generates code for a slightly newer sokol API than the bindings in
  sauce/sokol/gfx/gfx.odin.  So for this learning ticket we write the
  shader source directly as a Metal string — this is exactly what shdc
  does internally, and reading it teaches you what the tool produces.
  (In the main project, build.odin calls shdc and the generated .odin
   is committed; that compiled result does match the bindings.)

HOW SOKOL SHADERS WORK (Metal backend):
  1. Write vertex + fragment functions in Metal Shading Language (MSL).
  2. Put the source in Shader_Desc.vertex_func.source / fragment_func.source.
  3. sg.make_shader(desc) compiles them at runtime.
  4. Create a sg.Pipeline that references the shader + describes vertex layout.
  5. Each frame: apply_pipeline → apply_bindings → apply_uniforms → draw.

GLOW TECHNIQUE (single-pass, per-vertex):
  We draw many transparent overlapping quads at slightly different sizes
  with decreasing alpha.  Stacking translucent layers on additive blend
  creates a bloom/halo around the shape without needing a second pass.
  This is a classic "cheap glow" trick.

UNIFORM BLOCK:
  We pass a `time` float to the shader so the color can pulse.

TASKS FOR YOU:
  [ ] Run it: `zsh build.sh`
  [ ] Change GLOW_LAYERS and GLOW_SPREAD to adjust the halo size.
  [ ] Edit the fragment shader to output a different color formula.
  [ ] Add a second rect shape at a different position.
  [ ] Read the MSL source carefully — every line has a comment.
*/

package t09

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

GLOW_LAYERS :: 8      // how many transparent halo layers to draw
GLOW_SPREAD :: 6.0    // how many extra pixels each halo layer adds

// ---- MSL shader source ----
// This is Metal Shading Language — the GPU language on macOS.
//
// Vertex shader: receives (x,y) position in NDC and (r,g,b,a) color.
//   Outputs: clip position + color for the fragment shader.
//
// Fragment shader: receives the interpolated color, multiplies by a
//   time-based pulse, outputs the final pixel color.
//
// Uniform block: `time` is uploaded every frame via apply_uniforms.

MSL_VS :: `
#include <metal_stdlib>
using namespace metal;

// This matches the vertex layout we set up in the Pipeline_Desc below.
struct vs_in {
    float2 position [[attribute(0)]];   // slot 0 → FLOAT2
    float4 color    [[attribute(1)]];   // slot 1 → FLOAT4
};

struct vs_out {
    float4 position [[position]];  // clip-space position (required)
    float4 color;                  // passed to fragment shader
};

vertex vs_out _main(vs_in in [[stage_in]]) {
    vs_out out;
    out.position = float4(in.position, 0.0, 1.0);  // NDC → clip space
    out.color    = in.color;
    return out;
}
`

MSL_FS :: `
#include <metal_stdlib>
using namespace metal;

// Uniform block — must match Glow_Params struct in Odin exactly.
struct Params {
    float time;
    float pad0, pad1, pad2;  // 16-byte alignment
};

struct fs_in {
    float4 color;
};

fragment float4 _main(fs_in in [[stage_in]],
                      constant Params& params [[buffer(0)]])
{
    // Pulse the brightness using sine wave on time.
    float pulse = 0.75 + 0.25 * sin(params.time * 3.0);
    return float4(in.color.rgb * pulse, in.color.a);
}
`

// ---- Odin-side uniform struct (must match MSL Params layout) ----
Glow_Params :: struct #align(16) {
    time: f32,
    _pad: [3]f32,
}

// ---- GPU resources ----
pip:  sg.Pipeline
pip_additive: sg.Pipeline  // same shader, additive blend for glow layers

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

MAX_VERTS :: 4096
vert_data: [MAX_VERTS * 6]f32   // x,y, r,g,b,a per vertex
vert_count: int
vbuf: sg.Buffer

idx_data: [MAX_VERTS / 4 * 6]u16
ibuf: sg.Buffer

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })

    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.04, g=0.04, b=0.08, a=1 } } },
    }

    // ---- vertex buffer (dynamic, updated every frame) ----
    vbuf = sg.make_buffer({
        usage = .DYNAMIC,
        size  = size_of(vert_data),
    })

    // ---- index buffer ----
    max_quads :: MAX_VERTS / 4
    for i in 0..<max_quads {
        base := u16(i * 4)
        idx_data[i*6+0] = base + 0
        idx_data[i*6+1] = base + 1
        idx_data[i*6+2] = base + 2
        idx_data[i*6+3] = base + 0
        idx_data[i*6+4] = base + 2
        idx_data[i*6+5] = base + 3
    }
    ibuf = sg.make_buffer({
        type = .INDEXBUFFER,
        data = { ptr = raw_data(idx_data[:]), size = size_of(idx_data) },
    })

    // ---- shader ----
    shd := sg.make_shader({
        vertex_func   = { source = MSL_VS, entry = "_main" },
        fragment_func = { source = MSL_FS, entry = "_main" },
        uniform_blocks = {
            0 = {
                stage  = .FRAGMENT,
                size   = u32(size_of(Glow_Params)),
                msl_buffer_n = 0,
            },
        },
    })

    // ---- pipeline: normal alpha blend ----
    layout := sg.Vertex_Layout_State{
        attrs = {
            0 = { format = .FLOAT2 },   // position
            1 = { format = .FLOAT4 },   // color
        },
    }
    pip = sg.make_pipeline({
        shader     = shd,
        index_type = .UINT16,
        layout     = layout,
        colors = {
            0 = { blend = {
                enabled         = true,
                src_factor_rgb  = .SRC_ALPHA,
                dst_factor_rgb  = .ONE_MINUS_SRC_ALPHA,
            }},
        },
    })

    // ---- pipeline: additive blend for glow layers ----
    pip_additive = sg.make_pipeline({
        shader     = shd,
        index_type = .UINT16,
        layout     = layout,
        colors = {
            0 = { blend = {
                enabled         = true,
                src_factor_rgb  = .SRC_ALPHA,
                dst_factor_rgb  = .ONE,   // additive: src + dst → brightens
            }},
        },
    })
}

// NDC helpers: convert pixel coords to [-1, +1] range
px_to_ndc_x :: proc(x: f32) -> f32 { return (x / W) * 2.0 - 1.0 }
px_to_ndc_y :: proc(y: f32) -> f32 { return 1.0 - (y / H) * 2.0 }  // flipped

push_quad :: proc(x, y, w, h: f32, r, g, b, a: f32) {
    x0 := px_to_ndc_x(x)
    y0 := px_to_ndc_y(y)
    x1 := px_to_ndc_x(x + w)
    y1 := px_to_ndc_y(y + h)

    base := vert_count * 6
    // 4 vertices × (x, y, r, g, b, a)
    verts := [24]f32{
        x0, y0, r, g, b, a,
        x1, y0, r, g, b, a,
        x1, y1, r, g, b, a,
        x0, y1, r, g, b, a,
    }
    for v, i in verts { vert_data[base + i] = v }
    vert_count += 4
}

// Draw a glowing rect: solid core + additive halo layers
draw_glowing_rect :: proc(bind: ^sg.Bindings, params: ^Glow_Params,
                          x, y, w, h: f32, r, g, b: f32) {
    // Core rect (opaque solid color)
    vert_count = 0
    push_quad(x, y, w, h, r, g, b, 1.0)
    sg.update_buffer(vbuf, { ptr = raw_data(vert_data[:]), size = size_of(vert_data) })
    sg.apply_pipeline(pip)
    sg.apply_bindings(bind^)
    sg.apply_uniforms(0, { ptr = params, size = size_of(Glow_Params) })
    sg.draw(0, 6, 1)

    // Glow layers (additive, growing outward, fading alpha)
    sg.apply_pipeline(pip_additive)
    for i in 1..=GLOW_LAYERS {
        fi     := f32(i)
        expand := fi * GLOW_SPREAD
        alpha  := 0.18 / fi   // outer layers more transparent
        vert_count = 0
        push_quad(x - expand, y - expand, w + expand*2, h + expand*2,
                  r, g, b, alpha)
        sg.update_buffer(vbuf, { ptr = raw_data(vert_data[:]), size = size_of(vert_data) })
        sg.apply_bindings(bind^)
        sg.apply_uniforms(0, { ptr = params, size = size_of(Glow_Params) })
        sg.draw(0, 6, 1)
    }
}

frame :: proc "c" () {
    context = rt_ctx
    t := f32(sapp.frame_count()) * 0.016

    params := Glow_Params{ time = t }

    bind := sg.Bindings{
        vertex_buffers = { 0 = vbuf },
        index_buffer   = ibuf,
    }

    sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })

    // Draw several glowing shapes
    draw_glowing_rect(&bind, &params, 120,  160, 120, 70,  1.0, 0.4, 0.1)  // orange
    draw_glowing_rect(&bind, &params, 360,  100, 90,  90,  0.2, 0.8, 1.0)  // cyan
    draw_glowing_rect(&bind, &params, 600,  220, 150, 60,  0.4, 1.0, 0.3)  // green
    draw_glowing_rect(&bind, &params, 750,  350, 80,  80,  1.0, 0.2, 0.8)  // pink

    // Pulsing white center box
    pulse := 0.5 + 0.5*_sin(t*2)
    sz    := 40 + pulse*20
    draw_glowing_rect(&bind, &params, W/2 - sz/2, H/2 - sz/2, sz, sz, 1.0, 1.0, 0.85)

    sg.end_pass()
    sg.commit()
}

_sin :: proc(x: f32) -> f32 {
    x2 := x*x; return x*(1 - x2/6 + x2*x2/120)
}

cleanup :: proc "c" () {
    context = rt_ctx
    sg.shutdown()
}

main :: proc() {
    rt_ctx = context
    sapp.run({
        init_cb    = init,
        frame_cb   = frame,
        cleanup_cb = cleanup,
        width      = W,
        height     = H,
        window_title = "T09 – Custom Shader & Glow",
        logger     = { func = slog.func },
    })
}
