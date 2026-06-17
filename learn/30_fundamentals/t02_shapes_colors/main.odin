package t02_shapes_colors

import sapp "../../../sauce/sokol/app"
import sg "../../../sauce/sokol/gfx"
import sgl "../../../sauce/sokol/gl"
import sglue "../../../sauce/sokol/glue"
import slog "../../../sauce/sokol/log"
import "base:runtime"
import "core:math"


W :: 960
H :: 540

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	// sokol_gl must be set up after sokol_gfx
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.1, g = 0.1, b = 0.15, a = 1}}},
	}
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(x, y, r, g, b, 255)
	sgl.v2f_c4b(x + w, y, r, g, b, 255)
	sgl.v2f_c4b(x + w, y + h, r, g, b, 255)
	sgl.v2f_c4b(x, y + h, r, g, b, 255)
	sgl.end()
}

draw_line :: proc(x0, y0, x1, y1: f32, r, g, b: u8) {
	sgl.begin_lines()
	sgl.v2f_c4b(x0, y0, r, g, b, 255)
	sgl.v2f_c4b(x1, y1, r, g, b, 255)
	sgl.end()
}

frame :: proc "c" () {
	context = rt_ctx

	// Set up a 2D projection that maps pixels: (0,0) top-left, (W,H) bottom-right.
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1) // left, right, bottom, top, near, far

	draw_rect(50, 50, 200, 120, 220, 60, 60)

	t := f32(sapp.frame_count()) * 0.1
	slide_x := 300 + 100 * math.sin(t)
	draw_rect(slide_x, 200, 100, 100, 60, 200, 100)

	bx, by, bw, bh: f32 = 500, 50, 150, 80
	draw_line(bx, by, bx + bw, by, 220, 60, 60)
	draw_line(bx + bw, by, bx + bw, by + bh, 220, 60, 60)
	draw_line(bx + bw, by + bh, bx, by + bh, 220, 60, 60)
	draw_line(bx, by + bh, bx, by, 220, 60, 60)


	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw() // flush sokol_gl draw calls
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
	sapp.run(
		{
			init_cb = init,
			frame_cb = frame,
			cleanup_cb = cleanup,
			width = W,
			height = H,
			window_title = "T02 – Shapes & Colors",
			logger = {func = slog.func},
		},
	)
}

