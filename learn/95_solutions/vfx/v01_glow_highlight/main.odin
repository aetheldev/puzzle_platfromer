package v01_glow_highlight

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

selected: int
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

draw_rect_alpha :: proc(x, y, w, h: f32, r, g, b, a: f32) {
	sgl.begin_quads()
	sgl.v2f_c4f(x,   y,   r, g, b, a)
	sgl.v2f_c4f(x+w, y,   r, g, b, a)
	sgl.v2f_c4f(x+w, y+h, r, g, b, a)
	sgl.v2f_c4f(x,   y+h, r, g, b, a)
	sgl.end()
}

draw_outline :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_lines()
	sgl.v2f_c4b(x, y, r, g, b, 255)
	sgl.v2f_c4b(x+w, y, r, g, b, 255)
	sgl.v2f_c4b(x+w, y, r, g, b, 255)
	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
	sgl.v2f_c4b(x, y+h, r, g, b, 255)
	sgl.v2f_c4b(x, y+h, r, g, b, 255)
	sgl.v2f_c4b(x, y, r, g, b, 255)
	sgl.end()
}

draw_glow_box :: proc(x, y, w, h: f32, selected: bool, pulse: f32, r, g, b: f32) {
	layers := 3
	if selected do layers = 6
	for i in 0..<layers {
		expand := f32(i+1) * (selected ? 10 : 6)
		alpha := (selected ? 0.10 : 0.05) * (1.0 - f32(i)/f32(layers)) * pulse
		draw_rect_alpha(x-expand, y-expand, w+expand*2, h+expand*2, r, g, b, alpha)
	}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN do return
	#partial switch e.key_code {
	case .A, .LEFT:
		selected = (selected + 2) % 3
	case .D, .RIGHT:
		selected = (selected + 1) % 3
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = { colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.06, g = 0.07, b = 0.11, a = 1 } } } }
}

frame :: proc "c" () {
	context = rt_ctx
	pulse := 0.7 + 0.3 * f32((sapp.frame_count()%90))/90.0

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	positions := [3][2]f32{{180, 230}, {420, 190}, {660, 250}}
	colors := [3][3]f32{{1.0, 0.55, 0.2}, {0.35, 0.8, 1.0}, {0.75, 1.0, 0.35}}
	for pos, i in positions {
		col := colors[i]
		draw_glow_box(pos[0], pos[1], 110, 110, i == selected, pulse, col[0], col[1], col[2])
		draw_rect_alpha(pos[0], pos[1], 110, 110, col[0], col[1], col[2], 1)
		if i == selected {
			draw_outline(pos[0]-4, pos[1]-4, 118, 118, 255, 240, 180)
		}
	}

	sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
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
	sapp.run({ init_cb = init, frame_cb = frame, event_cb = event, cleanup_cb = cleanup, width = W, height = H, window_title = "V01 Glow Highlight", logger = { func = slog.func } })
}
