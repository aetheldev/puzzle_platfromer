/*
S02 — Animated Fog
==================
Same plumbing as s00; only the shader differs. Fog = blend the scene toward
a grey color by a NOISE value that scrolls over time.
Concepts you keep:
  - hash/noise/fbm: how you make organic randomness on the GPU with no texture.
  - mix(a, b, t): linear blend. Fog is just mixing scene -> fog_color by density.
  - bias density by uv.y to get heavier ground fog.
Try: change the 3.0 scale (fog size), the scroll speed, fog_color, the 0.8.
*/

package s02_fog

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

// SCENE shader: draws the game into the offscreen texture. Plain pass-through.
SCENE_VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float4 color [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float4 color; };
vertex vs_out _main(vs_in in [[stage_in]]) { vs_out o; o.position=float4(in.position,0,1); o.color=in.color; return o; }
`
SCENE_FS :: `
#include <metal_stdlib>
using namespace metal;
struct fs_in { float4 color; };
fragment float4 _main(fs_in in [[stage_in]]) { return in.color; }
`

// POST vertex shader: fullscreen quad, passes uv through.
POST_VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float2 uv; };
vertex vs_out _main(vs_in in [[stage_in]]) { vs_out o; o.position=float4(in.position,0,1); o.uv=in.uv; return o; }
`

// POST fragment shader: THE EFFECT. Edit this to change the look.
POST_FS :: `
#include <metal_stdlib>
using namespace metal;
struct Params { float time; float pad0,pad1,pad2; };
// cheap value-noise: hash + smooth interpolate. Good enough for drifting fog.
float hash(float2 p){ return fract(sin(dot(p,float2(127.1,311.7)))*43758.5453); }
float noise(float2 p){
    float2 i=floor(p), f=fract(p);
    float a=hash(i), b=hash(i+float2(1,0)), c=hash(i+float2(0,1)), d=hash(i+float2(1,1));
    float2 u=f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
// layer a few noise octaves = fluffier fog (fractal brownian motion)
float fbm(float2 p){ float v=0.0, amp=0.5; for(int i=0;i<4;i++){ v+=amp*noise(p); p*=2.0; amp*=0.5;} return v; }
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    float4 col = scene.sample(smp, uv);
    // sample drifting fog density. two scrolling layers for parallax depth.
    float2 q = uv * 3.0;
    float f = fbm(q + float2(p.time*0.06, p.time*0.02));
    f += 0.5 * fbm(q*2.0 - float2(p.time*0.03, 0.0));
    float density = clamp(f*0.5, 0.0, 1.0);
    // fog thicker toward the bottom of the screen (ground fog)
    density *= mix(0.3, 1.0, 1.0 - uv.y);
    float3 fog_color = float3(0.55,0.60,0.70);
    // blend scene toward fog color by density
    col.rgb = mix(col.rgb, fog_color, density*0.8);
    return col;
}
`

Post_Params :: struct #align(16) {
	time: f32,
	_pad: [3]f32,
}

scene_pip:  sg.Pipeline
post_pip:   sg.Pipeline
color_img:  sg.Image
smp:        sg.Sampler
attachments: sg.Attachments
scene_action: sg.Pass_Action
disp_action:  sg.Pass_Action
scene_vbuf: sg.Buffer
scene_ibuf: sg.Buffer
quad_vbuf:  sg.Buffer
MAX_VERTS :: 4096
scene_verts: [MAX_VERTS * 6]f32
scene_vcount: int
rt_ctx: runtime.Context
mouse_x, mouse_y: f32 = W/2, H/2

px_to_ndc_x :: proc(x: f32) -> f32 { return (x / W) * 2.0 - 1.0 }
px_to_ndc_y :: proc(y: f32) -> f32 { return 1.0 - (y / H) * 2.0 }

push_quad :: proc(x, y, w, h, r, g, b, a: f32) {
	x0 := px_to_ndc_x(x); y0 := px_to_ndc_y(y)
	x1 := px_to_ndc_x(x+w); y1 := px_to_ndc_y(y+h)
	base := scene_vcount * 6
	verts := [24]f32{ x0,y0,r,g,b,a, x1,y0,r,g,b,a, x1,y1,r,g,b,a, x0,y1,r,g,b,a }
	for v, i in verts { scene_verts[base+i] = v }
	scene_vcount += 4
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x
		mouse_y = e.mouse_y
	}

}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	color_img = sg.make_image({ render_target = true, width = W, height = H, pixel_format = .RGBA8, sample_count = 1 })
	smp = sg.make_sampler({ min_filter = .LINEAR, mag_filter = .LINEAR, wrap_u = .CLAMP_TO_EDGE, wrap_v = .CLAMP_TO_EDGE })
	attachments = sg.make_attachments({ colors = { 0 = { image = color_img } } })
	scene_action = { colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.06,g=0.07,b=0.10,a=1 } } } }
	disp_action  = { colors = { 0 = { load_action = .CLEAR } } }

	scene_vbuf = sg.make_buffer({ usage = .DYNAMIC, size = size_of(scene_verts) })
	max_quads :: MAX_VERTS / 4
	idx: [max_quads*6]u16
	for i in 0..<max_quads { b := u16(i*4); idx[i*6+0]=b+0; idx[i*6+1]=b+1; idx[i*6+2]=b+2; idx[i*6+3]=b+0; idx[i*6+4]=b+2; idx[i*6+5]=b+3 }
	scene_ibuf = sg.make_buffer({ type = .INDEXBUFFER, data = { ptr = raw_data(idx[:]), size = size_of(idx) } })

	scene_shd := sg.make_shader({ vertex_func = { source = SCENE_VS, entry = "_main" }, fragment_func = { source = SCENE_FS, entry = "_main" } })
	scene_pip = sg.make_pipeline({ shader = scene_shd, index_type = .UINT16, layout = { attrs = { 0 = { format = .FLOAT2 }, 1 = { format = .FLOAT4 } } }, colors = { 0 = { pixel_format = .RGBA8 } } })

	fq := [?]f32{ -1,-1,0,1, 1,-1,1,1, 1,1,1,0,  -1,-1,0,1, 1,1,1,0, -1,1,0,0 }
	quad_vbuf = sg.make_buffer({ data = { ptr = raw_data(fq[:]), size = size_of(fq) } })

	post_shd := sg.make_shader({
		vertex_func = { source = POST_VS, entry = "_main" },
		fragment_func = { source = POST_FS, entry = "_main" },
		uniform_blocks = { 0 = { stage = .FRAGMENT, size = u32(size_of(Post_Params)), msl_buffer_n = 0 } },
		images   = { 0 = { stage = .FRAGMENT, image_type = ._2D, sample_type = .FLOAT } },
		samplers = { 0 = { stage = .FRAGMENT, sampler_type = .FILTERING } },
		image_sampler_pairs = { 0 = { stage = .FRAGMENT, image_slot = 0, sampler_slot = 0 } },
	})
	post_pip = sg.make_pipeline({ shader = post_shd, layout = { attrs = { 0 = { format = .FLOAT2 }, 1 = { format = .FLOAT2 } } } })
}

draw_scene :: proc() {
	scene_vcount = 0
	t := f32(sapp.frame_count()) * 0.016
	push_quad(0, 0, W, H, 0.10, 0.12, 0.16, 1)
	for i in 0..<6 {
		fi := f32(i)
		x := 120 + fi*120 + math.sin(t + fi)*30
		y := 200 + math.cos(t*1.3 + fi)*80
		push_quad(x, y, 80, 80, 0.9, 0.4 + fi*0.08, 0.2, 1)
	}
	push_quad(W/2-40, H/2-40, 80, 80, 0.3, 0.8, 1.0, 1)
	sg.update_buffer(scene_vbuf, { ptr = raw_data(scene_verts[:]), size = size_of(scene_verts) })
	sg.apply_pipeline(scene_pip)
	sg.apply_bindings({ vertex_buffers = { 0 = scene_vbuf }, index_buffer = scene_ibuf })
	sg.draw(0, scene_vcount/4*6, 1)
}

frame :: proc "c" () {
	context = rt_ctx
	sg.begin_pass({ action = scene_action, attachments = attachments })
	draw_scene()
	sg.end_pass()

	params := Post_Params{}
	params.time = f32(sapp.frame_count()) * 0.016


	sg.begin_pass({ action = disp_action, swapchain = sglue.swapchain() })
	sg.apply_pipeline(post_pip)
	sg.apply_bindings({ vertex_buffers = { 0 = quad_vbuf }, images = { 0 = color_img }, samplers = { 0 = smp } })
	sg.apply_uniforms(0, { ptr = &params, size = size_of(Post_Params) })
	sg.draw(0, 6, 1)
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () { context = rt_ctx; sg.shutdown() }

main :: proc() {
	rt_ctx = context
	sapp.run({ init_cb = init, frame_cb = frame, event_cb = event, cleanup_cb = cleanup,
		width = W, height = H, window_title = "S02 — Animated Fog", logger = { func = slog.func } })
}
