/*
GP02 — Transform (Model Matrix)
===============================
A game object stores a Transform (position, rotation, scale). Each frame we
turn it into ONE model matrix that maps the object's LOCAL space into WORLD
space:

    model = translate(position) * rotate(rotation) * scale(scale)

Order matters (gp01): scale, then rotate, then translate (read right to left),
so the object scales/rotates around its own pivot, THEN gets placed in the
world.

Read these blocks:
  - `Transform`         : the per-object data.
  - `model_matrix`      : T * R * S in one place.
  - `draw_object`       : transform the 4 local corners by the model matrix.
  - `frame`             : many objects, SAME draw code, different transforms.

Controls: none. The objects animate so you see each spin in place.
*/

package gp02_transform

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

Mat3 :: matrix[3, 3]f32

Transform :: struct {
	position: [2]f32, // world pixels
	rotation: f32,    // radians
	scale:    [2]f32, // multiplier on the local unit square
}

mat_translate :: proc(t: [2]f32) -> Mat3 {
	return Mat3{1, 0, t.x, 0, 1, t.y, 0, 0, 1}
}
mat_scale :: proc(s: [2]f32) -> Mat3 {
	return Mat3{s.x, 0, 0, 0, s.y, 0, 0, 0, 1}
}
mat_rotate :: proc(a: f32) -> Mat3 {
	c := math.cos(a); s := math.sin(a)
	return Mat3{c, -s, 0, s, c, 0, 0, 0, 1}
}

// THE model matrix: scale, then rotate, then translate.
model_matrix :: proc(tr: Transform) -> Mat3 {
	return mat_translate(tr.position) * mat_rotate(tr.rotation) * mat_scale(tr.scale)
}

apply :: proc(m: Mat3, p: [2]f32) -> [2]f32 {
	v := m * [3]f32{p.x, p.y, 1}
	return v.xy
}

// a 60px unit square centered on its own origin (local space)
UNIT :: f32(60)
LOCAL := [4][2]f32{{-0.5, -0.5}, {0.5, -0.5}, {0.5, 0.5}, {-0.5, 0.5}}

rt_ctx: runtime.Context
pass_action: sg.Pass_Action

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.05, g = 0.06, b = 0.10, a = 1}}},
	}
}

// SAME draw code for every object: build model matrix, transform local corners.
draw_object :: proc(tr: Transform, r, g, b: f32) {
	m := model_matrix(tr)
	sgl.begin_quads()
	sgl.c3f(r, g, b)
	for c in LOCAL {
		p := apply(m, {c.x * UNIT, c.y * UNIT})
		sgl.v2f(p.x, p.y)
	}
	sgl.end()
}

frame :: proc "c" () {
	context = rt_ctx
	t := f32(sapp.frame_count()) * 0.016

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	objects := [4]Transform{
		{position = {200, 200}, rotation = t,        scale = {1, 1}},
		{position = {480, 200}, rotation = -t * 1.5,  scale = {1.5 + math.sin(t), 1}},
		{position = {760, 200}, rotation = 0,         scale = {2, 2}},
		{position = {480, 400}, rotation = t * 0.5,   scale = {1.2, 1.2}},
	}
	cols := [4][3]f32{{0.9, 0.6, 0.3}, {0.4, 0.8, 0.6}, {0.5, 0.6, 1.0}, {0.9, 0.5, 0.8}}
	for tr, i in objects {
		draw_object(tr, cols[i].r, cols[i].g, cols[i].b)
	}

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	sgl.shutdown()
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run({
		init_cb      = init,
		frame_cb     = frame,
		cleanup_cb   = cleanup,
		width        = W,
		height       = H,
		window_title = "GP02 — Transform / Model Matrix",
		logger       = {func = slog.func},
	})
}
