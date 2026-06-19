/*
GP12 — SSAO (illustrative 2D demo)
==================================
Ambient occlusion = how much surrounding geometry blocks ambient light. Deep
corners darken; open areas stay bright. Real SSAO reads a DEPTH buffer + NORMALS
(a 3D technique). This demo fakes a depth/height map (raised boxes on a floor)
in the fragment shader, then does a simplified SSAO: for each pixel it samples
neighbors and darkens where neighbors are "higher" (closer) — the core idea
"compare neighbor depths, darken where blocked".

Read: FS — `height()` is the fake depth; the sample loop accumulates occlusion;
the result darkens ambient. You will see soft dark halos around the boxes.

Controls:  Z/X = smaller/bigger radius   C/V = less/more strength
*/

package gp12_ssao

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
struct Params { float radius; float strength; float aspect; float pad; };

// fake "depth": raised boxes (height 1) on a floor (height 0).
float height(float2 uv, float aspect) {
    float2 p = uv * float2(aspect, 1.0);
    float h = 0.0;
    float2 boxes[3] = { float2(0.3*aspect,0.35), float2(0.62*aspect,0.55), float2(0.45*aspect,0.72) };
    for (int i = 0; i < 3; i++) {
        float2 d = abs(p - boxes[i]);
        if (d.x < 0.12 && d.y < 0.12) h = 1.0;
    }
    return h;
}
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float h = height(in.uv, p.aspect);
    float3 albedo = (h > 0.5) ? float3(0.8, 0.6, 0.4) : float3(0.35, 0.4, 0.5);

    // SSAO: sample neighbors; if a neighbor is HIGHER than us, it occludes us.
    float ao = 0.0;
    float count = 0.0;
    int N = 8;
    for (int i = 0; i < N; i++) {
        float ang = float(i) / float(N) * 6.2831;
        float2 o = float2(cos(ang), sin(ang)) * p.radius;
        float nh = height(in.uv + o, p.aspect);
        if (nh > h + 0.01) ao += 1.0;     // neighbor blocks ambient
        count += 1.0;
    }
    ao = 1.0 - (ao / count) * p.strength;   // 1 = open, <1 = occluded

    float3 ambient = albedo * 0.6 * ao;     // darken ambient by occlusion
    float3 col = albedo * 0.4 + ambient;
    return float4(col, 1.0);
}
`

Params :: struct #align (16) {
	radius:   f32,
	strength: f32,
	aspect:   f32,
	_pad:     f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context
radius:   f32 = 0.03
strength: f32 = 1.0
keys: #sparse [sapp.Keycode]bool

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
	#partial switch e.type {
	case .KEY_DOWN: keys[e.key_code] = true
	case .KEY_UP:   keys[e.key_code] = false
	}
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	if keys[.Z] { radius = max(0.005, radius - dt * 0.05) }
	if keys[.X] { radius += dt * 0.05 }
	if keys[.C] { strength = max(0, strength - dt) }
	if keys[.V] { strength = min(2, strength + dt) }
	params := Params{radius = radius, strength = strength, aspect = f32(W) / f32(H)}
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
		width = W, height = H, window_title = "GP12 — SSAO demo (Z/X radius, C/V strength)",
		logger = {func = slog.func},
	})
}
