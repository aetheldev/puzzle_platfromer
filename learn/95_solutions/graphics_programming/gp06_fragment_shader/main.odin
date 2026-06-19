/*
GP06 — Fragment Shader
======================
The fragment shader runs ONCE PER PIXEL and returns that pixel's final color.
This file draws one fullscreen quad and computes a procedural image entirely
in the FRAGMENT shader from `uv` + `time` — no texture needed.

Mental shift: you do NOT loop over pixels. You write the formula for ONE pixel
("given this uv, what color?") and the GPU runs it for all of them in parallel.

Read: FS — animated rings via length(uv-0.5) + sin + mix.

No render-to-texture here on purpose: just a quad whose fragment shader makes
the picture. Shaders are MSL strings. Controls: none.
*/

package gp06_fragment_shader

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
struct vs_in  { float2 position [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float2 uv; };
vertex vs_out _main(vs_in in [[stage_in]]) {
    vs_out o;
    o.position = float4(in.position, 0.0, 1.0);
    o.uv = in.uv;
    return o;
}
`
FS :: `
#include <metal_stdlib>
using namespace metal;
struct fs_in { float2 uv; };
struct Params { float time; float pad0, pad1, pad2; };
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float2 uv = in.uv;
    float d = length(uv - 0.5);
    // animated concentric rings: density 40, scrolling with time
    float rings = 0.5 + 0.5 * sin(d * 40.0 - p.time * 3.0);
    float3 col = mix(float3(0.05, 0.10, 0.20), float3(0.20, 0.70, 1.00), rings);
    // a soft circular vignette so the center pops
    col *= smoothstep(0.9, 0.2, d);
    return float4(col, 1.0);
}
`

Params :: struct #align (16) {
	time: f32,
	_pad: [3]f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

	// fullscreen quad: x,y (NDC) + u,v
	quad := [?]f32{
		-1, -1, 0, 1,   1, -1, 1, 1,   1, 1, 1, 0,
		-1, -1, 0, 1,   1,  1, 1, 0,  -1, 1, 0, 0,
	}
	vbuf = sg.make_buffer({
		usage = {vertex_buffer = true},
		data  = {ptr = raw_data(quad[:]), size = size_of(quad)},
	})

	shd := sg.make_shader({
		vertex_func    = {source = VS, entry = "_main"},
		fragment_func  = {source = FS, entry = "_main"},
		uniform_blocks = {0 = {stage = .FRAGMENT, size = u32(size_of(Params)), msl_buffer_n = 0}},
	})
	pip = sg.make_pipeline({
		shader = shd,
		layout = {attrs = {0 = {format = .FLOAT2}, 1 = {format = .FLOAT2}}},
	})

	pass_action = {colors = {0 = {load_action = .CLEAR}}}
}

frame :: proc "c" () {
	context = rt_ctx
	params := Params{time = f32(sapp.frame_count()) * 0.016}
	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sg.apply_pipeline(pip)
	sg.apply_bindings({vertex_buffers = {0 = vbuf}})
	sg.apply_uniforms(0, {ptr = &params, size = size_of(Params)})
	sg.draw(0, 6, 1)
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
		window_title = "GP06 — Fragment Shader",
		logger       = {func = slog.func},
	})
}
