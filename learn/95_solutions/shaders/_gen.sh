#!/bin/zsh
# One-shot generator for the shader post-FX lesson solutions.
# Each solution shares identical render-to-texture plumbing; only the post
# fragment shader, the uniform struct, and a few per-frame values differ.
# This script writes each solution's main.odin + build.sh.
#
# Run once from this directory:  zsh _gen.sh
set -e
cd "$(dirname "$0")"

emit_build() {
	local dir="$1" name="$2"
	cat > "$dir/build.sh" <<EOF
#!/bin/zsh
set -e
cd "\$(dirname "\$0")"
# macOS keyboard-focus fix lives in learn/run_graphics.sh.
source "../../../run_graphics.sh"
run_graphics "$name" "../../../../sauce/sokol"
EOF
}

# args: dir pkg title params_fields post_fs frame_extra event_block top_comment
emit_main() {
	local dir="$1" pkg="$2" title="$3" params="$4" postfs="$5" frame_extra="$6" event_block="$7" comment="$8"
	mkdir -p "$dir"
	cat > "$dir/main.odin" <<EOF
/*
$comment
*/

package $pkg

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

// SCENE shader: draws the game into the offscreen texture. Plain pass-through.
SCENE_VS :: \`
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float4 color [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float4 color; };
vertex vs_out _main(vs_in in [[stage_in]]) { vs_out o; o.position=float4(in.position,0,1); o.color=in.color; return o; }
\`
SCENE_FS :: \`
#include <metal_stdlib>
using namespace metal;
struct fs_in { float4 color; };
fragment float4 _main(fs_in in [[stage_in]]) { return in.color; }
\`

// POST vertex shader: fullscreen quad, passes uv through.
POST_VS :: \`
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float2 uv; };
vertex vs_out _main(vs_in in [[stage_in]]) { vs_out o; o.position=float4(in.position,0,1); o.uv=in.uv; return o; }
\`

// POST fragment shader: THE EFFECT. Edit this to change the look.
POST_FS :: \`
$postfs
\`

Post_Params :: struct #align(16) {
$params
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
$event_block
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
$frame_extra

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
		width = W, height = H, window_title = "$title", logger = { func = slog.func } })
}
EOF
}

# ============================ S01 DARKNESS / TORCH ============================
emit_main "s01_darkness" "s01_darkness" "S01 — Darkness / Torch (move mouse)" \
'	time:  f32,      // offset 0
	_pad0: f32,      // offset 4 (alignment pad: MSL float2 starts at offset 8)
	mouse: [2]f32,   // offset 8: torch position in uv (0..1)' \
'#include <metal_stdlib>
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
}' \
'	// mouse pixels -> uv (0..1) using the LIVE framebuffer size so it is
	// correct on Retina/high-DPI. No Y flip: the scene was rendered flipped,
	// so the texture uv.y already lines up with sokols top-down mouse_y.
	fw := sapp.widthf(); fh := sapp.heightf()
	params.mouse = { mouse_x / fw, mouse_y / fh }' \
'' \
'S01 — Darkness / Torch
======================
Only the POST fragment shader changed from s00. The scene is identical.
This is "fog of war" / horror darkness: everything is dim except a circle
of light around the mouse (your torch). Two ideas you reuse forever:
  - smoothstep(a, b, x): a soft 0..1 ramp. Here it makes the light edge soft.
  - keep an ambient floor so the dark area is not pure black (reads better).
Move the mouse. Change the 0.45/0.05 radius. Change ambient. Add flicker.'

# ============================ S02 FOG ========================================
emit_main "s02_fog" "s02_fog" "S02 — Animated Fog" \
'	time: f32,
	_pad: [3]f32,' \
'#include <metal_stdlib>
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
}' \
'' \
'' \
'S02 — Animated Fog
==================
Same plumbing as s00; only the shader differs. Fog = blend the scene toward
a grey color by a NOISE value that scrolls over time.
Concepts you keep:
  - hash/noise/fbm: how you make organic randomness on the GPU with no texture.
  - mix(a, b, t): linear blend. Fog is just mixing scene -> fog_color by density.
  - bias density by uv.y to get heavier ground fog.
Try: change the 3.0 scale (fog size), the scroll speed, fog_color, the 0.8.'

# ============================ S03 2D LIGHTS ==================================
emit_main "s03_lights" "s03_lights" "S03 — Multiple 2D Lights" \
'	time: f32,          // offset 0
	_pad: [3]f32,       // offset 4..15 (MSL float4 array starts at offset 16)
	lights: [4][4]f32,  // offset 16: per light: x, y (uv), radius, intensity' \
'#include <metal_stdlib>
using namespace metal;
struct Params { float time; float _pad[3]; float4 lights[4]; };
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    float4 col = scene.sample(smp, uv);
    float ambient = 0.10;
    float lit = ambient;
    // accumulate contribution of each light (classic 2D lighting accumulation)
    for (int i=0;i<4;i++){
        float2 lp = p.lights[i].xy;
        float radius = p.lights[i].z;
        float intensity = p.lights[i].w;
        float2 d = uv - lp; d.x *= 960.0/540.0;
        float falloff = 1.0 - smoothstep(0.0, radius, length(d));
        lit += falloff * intensity;
    }
    lit = clamp(lit, 0.0, 1.4);
    col.rgb *= lit;
    return col;
}' \
'	// three moving colored-ish lights orbiting; packed as x,y,radius,intensity
	tt := params.time
	params.lights[0] = { 0.5 + 0.30*math.cos(tt*0.7), 0.5 + 0.30*math.sin(tt*0.7), 0.35, 0.9 }
	params.lights[1] = { 0.3 + 0.15*math.sin(tt*1.1), 0.6, 0.25, 0.7 }
	params.lights[2] = { 0.75, 0.4 + 0.2*math.cos(tt*0.9), 0.30, 0.8 }
	// mouse pixels -> uv via LIVE framebuffer size (Retina-safe), no Y flip
	fw := sapp.widthf(); fh := sapp.heightf()
	params.lights[3] = { mouse_x / fw, mouse_y / fh, 0.28, 1.0 }' \
'' \
'S03 — Multiple 2D Lights
========================
Extends s01 from one light to many. We pass an ARRAY of lights as uniforms
and the shader loops, adding each light contribution to a brightness value
(ambient + sum of falloffs). This is exactly how simple 2D light systems work.
Light 4 follows your mouse. Concepts:
  - uniform arrays (float4 lights[4]) pack data: xy=pos, z=radius, w=intensity.
  - accumulate light, then multiply the scene by it. Clamp so it does not blow out.
Try: add a 5th light, give lights colors (multiply tint per light), pulse intensity.'

# ============================ S04 CRT / TV ===================================
emit_main "s04_crt" "s04_crt" "S04 — CRT / Old TV" \
'	time: f32,
	_pad: [3]f32,' \
'#include <metal_stdlib>
using namespace metal;
struct Params { float time; float pad0,pad1,pad2; };
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    // 1. screen CURVATURE: bend uv outward so it bulges like a CRT tube
    float2 c = uv*2.0 - 1.0;            // -1..1
    c *= 1.0 + 0.12*dot(c,c);           // barrel distortion
    float2 cuv = c*0.5 + 0.5;           // back to 0..1
    // outside the curved screen = black bezel
    if (cuv.x<0.0||cuv.x>1.0||cuv.y<0.0||cuv.y>1.0) return float4(0,0,0,1);

    // 2. CHROMATIC ABERRATION: sample R/G/B at slightly offset positions
    float off = 0.0015;
    float r = scene.sample(smp, cuv + float2(off,0)).r;
    float g = scene.sample(smp, cuv).g;
    float b = scene.sample(smp, cuv - float2(off,0)).b;
    float3 col = float3(r,g,b);

    // 3. SCANLINES: darken every other row
    float scan = 0.85 + 0.15*sin(cuv.y * 540.0 * 3.14159);
    col *= scan;

    // 4. ROLLING flicker + faint vignette
    col *= 0.95 + 0.05*sin(p.time*8.0 + cuv.y*4.0);
    float2 v = cuv-0.5; col *= smoothstep(0.9, 0.4, length(v));
    return float4(col,1.0);
}' \
'' \
'' \
'S04 — CRT / Old TV
==================
Same plumbing; the shader fakes an old tube TV by stacking small tricks:
  1. barrel distortion: bend the uv so the picture bulges.
  2. chromatic aberration: sample R/G/B at tiny offsets -> color fringing.
  3. scanlines: a sine over uv.y darkens alternate rows.
  4. flicker + vignette for mood.
Each is a few lines. Real "looks" are usually many cheap tricks layered.
Try: strengthen 0.12 curvature, change off (fringing), the 540.0 scanline count.'

# ============================ S05 COLOR GRADING ==============================
emit_main "s05_grade" "s05_grade" "S05 — Color Grading / Mood" \
'	time: f32,
	_pad: [3]f32,' \
'#include <metal_stdlib>
using namespace metal;
struct Params { float time; float pad0,pad1,pad2; };
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    float3 col = scene.sample(smp, uv).rgb;
    // CONTRAST around mid-grey
    col = (col - 0.5) * 1.15 + 0.5;
    // SATURATION: mix toward greyscale luminance
    float l = dot(col, float3(0.299,0.587,0.114));
    float sat = 1.25;                              // >1 more saturated
    col = mix(float3(l), col, sat);
    // tint shadows cool, highlights warm (split toning -> cinematic mood)
    float3 shadow_tint = float3(0.05,0.08,0.15);
    float3 high_tint   = float3(0.15,0.10,0.02);
    col += mix(shadow_tint, high_tint, l);
    // slowly drift the whole mood with time so you SEE grading at work
    float warm = 0.5 + 0.5*sin(p.time*0.5);
    col *= mix(float3(0.9,0.95,1.1), float3(1.1,1.0,0.85), warm);
    return float4(clamp(col,0.0,1.0),1.0);
}' \
'' \
'' \
'S05 — Color Grading / Mood
==========================
No new geometry — grading just remaps colors. The same scene can feel warm,
cold, cinematic, or sickly purely from these maths:
  - contrast: push values away from 0.5.
  - saturation: mix between greyscale luminance and full color.
  - split toning: tint dark areas one color, bright areas another.
This is what gives games a consistent "look". Try your own palette: set
shadow_tint/high_tint to your game mood, change contrast and sat.'

# ============================ S06 BLOOM ======================================
# Bloom needs a brightness extraction + blur + composite. To keep it ONE pass
# and readable, we approximate: sample neighborhood, keep only bright parts,
# blur by averaging offset samples, add back. (Production bloom uses extra
# passes; this teaches the idea cheaply.)
emit_main "s06_bloom" "s06_bloom" "S06 — Bloom / Glow" \
'	time: f32,
	_pad: [3]f32,' \
'#include <metal_stdlib>
using namespace metal;
struct Params { float time; float pad0,pad1,pad2; };
// keep only the bright part of a color (threshold)
float3 bright(float3 c){ float l=dot(c,float3(0.299,0.587,0.114)); return c*smoothstep(0.6,0.9,l); }
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    float3 base = scene.sample(smp, uv).rgb;
    // blur the BRIGHT parts by averaging a ring of offset samples.
    float3 glow = float3(0.0);
    float texel = 1.0/540.0;
    for (int i=-3;i<=3;i++){
        for (int j=-3;j<=3;j++){
            float2 o = float2(float(i),float(j))*texel*2.0;
            glow += bright(scene.sample(smp, uv+o).rgb);
        }
    }
    glow /= 49.0;
    // add the blurred brightness back on top -> things glow
    float3 col = base + glow*1.6;
    return float4(col,1.0);
}' \
'' \
'' \
'S06 — Bloom / Glow
==================
Bloom = bright things bleed light into neighbors. The recipe:
  1. BRIGHT PASS: keep only pixels brighter than a threshold.
  2. BLUR: average nearby samples so the brightness spreads.
  3. COMPOSITE: add the blurred glow back on top of the original.
This version does all three in one shader with a small sample loop (cheap,
slightly soft). Production engines do the blur in separate downsampled passes
for speed/quality — same idea, more passes. (See learn/50_advanced.)
Try: change the 0.6/0.9 threshold, the loop range (blur size), the 1.6 strength.'

# build scripts for all
for d in s01_darkness s02_fog s03_lights s04_crt s05_grade s06_bloom; do
	name="$d"
	emit_build "$d" "$name"
done

echo "generated."
