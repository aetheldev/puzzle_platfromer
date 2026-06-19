/*
GP13 — Color Grading
====================
Color grading reinterprets the final image's colors to set MOOD. The chain,
in order: exposure -> contrast -> saturation -> lift/gamma/gain.

This demo builds a colorful procedural scene, then runs the grade() chain with
switchable PRESETS (neutral, teal/orange, horror desaturate, warm sunset) so
you see the SAME scene change feeling.

Read: FS — grade(): the ordered chain. Note lift=shadows, gamma=mids,
gain=highlights. Production bakes a grade like this into a LUT (see LESSON).

Controls:  SPACE = cycle preset
*/

package gp13_color_grading

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
    vs_out o; o.position = float4(in.position, 0.0, 1.0); o.uv = in.uv; return o;
}
`
FS :: `
#include <metal_stdlib>
using namespace metal;
struct fs_in { float2 uv; };
struct Params {
    float exposure; float contrast; float saturation; float pad0;
    float3 lift;  float pad1;
    float3 gain;  float pad2;
    float3 gamma; float pad3;
};
float3 scene(float2 uv) {
    // a colorful test image: gradient + a few blobs
    float3 c = mix(float3(0.2,0.3,0.5), float3(0.9,0.7,0.4), uv.x);
    c = mix(c, float3(0.3,0.7,0.4), smoothstep(0.4,0.0,length(uv-float2(0.3,0.6))));
    c = mix(c, float3(0.9,0.3,0.3), smoothstep(0.3,0.0,length(uv-float2(0.7,0.4))));
    return c;
}
float3 grade(float3 c, constant Params& p) {
    c *= p.exposure;                                  // 1. exposure
    c = (c - 0.5) * p.contrast + 0.5;                 // 2. contrast about mid-gray
    float l = dot(c, float3(0.2126, 0.7152, 0.0722)); // luma
    c = mix(float3(l), c, p.saturation);              // 3. saturation
    c = pow(max(c * p.gain + p.lift, 0.0), 1.0 / p.gamma); // 4. lift/gamma/gain
    return clamp(c, 0.0, 1.0);
}
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    return float4(grade(scene(in.uv), p), 1.0);
}
`

Params :: struct #align (16) {
	exposure:   f32,
	contrast:   f32,
	saturation: f32,
	_pad0:      f32,
	lift:       [3]f32,
	_pad1:      f32,
	gain:       [3]f32,
	_pad2:      f32,
	gamma:      [3]f32,
	_pad3:      f32,
}

PRESETS := [4]Params{
	// neutral
	{exposure = 1, contrast = 1, saturation = 1, lift = {0, 0, 0}, gain = {1, 1, 1}, gamma = {1, 1, 1}},
	// teal & orange: blue lift, orange gain, punchy
	{exposure = 1.05, contrast = 1.15, saturation = 1.2, lift = {-0.02, 0.0, 0.05}, gain = {1.15, 1.0, 0.85}, gamma = {1, 1, 1}},
	// horror: desaturated, cool, crushed
	{exposure = 0.9, contrast = 1.25, saturation = 0.35, lift = {0.0, 0.0, 0.04}, gain = {0.85, 0.9, 1.0}, gamma = {0.9, 0.9, 0.95}},
	// warm sunset
	{exposure = 1.1, contrast = 1.05, saturation = 1.25, lift = {0.04, 0.01, -0.02}, gain = {1.2, 1.0, 0.8}, gamma = {1.05, 1.0, 0.95}},
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context
preset: int = 0

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	quad := [?]f32{
		-1, -1, 0, 1,   1, -1, 1, 1,   1, 1, 1, 0,
		-1, -1, 0, 1,   1,  1, 1, 0,  -1, 1, 0, 0,
	}
	vbuf = sg.make_buffer({usage = {vertex_buffer = true}, data = {ptr = raw_data(quad[:]), size = size_of(quad)}})
	shd := sg.make_shader({
		vertex_func    = {source = VS, entry = "_main"},
		fragment_func  = {source = FS, entry = "_main"},
		uniform_blocks = {0 = {stage = .FRAGMENT, size = u32(size_of(Params)), msl_buffer_n = 0}},
	})
	pip = sg.make_pipeline({shader = shd, layout = {attrs = {0 = {format = .FLOAT2}, 1 = {format = .FLOAT2}}}})
	pass_action = {colors = {0 = {load_action = .CLEAR}}}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type == .KEY_DOWN && e.key_code == .SPACE { preset = (preset + 1) % 4 }
}

frame :: proc "c" () {
	context = rt_ctx
	params := PRESETS[preset]
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
		init_cb = init, frame_cb = frame, event_cb = event, cleanup_cb = cleanup,
		width = W, height = H, window_title = "GP13 — Color Grading (SPACE cycles presets)",
		logger = {func = slog.func},
	})
}
