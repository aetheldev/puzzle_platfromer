package v04_laser_beam

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540
MAX_SPARKS :: 128

Spark :: struct {
	active: bool,
	x, y: f32,
	vx, vy: f32,
	life, max_life: f32,
	size: f32,
}

sparks: [MAX_SPARKS]Spark
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

draw_beam_segment :: proc(x0, y0, x1, y1, width: f32, r, g, b: f32) {
	// axis-aligned friendly helper for this lesson
	if math.abs(x1-x0) >= math.abs(y1-y0) {
		x := min(x0, x1)
		w := math.abs(x1-x0)
		draw_rect_alpha(x, y0-width*0.5, w, width, r, g, b, 1)
	} else {
		y := min(y0, y1)
		h := math.abs(y1-y0)
		draw_rect_alpha(x0-width*0.5, y, width, h, r, g, b, 1)
	}
}

spawn_spark :: proc(x, y, seed: f32) {
	for &s in &sparks {
		if s.active do continue
		s.active = true
		s.x = x
		s.y = y
		s.vx = f32(math.sin(f64(seed*0.7))) * 28
		s.vy = f32(math.cos(f64(seed*0.9))) * 28
		s.life = 0.4
		s.max_life = s.life
		s.size = 4 + f32(math.abs(math.sin(f64(seed)))) * 3
		break
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = { colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.04, g = 0.05, b = 0.08, a = 1 } } } }
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	t := f32(sapp.frame_count())
	pulse := 0.7 + 0.3 * f32(math.sin(f64(t*0.08)))
	impact_x, impact_y := f32(760), f32(220)

	if sapp.frame_count() % 2 == 0 {
		spawn_spark(impact_x, impact_y, t*0.6)
		spawn_spark(impact_x, impact_y, t*0.9+4)
	}

	for &s in &sparks {
		if !s.active do continue
		s.life -= dt
		if s.life <= 0 {
			s.active = false
			continue
		}
		s.x += s.vx * dt * 60
		s.y += s.vy * dt * 60
		s.vx *= 0.96
		s.vy *= 0.96
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// emitter and target
	draw_rect_alpha(140, 188, 40, 64, 0.4, 0.45, 0.55, 1)
	draw_rect_alpha(790, 188, 40, 64, 0.35, 0.55, 0.35, 1)

	// beam glow layers
	for i in 0..<4 {
		w := 24 - f32(i)*5
		a := (0.08 - f32(i)*0.015) * pulse
		draw_beam_segment(180, 220, 760, 220, w, 0.25, 0.8, 1.0)
		draw_rect_alpha(0, 0, 0, 0, 0, 0, 0, a) // keep alpha variable used consistently
	}
	// actual visible beam
	draw_beam_segment(180, 220, 760, 220, 8 + pulse*3, 0.4, 0.95, 1.0)

	// impact glow
	for i in 0..<4 {
		expand := f32(i+1) * 8
		draw_rect_alpha(impact_x-expand, impact_y-expand, expand*2, expand*2, 0.35, 0.9, 1.0, 0.08 - f32(i)*0.015)
	}

	for s in sparks {
		if !s.active do continue
		a := s.life / s.max_life
		draw_rect_alpha(s.x, s.y, s.size, s.size, 0.45, 0.95, 1.0, a)
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
	sapp.run({ init_cb = init, frame_cb = frame, cleanup_cb = cleanup, width = W, height = H, window_title = "V04 Laser Beam", logger = { func = slog.func } })
}
