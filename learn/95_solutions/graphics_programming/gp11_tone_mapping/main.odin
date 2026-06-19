/*
GP11 — Tone Mapping
===================
The GPU lights in HDR (values > 1.0) but the screen shows 0..1. Tone mapping
squeezes HDR into displayable range without ugly white blowout.

This demo builds a procedural HDR gradient + bright discs, then maps it with:
  - CLAMP    (bad: bright areas flatten to white)
  - REINHARD : c / (1 + c)
  - ACES     : filmic curve most games use
Then applies gamma (linear -> sRGB).

Read: FS — exposure, the three operators, the gamma line. Order matters:
light -> (bloom) -> tone map -> gamma.

Controls:  SPACE = cycle clamp/Reinhard/ACES   Z/X = exposure down/up
*/

package gp11_tone_mapping

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
struct Params { float mode; float exposure; float aspect; float pad; };

float3 aces(float3 x) {
    float a=2.51, b=0.03, c=2.43, d=0.59, e=0.14;
    return clamp((x*(a*x+b)) / (x*(c*x+d)+e), 0.0, 1.0);
}
float3 hdr_scene(float2 uv, float aspect) {
    // a gradient that ramps WELL past 1.0 on the right, plus two bright discs
    float3 c = float3(uv.x * 6.0) * float3(1.0, 0.8, 0.6);
    float2 p = uv; p.x *= aspect;
    c += float3(8.0, 3.0, 1.0) * 0.05 / (length(p - float2(0.3*aspect, 0.4)) + 0.03);
    c += float3(1.0, 4.0, 8.0) * 0.05 / (length(p - float2(0.7*aspect, 0.65)) + 0.03);
    return c;
}
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float3 hdr = hdr_scene(in.uv, p.aspect) * p.exposure;
    float3 mapped;
    if (p.mode < 0.5)      mapped = clamp(hdr, 0.0, 1.0);   // CLAMP (blows out)
    else if (p.mode < 1.5) mapped = hdr / (1.0 + hdr);      // REINHARD
    else                   mapped = aces(hdr);              // ACES
    mapped = pow(mapped, float3(1.0/2.2));                  // gamma (linear->sRGB)
    return float4(mapped, 1.0);
}
`

Params :: struct #align (16) {
	mode:     f32,
	exposure: f32,
	aspect:   f32,
	_pad:     f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context
mode: f32 = 2 // start on ACES
exposure: f32 = 1.0
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
	case .KEY_DOWN:
		keys[e.key_code] = true
		if e.key_code == .SPACE { mode = f32(int(mode + 1) % 3) }
	case .KEY_UP: keys[e.key_code] = false
	}
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	if keys[.Z] { exposure = max(0.05, exposure - dt) }
	if keys[.X] { exposure += dt }
	params := Params{mode = mode, exposure = exposure, aspect = f32(W) / f32(H)}
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
		width = W, height = H, window_title = "GP11 — Tone Mapping (SPACE cycles, Z/X exposure)",
		logger = {func = slog.func},
	})
}
