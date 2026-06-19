/*
GP10 — Bloom, Done Properly (single-shader demo)
================================================
Bloom = bright things bleed light into neighbors. Three stages:
  1. BRIGHT-PASS : keep only pixels above a brightness threshold.
  2. BLUR        : average a grid of nearby samples.
  3. COMPOSITE   : final = scene + glow * strength.

Real engines do separable + downsampled blur passes for speed (see LESSON).
This demo does it in ONE fragment shader so the math is visible: it builds a
procedural "scene" (a few bright emissive discs on a dark floor), then runs the
three stages on it. No render-to-texture needed to learn the recipe.

Read: FS — `scene()`, `bright_pass()`, the blur loop, the composite.

Controls:  Z/X = lower/raise threshold   C/V = less/more strength
*/

package gp10_bloom_depth

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
struct Params { float threshold; float strength; float aspect; float time; };

// procedural HDR scene: bright emissive discs (color > 1) on a dark floor.
float3 scene(float2 uv, float aspect, float time) {
    float3 c = float3(0.04, 0.05, 0.08);
    float2 p = uv; p.x *= aspect;
    float2 lights[3] = { float2(0.35*aspect, 0.5), float2(0.65*aspect, 0.4), float2(0.5*aspect, 0.7) };
    float3 cols[3]   = { float3(4.0,1.5,0.6), float3(0.6,3.0,4.0), float3(3.5,0.8,3.0) };
    for (int i = 0; i < 3; i++) {
        float d = length(p - lights[i]);
        if (d < 0.05) c += cols[i];                 // bright core (HDR)
        c += cols[i] * 0.02 / (d + 0.02);           // soft falloff
    }
    return c;
}
float3 bright_pass(float3 c, float thresh) {
    float b = max(c.r, max(c.g, c.b));
    float k = smoothstep(thresh, thresh + 0.3, b);
    return c * k;
}
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float3 base = scene(in.uv, p.aspect, p.time);

    // BLUR the bright-pass: average a grid of offset samples.
    float3 glow = float3(0.0);
    float texel = 1.0 / 540.0;
    int R = 3;
    float count = 0.0;
    for (int y = -R; y <= R; y++) {
        for (int x = -R; x <= R; x++) {
            float2 o = float2(float(x), float(y)) * texel * 2.0;
            glow += bright_pass(scene(in.uv + o, p.aspect, p.time), p.threshold);
            count += 1.0;
        }
    }
    glow /= count;

    // COMPOSITE: scene + glow * strength
    float3 col = base + glow * p.strength;
    col = col / (1.0 + col);   // simple tone map so HDR fits the screen (gp11)
    return float4(col, 1.0);
}
`

Params :: struct #align (16) {
	threshold: f32,
	strength:  f32,
	aspect:    f32,
	time:      f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context
threshold: f32 = 1.0
strength:  f32 = 2.5
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
	if keys[.Z] { threshold = max(0, threshold - dt) }
	if keys[.X] { threshold += dt }
	if keys[.C] { strength = max(0, strength - dt * 2) }
	if keys[.V] { strength += dt * 2 }
	params := Params{
		threshold = threshold, strength = strength,
		aspect = f32(W) / f32(H), time = f32(sapp.frame_count()) * 0.016,
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
		width = W, height = H, window_title = "GP10 — Bloom (Z/X threshold, C/V strength)",
		logger = {func = slog.func},
	})
}
