/*
GP05 — Vertex Shader
====================
The vertex shader runs ONCE PER VERTEX. Its job: output the final clip-space
position and pass interpolated data (color, uv) down to the fragment stage.

This file draws a tessellated grid of vertices and the VERTEX shader wobbles
their positions with sin(time + x). You SEE geometry move from inside the
vertex shader — not pixels. The fragment shader is trivial on purpose.

Read: VS (the wobble + pass-through color). The `time` uniform is uploaded
each frame.

Shaders are MSL strings (same reason as 45_shaders_postfx). Controls: none.
*/

package gp05_vertex_shader

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float4 color [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float4 color; };
struct Params { float time; float pad0, pad1, pad2; };
vertex vs_out _main(vs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    vs_out o;
    float2 pos = in.position;
    // PER-VERTEX wobble: move the geometry, not the pixels.
    pos.y += sin(p.time * 2.0 + in.position.x * 6.0) * 0.08;
    pos.x += cos(p.time * 1.3 + in.position.y * 6.0) * 0.04;
    o.position = float4(pos, 0.0, 1.0);
    o.color = in.color;     // interpolated across the triangle automatically
    return o;
}
`
FS :: `
#include <metal_stdlib>
using namespace metal;
struct fs_in { float4 color; };
fragment float4 _main(fs_in in [[stage_in]]) { return in.color; }
`

Params :: struct #align (16) {
	time: f32,
	_pad: [3]f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
ibuf: sg.Buffer
vcount: int
icount: int
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

// build a GRID of quads so there are many vertices to wobble
GRID :: 16

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

	verts: [dynamic]f32
	idx: [dynamic]u16
	defer { delete(verts); delete(idx) }

	step := f32(2.0) / GRID
	for gy in 0 ..= GRID {
		for gx in 0 ..= GRID {
			x := -1.0 + f32(gx) * step
			y := -1.0 + f32(gy) * step
			r := f32(gx) / GRID
			g := f32(gy) / GRID
			append(&verts, x, y, r, g, 1.0 - r, 1.0)
		}
	}
	row := u16(GRID + 1)
	for gy in 0 ..< GRID {
		for gx in 0 ..< GRID {
			a := u16(gy) * row + u16(gx)
			b := a + 1
			c := a + row
			d := c + 1
			append(&idx, a, b, c, b, d, c)
		}
	}
	vcount = len(verts) / 6
	icount = len(idx)

	vbuf = sg.make_buffer({
		usage = {vertex_buffer = true},
		data  = {ptr = raw_data(verts), size = uint(len(verts) * 4)},
	})
	ibuf = sg.make_buffer({
		usage = {index_buffer = true},
		data  = {ptr = raw_data(idx), size = uint(len(idx) * 2)},
	})

	shd := sg.make_shader({
		vertex_func   = {source = VS, entry = "_main"},
		fragment_func = {source = FS, entry = "_main"},
		uniform_blocks = {
			0 = {stage = .VERTEX, size = u32(size_of(Params)), msl_buffer_n = 0},
		},
	})
	pip = sg.make_pipeline({
		shader     = shd,
		index_type = .UINT16,
		layout     = {attrs = {0 = {format = .FLOAT2}, 1 = {format = .FLOAT4}}},
	})

	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.04, g = 0.05, b = 0.08, a = 1}}},
	}
}

frame :: proc "c" () {
	context = rt_ctx
	params := Params{time = f32(sapp.frame_count()) * 0.016}
	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sg.apply_pipeline(pip)
	sg.apply_bindings({vertex_buffers = {0 = vbuf}, index_buffer = ibuf})
	sg.apply_uniforms(0, {ptr = &params, size = size_of(Params)})
	sg.draw(0, icount, 1)
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run({
		init_cb      = init,
		frame_cb     = frame,
		cleanup_cb   = cleanup,
		width        = W,
		height       = H,
		window_title = "GP05 — Vertex Shader (wobble grid)",
		logger       = {func = slog.func},
	})
}
