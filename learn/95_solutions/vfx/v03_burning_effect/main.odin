package v03_burning_effect

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540
MAX_EMBERS :: 192

Ember :: struct {
	active: bool,
	x, y: f32,
	vx, vy: f32,
	life, max_life: f32,
	size: f32,
}

embers: [MAX_EMBERS]Ember
burn_timer: f32
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

ignite :: proc() {
	burn_timer = 2.8
}

spawn_ember :: proc(x, y, seed: f32) {
	for &e in &embers {
		if e.active do continue
		e.active = true
		e.x = x
		e.y = y
		e.vx = f32(math.sin(f64(seed))) * 16
		e.vy = -32 - f32(math.cos(f64(seed*0.7))) * 18
		e.life = 0.8
		e.max_life = e.life
		e.size = 4 + f32(math.abs(math.sin(f64(seed)))) * 4
		break
	}
}

event :: proc "c" (ev: ^sapp.Event) {
	context = rt_ctx
	if ev.type != .KEY_DOWN do return
	#partial switch ev.key_code {
	case .SPACE, .ENTER:
		ignite()
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = { colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.06, g = 0.06, b = 0.08, a = 1 } } } }
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	t := f32(sapp.frame_count())
	target_x, target_y := f32(420), f32(180)
	target_w, target_h := f32(120), f32(160)

	if burn_timer > 0 {
		burn_timer -= dt
		if sapp.frame_count() % 2 == 0 {
			spawn_ember(target_x + 20 + f32(math.sin(f64(t*0.2)))*20, target_y + target_h - 20, t*0.3)
			spawn_ember(target_x + 70 + f32(math.cos(f64(t*0.17)))*16, target_y + target_h - 30, t*0.5)
		}
	}

	for &e in &embers {
		if !e.active do continue
		e.life -= dt
		if e.life <= 0 {
			e.active = false
			continue
		}
		e.x += e.vx * dt * 60
		e.y += e.vy * dt * 60
		e.vy -= 4 * dt
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// floor
	draw_rect_alpha(0, 420, W, 120, 0.15, 0.18, 0.22, 1)

	// target shadow
	draw_rect_alpha(target_x+18, target_y+target_h-6, 84, 14, 0, 0, 0, 0.28)

	// burn glow
	if burn_timer > 0 {
		pulse := 0.7 + 0.3 * f32(math.sin(f64(t*0.08)))
		for i in 0..<5 {
			expand := f32(i+1) * 10
			draw_rect_alpha(target_x-expand, target_y-expand, target_w+expand*2, target_h+expand*2, 1.0, 0.35, 0.08, (0.09-f32(i)*0.015)*pulse)
		}
	}

	// target body
	draw_rect_alpha(target_x, target_y, target_w, target_h, 0.45, 0.48, 0.56, 1)

	// hot overlay
	if burn_timer > 0 {
		draw_rect_alpha(target_x+10, target_y+10, target_w-20, target_h-20, 1.0, 0.45, 0.12, 0.35)
	}

	for e in embers {
		if !e.active do continue
		a := e.life / e.max_life
		draw_rect_alpha(e.x, e.y, e.size, e.size, 1.0, 0.45, 0.12, a)
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
	sapp.run({ init_cb = init, frame_cb = frame, event_cb = event, cleanup_cb = cleanup, width = W, height = H, window_title = "V03 Burning Effect", logger = { func = slog.func } })
}
