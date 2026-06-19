/*
GP08 — PBR (illustrative 2D demo)
=================================
Full PBR is a 3D technique. This DEMO lights a procedural "ball" (a shaded
disc) in the fragment shader to make the two ideas that matter MOST concrete:
  - ROUGHNESS widens/dulls the specular highlight.
  - FRESNEL (gp07) brightens the rim — it is the 'F' term inside the PBR BRDF.

It is NOT full Cook-Torrance. It is Lambert diffuse + a roughness-controlled
specular blob + a Fresnel rim, so you FEEL roughness change the highlight.

Read: FS — diffuse (dot(N,L)), specular (pow(dot(N,H), shininess)) where
shininess derives from roughness, and the Fresnel rim.

Controls:  Z/X = rougher/smoother   (roughness pulses too if untouched)
*/

package gp08_pbr

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
struct Params { float roughness; float aspect; float lightx; float lighty; };
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float2 c = (in.uv - 0.5) * float2(p.aspect, 1.0) * 2.4;
    float r2 = dot(c, c);
    if (r2 > 1.0) return float4(0.03, 0.04, 0.07, 1.0);   // background
    // reconstruct a sphere normal from the disc position
    float3 N = normalize(float3(c, sqrt(max(0.0, 1.0 - r2))));
    float3 L = normalize(float3(p.lightx, p.lighty, 0.8));
    float3 V = float3(0.0, 0.0, 1.0);
    float3 Hh = normalize(L + V);

    float3 albedo = float3(0.85, 0.35, 0.25);
    float  diff   = max(dot(N, L), 0.0);

    // roughness -> highlight width. Smooth = tiny sharp spec, rough = wide dull.
    float shininess = mix(256.0, 4.0, p.roughness);
    float spec = pow(max(dot(N, Hh), 0.0), shininess) * (1.0 - p.roughness * 0.7);

    // Fresnel rim (the BRDF 'F' term)
    float fres = pow(1.0 - max(dot(N, V), 0.0), 4.0) * 0.6;

    float3 col = albedo * (0.1 + diff) + spec + fres * float3(0.4, 0.7, 1.0);
    return float4(col, 1.0);
}
`

Params :: struct #align (16) {
	roughness: f32,
	aspect:    f32,
	lightx:    f32,
	lighty:    f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context
roughness: f32 = 0.3
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
	if keys[.Z] { roughness = min(1, roughness + dt) }
	if keys[.X] { roughness = max(0, roughness - dt) }
	t := f32(sapp.frame_count()) * 0.016
	params := Params{
		roughness = roughness,
		aspect    = f32(W) / f32(H),
		lightx    = math.cos(t) * 0.7,
		lighty    = math.sin(t) * 0.7,
	}
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
		width = W, height = H, window_title = "GP08 — PBR demo (Z/X roughness)",
		logger = {func = slog.func},
	})
}
