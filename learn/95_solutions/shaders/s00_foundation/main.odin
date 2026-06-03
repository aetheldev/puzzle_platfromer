/*
S00 — Post-Processing Foundation: Render To Texture + Fullscreen Quad
====================================================================
This is THE pattern behind almost every "screen" effect you admire — fog,
darkness/vignette, CRT/TV, color grading, bloom, underwater wobble. None of
them touch your game objects. They all do the same two-step trick:

  STEP 1 (offscreen pass): draw the whole game into a TEXTURE instead of the
          window. The texture is just an image the GPU can sample later.
  STEP 2 (display pass):   draw ONE rectangle that covers the whole window,
          and a fragment shader reads the texture pixel-by-pixel and decides
          the final color. That shader is where the effect lives.

Once you have this skeleton, "adding fog" = changing a few lines of the
fragment shader. That is why this foundation lesson matters most.

This file does the full thing with the SIMPLEST possible effect so the
plumbing is obvious: the post shader just darkens the edges (a vignette) and
adds a faint scanline so you can SEE the post pass is running.

We write the shaders in MSL (Metal Shading Language) directly, same as the
t09 lesson, because the bundled sokol-shdc version does not match these
bindings. Writing MSL by hand teaches you exactly what a shader is.

Controls: none. Just look.
*/

package s00_foundation

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

// ---------------------------------------------------------------------------
// SCENE SHADER — draws colored quads into the offscreen texture (step 1).
// Plain: position in, color in, color out. No effect here.
// ---------------------------------------------------------------------------
SCENE_VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float4 color [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float4 color; };
vertex vs_out _main(vs_in in [[stage_in]]) {
    vs_out o;
    o.position = float4(in.position, 0.0, 1.0);
    o.color = in.color;
    return o;
}
`
SCENE_FS :: `
#include <metal_stdlib>
using namespace metal;
struct fs_in { float4 color; };
fragment float4 _main(fs_in in [[stage_in]]) { return in.color; }
`

// ---------------------------------------------------------------------------
// POST SHADER — runs once over the whole screen (step 2).
// It samples the offscreen texture at this pixel's uv, then modifies it.
// THIS is the file you edit to make new effects.
// ---------------------------------------------------------------------------
POST_VS :: `
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
POST_FS :: `
#include <metal_stdlib>
using namespace metal;

// Uniforms uploaded from Odin each frame. Layout MUST match Post_Params.
struct Params { float time; float pad0, pad1, pad2; };

fragment float4 _main(float4 pos [[position]],
                      float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp           [[sampler(0)]],
                      constant Params& p    [[buffer(0)]])
{
    // 1. read the game's pixel at this screen position
    float4 col = scene.sample(smp, uv);

    // 2. VIGNETTE: darken toward the edges. distance from center 0..~0.7
    float2 center = uv - 0.5;
    float dist = length(center);
    float vignette = smoothstep(0.75, 0.30, dist); // 1 at center -> 0 at edge
    col.rgb *= vignette;

    // 3. faint moving scanline so you can confirm the post pass is alive
    float scan = 0.96 + 0.04 * sin(uv.y * 800.0 + p.time * 4.0);
    col.rgb *= scan;

    return col;
}
`

Post_Params :: struct #align(16) {
	time: f32,
	_pad: [3]f32,
}

// ---- GPU resources ----------------------------------------------------------
scene_pip:  sg.Pipeline        // pipeline for drawing the scene
post_pip:   sg.Pipeline        // pipeline for the fullscreen post pass
color_img:  sg.Image           // the offscreen texture the scene draws into
smp:        sg.Sampler         // how the post shader reads that texture
attachments: sg.Attachments    // ties color_img to the offscreen pass

scene_action: sg.Pass_Action
disp_action:  sg.Pass_Action

scene_vbuf: sg.Buffer
scene_ibuf: sg.Buffer
quad_vbuf:  sg.Buffer          // the single fullscreen quad

MAX_VERTS :: 4096
scene_verts: [MAX_VERTS * 6]f32 // x,y, r,g,b,a
scene_vcount: int

rt_ctx: runtime.Context

px_to_ndc_x :: proc(x: f32) -> f32 { return (x / W) * 2.0 - 1.0 }
px_to_ndc_y :: proc(y: f32) -> f32 { return 1.0 - (y / H) * 2.0 }

push_quad :: proc(x, y, w, h, r, g, b, a: f32) {
	x0 := px_to_ndc_x(x);     y0 := px_to_ndc_y(y)
	x1 := px_to_ndc_x(x + w); y1 := px_to_ndc_y(y + h)
	base := scene_vcount * 6
	verts := [24]f32{
		x0,y0, r,g,b,a,  x1,y0, r,g,b,a,
		x1,y1, r,g,b,a,  x0,y1, r,g,b,a,
	}
	for v, i in verts { scene_verts[base + i] = v }
	scene_vcount += 4
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })

	// --- the offscreen color texture (render_target = true is the key flag) ---
	color_img = sg.make_image({
		render_target = true,
		width = W, height = H,
		pixel_format = .RGBA8,
		sample_count = 1,
	})
	// how the post shader samples it: LINEAR = smooth, clamp at edges
	smp = sg.make_sampler({
		min_filter = .LINEAR, mag_filter = .LINEAR,
		wrap_u = .CLAMP_TO_EDGE, wrap_v = .CLAMP_TO_EDGE,
	})
	// attachments = "the offscreen pass draws into color_img"
	attachments = sg.make_attachments({
		colors = { 0 = { image = color_img } },
	})

	scene_action = { colors = { 0 = {
		load_action = .CLEAR, clear_value = { r=0.06, g=0.07, b=0.10, a=1 } } } }
	disp_action  = { colors = { 0 = { load_action = .CLEAR } } }

	// --- scene geometry buffers ---
	scene_vbuf = sg.make_buffer({ usage = .DYNAMIC, size = size_of(scene_verts) })
	max_quads :: MAX_VERTS / 4
	idx: [max_quads * 6]u16
	for i in 0..<max_quads {
		b := u16(i*4)
		idx[i*6+0]=b+0; idx[i*6+1]=b+1; idx[i*6+2]=b+2
		idx[i*6+3]=b+0; idx[i*6+4]=b+2; idx[i*6+5]=b+3
	}
	scene_ibuf = sg.make_buffer({ type = .INDEXBUFFER,
		data = { ptr = raw_data(idx[:]), size = size_of(idx) } })

	scene_shd := sg.make_shader({
		vertex_func   = { source = SCENE_VS, entry = "_main" },
		fragment_func = { source = SCENE_FS, entry = "_main" },
	})
	scene_pip = sg.make_pipeline({
		shader = scene_shd, index_type = .UINT16,
		layout = { attrs = { 0 = { format = .FLOAT2 }, 1 = { format = .FLOAT4 } } },
		colors = { 0 = { pixel_format = .RGBA8 } }, // match the offscreen target
	})

	// --- fullscreen quad: two triangles covering the whole NDC space ---
	// each vertex: x,y (NDC) + u,v (texture coords). v is flipped so the
	// image is not upside-down.
	fq := [?]f32{
		-1,-1, 0,1,   1,-1, 1,1,   1,1, 1,0,
		-1,-1, 0,1,   1, 1, 1,0,  -1,1, 0,0,
	}
	quad_vbuf = sg.make_buffer({ data = { ptr = raw_data(fq[:]), size = size_of(fq) } })

	post_shd := sg.make_shader({
		vertex_func   = { source = POST_VS, entry = "_main" },
		fragment_func = { source = POST_FS, entry = "_main" },
		uniform_blocks = { 0 = { stage = .FRAGMENT, size = u32(size_of(Post_Params)), msl_buffer_n = 0 } },
		images   = { 0 = { stage = .FRAGMENT, image_type = ._2D, sample_type = .FLOAT } },
		samplers = { 0 = { stage = .FRAGMENT, sampler_type = .FILTERING } },
		image_sampler_pairs = { 0 = { stage = .FRAGMENT, image_slot = 0, sampler_slot = 0 } },
	})
	post_pip = sg.make_pipeline({
		shader = post_shd,
		layout = { attrs = { 0 = { format = .FLOAT2 }, 1 = { format = .FLOAT2 } } },
	})
}

draw_scene :: proc() {
	scene_vcount = 0
	// a few moving shapes so there is something to post-process
	t := f32(sapp.frame_count()) * 0.016
	push_quad(0, 0, W, H, 0.10, 0.12, 0.16, 1) // background fill
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

	// ---- PASS 1: render the game into the offscreen texture ----
	sg.begin_pass({ action = scene_action, attachments = attachments })
	draw_scene()
	sg.end_pass()

	// ---- PASS 2: draw the texture to the window through the post shader ----
	params := Post_Params{ time = f32(sapp.frame_count()) * 0.016 }
	sg.begin_pass({ action = disp_action, swapchain = sglue.swapchain() })
	sg.apply_pipeline(post_pip)
	sg.apply_bindings({
		vertex_buffers = { 0 = quad_vbuf },
		images   = { 0 = color_img },
		samplers = { 0 = smp },
	})
	sg.apply_uniforms(0, { ptr = &params, size = size_of(Post_Params) })
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
		init_cb = init, frame_cb = frame, cleanup_cb = cleanup,
		width = W, height = H,
		window_title = "S00 — Post-Processing Foundation",
		logger = { func = slog.func },
	})
}
