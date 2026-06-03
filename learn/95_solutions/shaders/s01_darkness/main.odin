/*
S01 — Darkness / Torch
======================
Only the POST fragment shader changed from s00. The scene is identical.
This is "fog of war" / horror darkness: everything is dim except a circle
of light around the mouse (your torch). Two ideas you reuse forever:
  - smoothstep(a, b, x): a soft 0..1 ramp. Here it makes the light edge soft.
  - keep an ambient floor so the dark area is not pure black (reads better).
Move the mouse. Change the 0.45/0.05 radius. Change ambient. Add flicker.
*/

package s01_darkness

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
struct Params { float time; float _pad0; float2 mouse; };
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    float4 col = scene.sample(smp, uv);
    // distance from the mouse "torch", aspect-corrected so the light is round
    float2 d = uv - p.mouse;
    d.x *= 960.0/540.0;
    float dist = length(d);
    // bright in a radius around the torch, fading to near-black outside.
    float light = smoothstep(0.45, 0.05, dist);   // 1 near torch -> 0 far
    float ambient = 0.08;                          // never fully black
    col.rgb *= max(light, ambient);
    // subtle warm tint inside the light, like a flame
    col.rgb += float3(0.18,0.10,0.0) * light * (0.8 + 0.2*sin(p.time*8.0));
    return col;
}
`

Post_Params :: struct #align(16) {
	time:  f32,      // offset 0
	_pad0: f32,      // offset 4 (alignment pad: MSL float2 starts at offset 8)
	mouse: [2]f32,   // offset 8: torch position in uv (0..1)
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
	// mouse pixels -> uv (0..1) using the LIVE framebuffer size so it is
	// correct on Retina/high-DPI. No Y flip: the scene was rendered flipped,
	// so the texture uv.y already lines up with sokol's top-down mouse_y.
	fw := sapp.widthf(); fh := sapp.heightf()
	params.mouse = { mouse_x / fw, mouse_y / fh }

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
		width = W, height = H, window_title = "S01 — Darkness / Torch (move mouse)", logger = { func = slog.func } })
}
