/*
GP01 — Matrices
===============
A matrix is just a small grid of numbers that transforms a point:
    new_point = matrix * old_point

This file builds the four matrices you actually use — identity, translate,
scale, rotate — by hand, then draws the SAME unit square through each so you
can SEE what every matrix does. Finally it shows that order matters:
T*R*S  (scale, then rotate, then translate — read right to left) looks
different from S*R*T.

Read these blocks:
  - `mat_*` procs       : how each matrix is built (the actual numbers).
  - `apply`             : matrix * point.
  - `draw_square`       : transform 4 local corners, draw the quad.
  - `frame`             : builds T, R, S and the two combined orders.

Odin's `matrix[3,3]f32` supports `*` for matrix*matrix and matrix*vector, so we
let the language do the multiply. We use 3x3 (not 2x2) so the extra row can
carry TRANSLATION — that is why points get a trailing 1.

Controls: none. Just look. (Edit the code per the LESSON exercises.)
*/

package gp01_matrices

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

// --- the four matrices, built by hand (column-major, as Odin stores them) ---

mat_identity :: proc() -> Mat3 {
	return Mat3{
		1, 0, 0,
		0, 1, 0,
		0, 0, 1,
	}
}

// translate: the last column holds the offset (needs the point's trailing 1)
mat_translate :: proc(tx, ty: f32) -> Mat3 {
	return Mat3{
		1, 0, tx,
		0, 1, ty,
		0, 0, 1,
	}
}

// scale: the diagonal scales each axis
mat_scale :: proc(sx, sy: f32) -> Mat3 {
	return Mat3{
		sx, 0,  0,
		0,  sy, 0,
		0,  0,  1,
	}
}

// rotate: classic 2D rotation around the origin
mat_rotate :: proc(angle: f32) -> Mat3 {
	c := math.cos(angle)
	s := math.sin(angle)
	return Mat3{
		c, -s, 0,
		s,  c, 0,
		0,  0, 1,
	}
}

// matrix * point. The trailing 1 turns translation on.
apply :: proc(m: Mat3, p: [2]f32) -> [2]f32 {
	v := m * [3]f32{p.x, p.y, 1}
	return v.xy
}

rt_ctx: runtime.Context
pass_action: sg.Pass_Action

// a unit square centered on its own origin (local space)
LOCAL := [4][2]f32{{-0.5, -0.5}, {0.5, -0.5}, {0.5, 0.5}, {-0.5, 0.5}}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.05, g = 0.06, b = 0.10, a = 1}}},
	}
}

// transform the 4 local corners by M (after scaling local->pixels) and draw
draw_square :: proc(m: Mat3, px, py, size: f32, r, g, b: f32) {
	sgl.begin_quads()
	sgl.c3f(r, g, b)
	for c in LOCAL {
		// matrix acts in local units; then we place at (px,py) in pixels
		t := apply(m, c)
		sgl.v2f(px + t.x * size, py + t.y * size)
	}
	sgl.end()
}

frame :: proc "c" () {
	context = rt_ctx
	t := f32(sapp.frame_count()) * 0.016

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// build the four basic matrices
	I := mat_identity()
	T := mat_translate(0.6, 0) // shift right in local units
	S := mat_scale(1.6, 1.6)
	R := mat_rotate(t)

	S2 := f32(70) // pixel size of one local unit

	// row of single transforms
	draw_square(I, 150, 140, S2, 0.6, 0.6, 0.7) // identity: unchanged
	draw_square(T, 400, 140, S2, 0.9, 0.7, 0.3) // translate: shifted
	draw_square(S, 650, 140, S2, 0.4, 0.8, 0.6) // scale: bigger
	draw_square(R, 850, 140, S2, 0.8, 0.5, 0.9) // rotate: spins

	// combined: ORDER MATTERS. Read right-to-left.
	TRS := T * R * S // scale, then rotate, then translate
	SRT := S * R * T // translate, then rotate, then scale
	draw_square(TRS, 320, 400, S2, 1.0, 0.5, 0.4) // spins in place, offset
	draw_square(SRT, 640, 400, S2, 0.4, 0.6, 1.0) // orbits — different!

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
		window_title = "GP01 — Matrices",
		logger       = {func = slog.func},
	})
}
