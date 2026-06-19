/*
GP09 — Normal Mapping (illustrative 2D demo)
============================================
Lighting depends on the surface normal: brightness = max(dot(N, L), 0). A flat
quad has ONE normal everywhere, so it lights flatly. A normal map gives a
DIFFERENT normal per pixel so the flat surface looks bumpy.

This DEMO generates a procedural normal map (a grid of bumps) IN the fragment
shader and lights a flat quad with a moving light. Toggle the normal map on/off
to see flat vs bumpy from the SAME geometry.

Read: FS — `bump_normal()` builds a per-pixel normal; lighting is dot(N, L).
Note the pack/unpack idea (`*2-1`) is what a real normal TEXTURE stores.

Controls:  SPACE = toggle normal map on/off
*/

package gp09_normal_mapping

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
struct Params { float lightx; float lighty; float use_normal; float freq; };

// procedural normal map: a grid of rounded bumps. Returns a unit normal.
// (A real normal map reads this from a texture as rgb*2-1.)
float3 bump_normal(float2 uv, float freq) {
    float2 g = uv * freq;
    // height field = product of sines; slope -> normal
    float dx = cos(g.x * 6.2831) * sin(g.y * 6.2831);
    float dy = sin(g.x * 6.2831) * cos(g.y * 6.2831);
    float3 n = normalize(float3(-dx, -dy, 1.5));
    return n;
}
fragment float4 _main(fs_in in [[stage_in]], constant Params& p [[buffer(0)]]) {
    float3 N = (p.use_normal > 0.5) ? bump_normal(in.uv, p.freq)
                                    : float3(0.0, 0.0, 1.0);  // flat
    float3 L = normalize(float3(p.lightx, p.lighty, 0.7));
    float  d = max(dot(N, L), 0.0);
    float3 base = float3(0.6, 0.55, 0.5);
    float3 col = base * (0.15 + d);
    return float4(col, 1.0);
}
`

Params :: struct #align (16) {
	lightx:     f32,
	lighty:     f32,
	use_normal: f32,
	freq:       f32,
}

pip:  sg.Pipeline
vbuf: sg.Buffer
pass_action: sg.Pass_Action
rt_ctx: runtime.Context
use_normal := true

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
	if e.type == .KEY_DOWN && e.key_code == .SPACE { use_normal = !use_normal }
}

frame :: proc "c" () {
	context = rt_ctx
	t := f32(sapp.frame_count()) * 0.016
	params := Params{
		lightx     = math.cos(t) * 0.8,
		lighty     = math.sin(t) * 0.8,
		use_normal = use_normal ? 1 : 0,
		freq       = 8.0,
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
		width = W, height = H, window_title = "GP09 — Normal Mapping (SPACE toggles)",
		logger = {func = slog.func},
	})
}
