/*
GP04 — Projection (tiny 2D demo of the divide-by-depth idea)
============================================================
The projection matrix maps view space into NDC (the -1..1 cube). Two kinds:
  - ORTHO: no perspective. Even spacing. (What 2D uses.)
  - PERSPECTIVE: far things shrink, via dividing x/y by depth w.

We have no real 3D pipeline here, so this DEMO fakes it: it lays out a grid of
points with a "depth" that increases with distance from a vanishing point,
then toggles between:
  - ortho:        x_screen = x                       (even grid)
  - perspective:  x_screen = x / depth               (crowds toward vanish pt)

That divide-by-depth is the whole reason 3D looks 3D.

Read: `project_point` (the ortho vs perspective branch).

Controls:  SPACE = toggle ortho / perspective
*/

package gp04_projection

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

perspective := true
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

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type == .KEY_DOWN && e.key_code == .SPACE {
		perspective = !perspective
	}
}

// gx,gy in -N..N grid units, gz is fake depth (>=1). Returns screen pixels.
project_point :: proc(gx, gy, gz: f32) -> [2]f32 {
	cx := f32(W) / 2
	cy := f32(H) / 2
	scale := f32(60)
	if perspective {
		// PERSPECTIVE: divide by depth -> far points crowd toward the center.
		return {cx + (gx / gz) * scale * 4, cy + (gy / gz) * scale * 4}
	}
	// ORTHO: no depth divide -> even spacing.
	return {cx + gx * scale, cy + gy * scale}
}

draw_dot :: proc(p: [2]f32, s: f32, r, g, b: f32) {
	sgl.begin_quads()
	sgl.c3f(r, g, b)
	sgl.v2f(p.x - s, p.y - s); sgl.v2f(p.x + s, p.y - s)
	sgl.v2f(p.x + s, p.y + s); sgl.v2f(p.x - s, p.y + s)
	sgl.end()
}

frame :: proc "c" () {
	context = rt_ctx

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// a grid receding into the distance: depth grows with row index
	N :: 7
	for row in 0 ..< N {
		depth := f32(row) + 1.0 // 1..N  (closer..farther)
		for col in -N ..= N {
			gx := f32(col)
			gy := f32(2) // a floor plane, constant height
			p := project_point(gx, gy * depth, depth)
			b := 1.0 - f32(row) / f32(N)
			draw_dot(p, 4, 0.4, 0.7, b)
		}
	}

	// indicator: green = perspective, red = ortho
	if perspective { draw_dot({30, 30}, 12, 0.3, 0.9, 0.4) }
	else           { draw_dot({30, 30}, 12, 0.9, 0.4, 0.3) }

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
		event_cb     = event,
		cleanup_cb   = cleanup,
		width        = W,
		height       = H,
		window_title = "GP04 — Projection (SPACE toggles ortho/perspective)",
		logger       = {func = slog.func},
	})
}
