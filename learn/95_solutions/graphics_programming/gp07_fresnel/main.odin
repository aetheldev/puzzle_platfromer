/*
GP07 — Fresnel / Rim Light
==========================
Fresnel: surfaces glow brighter at glancing (edge) angles. Schlick:
    fresnel = pow(1 - max(dot(N, V), 0), power)
At the edge of a sphere the normal is nearly perpendicular to the view, so the
rim lights up. We fake it in 2D: for a disc, the "edge-ness" is just distance
from center, so:
    fres = pow(distance_to_center * 2, power)   // bright toward the rim

This draws one fullscreen quad; the FRAGMENT shader makes a glowing orb.

Read: FS — distance -> rim via pow(.., power); add rim color on a dark base.

`power` is uploaded as a uniform and pulses with time. Controls: none.
*/

package gp07_fresnel

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float2 uv; };
vertex vs_out _main(vs_in in [[stage_in]]) {
    vs_out o; o.position = float4(in.position, 0.0, 1.0); o.uv = in.uv; return o;
}
`
FS :: `
#include <metal_stdlib>
using namespace metal;
struct fs_in { float2 uv; };
struct Params { float power; float aspect; float pad0, pad1; };
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    // center the uv and correct aspect so the orb is round
    float2 n = (in.uv - 0.5) * float2(p.aspect, 1.0);
    float  r = length(n) * 2.4;             // 0 center .. ~1 at orb edge
    if (r > 1.0) { return float4(0.02, 0.03, 0.06, 1.0); } // background
    float fres = pow(clamp(r, 0.0, 1.0), p.power);          // bright toward edge
    float3 base = float3(0.05, 0.10, 0.25);
    float3 rim  = float3(0.4, 0.9, 1.0);
    return float4(base + fres * rim, 1.0);
}
`

Params :: struct #align (16) {
	power:  f32,
	aspect: f32,
	_pad:   [2]f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

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
	t := f32(sapp.frame_count()) * 0.016
	// pulse the Fresnel power so you see the rim sharpen/widen
	params := Params{power = 3.0 + 1.8 * math.sin(t), aspect = f32(W) / f32(H)}
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
		window_title = "GP07 — Fresnel / Rim Light",
		logger       = {func = slog.func},
	})
}
