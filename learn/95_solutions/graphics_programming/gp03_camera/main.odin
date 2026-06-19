/*
GP03 — Camera (View Matrix)
===========================
A camera is another object with a transform. To draw the world FROM that
camera, we move the whole world the OPPOSITE way: the view matrix is the
INVERSE of the camera's own model matrix.

    view = inverse(camera_model)

Each object is then drawn through:  view * model * local_point.
This handles camera position, ZOOM, and ROTATION in one operation — which is
why we use inverse instead of just subtracting the camera position.

Read these blocks:
  - `view_matrix`       : inverse of the camera's model.
  - `draw_object`       : view * model * corners.
  - `frame`             : arrow keys move/zoom/rotate the camera; HUD ignores it.

Controls:
  Arrows/WASD : move camera   Q/E : rotate camera   Z/X : zoom out/in
*/

package gp03_camera

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"
import "core:math/linalg"

W :: 960
H :: 540

Mat3 :: matrix[3, 3]f32

Camera :: struct {
	position: [2]f32,
	zoom:     f32,
	rotation: f32,
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

// view = inverse of the camera's own model matrix. We pivot the zoom/rotate
// about the screen center so the camera feels like it's looking at that point.
view_matrix :: proc(c: Camera) -> Mat3 {
	center := mat_translate({W / 2, H / 2})
	cam_model :=
		center *
		mat_rotate(c.rotation) *
		mat_scale({c.zoom, c.zoom}) *
		mat_translate({-c.position.x, -c.position.y})
	return linalg.inverse(cam_model)
}

apply :: proc(m: Mat3, p: [2]f32) -> [2]f32 {
	v := m * [3]f32{p.x, p.y, 1}
	return v.xy
}

cam: Camera
keys: #sparse [sapp.Keycode]bool
rt_ctx: runtime.Context
pass_action: sg.Pass_Action

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.05, g = 0.06, b = 0.10, a = 1}}},
	}
	cam = {position = {0, 0}, zoom = 1, rotation = 0}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .KEY_DOWN: keys[e.key_code] = true
	case .KEY_UP:   keys[e.key_code] = false
	}
}

// world-space box drawn through view (then sgl handles projection)
draw_box :: proc(view: Mat3, wx, wy, w, h: f32, r, g, b: f32) {
	corners := [4][2]f32{{wx, wy}, {wx + w, wy}, {wx + w, wy + h}, {wx, wy + h}}
	sgl.begin_quads()
	sgl.c3f(r, g, b)
	for c in corners {
		p := apply(view, c)
		sgl.v2f(p.x, p.y)
	}
	sgl.end()
}

// screen-space box: NO view matrix (HUD). Proves HUD ignores the camera.
draw_hud :: proc(x, y, w, h: f32, r, g, b: f32) {
	sgl.begin_quads()
	sgl.c3f(r, g, b)
	sgl.v2f(x, y); sgl.v2f(x + w, y); sgl.v2f(x + w, y + h); sgl.v2f(x, y + h)
	sgl.end()
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())

	speed := f32(300) * dt
	if keys[.LEFT]  || keys[.A] { cam.position.x -= speed }
	if keys[.RIGHT] || keys[.D] { cam.position.x += speed }
	if keys[.UP]    || keys[.W] { cam.position.y -= speed }
	if keys[.DOWN]  || keys[.S] { cam.position.y += speed }
	if keys[.Q] { cam.rotation -= 1.5 * dt }
	if keys[.E] { cam.rotation += 1.5 * dt }
	if keys[.Z] { cam.zoom = max(0.2, cam.zoom - 0.8 * dt) }
	if keys[.X] { cam.zoom += 0.8 * dt }

	view := view_matrix(cam)

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// world grid of boxes (world space, through the view matrix)
	for gy in 0 ..< 6 {
		for gx in 0 ..< 8 {
			wx := f32(gx) * 160
			wy := f32(gy) * 120
			draw_box(view, wx, wy, 90, 70, 0.3 + f32(gx) * 0.08, 0.6, 0.9 - f32(gy) * 0.1)
		}
	}

	// HUD: fixed top bar, drawn WITHOUT the view matrix — never scrolls/zooms.
	draw_hud(0, 0, W, 26, 0.12, 0.12, 0.18)
	draw_hud(12, 6, 120, 14, 0.9, 0.7, 0.3)

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
		window_title = "GP03 — Camera / View Matrix",
		logger       = {func = slog.func},
	})
}
