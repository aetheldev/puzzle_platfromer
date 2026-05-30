package v02_elemental_orbs

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540
MAX_PARTICLES :: 256

Element :: enum u8 { fire, ice, poison }

Particle :: struct {
	active: bool,
	element: Element,
	x, y: f32,
	vx, vy: f32,
	life, max_life: f32,
	size: f32,
}

particles: [MAX_PARTICLES]Particle
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

element_color :: proc(e: Element) -> (f32, f32, f32) {
	#partial switch e {
	case .fire:   return 1.0, 0.45, 0.1
	case .ice:    return 0.45, 0.85, 1.0
	case .poison: return 0.55, 1.0, 0.35
	}
	return 1, 1, 1
}

emit_particle :: proc(e: Element, x, y, seed: f32) {
	for &p in &particles {
		if p.active do continue
		p.active = true
		p.element = e
		p.x = x
		p.y = y
		#partial switch e {
		case .fire:
			p.vx = f32(math.sin(f64(seed*0.7))) * 22
			p.vy = -40 - f32(math.cos(f64(seed))) * 18
			p.life = 0.55
			p.size = 6
		case .ice:
			p.vx = f32(math.sin(f64(seed*0.3))) * 12
			p.vy = -15 - f32(math.cos(f64(seed*0.9))) * 8
			p.life = 0.85
			p.size = 5
		case .poison:
			p.vx = f32(math.sin(f64(seed*0.5))) * 16
			p.vy = -10 - f32(math.cos(f64(seed*0.8))) * 6
			p.life = 1.0
			p.size = 7
		}
		p.max_life = p.life
		break
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = { colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.05, g = 0.06, b = 0.09, a = 1 } } } }
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	t := f32(sapp.frame_count())

	orbs := [3]struct{ x, y: f32, e: Element }{
		{200, 260, .fire},
		{480, 260, .ice},
		{760, 260, .poison},
	}
	for orb, i in orbs {
		if sapp.frame_count() % 3 == 0 {
			emit_particle(orb.e, orb.x+36, orb.y+36, t+f32(i)*17)
		}
	}

	for &p in &particles {
		if !p.active do continue
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		#partial switch p.element {
		case .fire:
			p.vy -= 10 * dt
		case .ice:
			p.vx *= 0.995
		case .poison:
			p.vx += f32(math.sin(f64(t*0.1+p.x*0.01))) * 3 * dt
		}
		p.x += p.vx * dt * 60
		p.y += p.vy * dt * 60
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	for orb in orbs {
		r, g, b := element_color(orb.e)
		for i in 0..<4 {
			expand := f32(i+1) * 8
			draw_rect_alpha(orb.x-expand, orb.y-expand, 72+expand*2, 72+expand*2, r, g, b, 0.08 - f32(i)*0.015)
		}
		draw_rect_alpha(orb.x, orb.y, 72, 72, r, g, b, 1)
	}

	for p in particles {
		if !p.active do continue
		r, g, b := element_color(p.element)
		a := p.life / p.max_life
		s := p.size * (0.6 + a)
		draw_rect_alpha(p.x, p.y, s, s, r, g, b, a)
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
	sapp.run({ init_cb = init, frame_cb = frame, cleanup_cb = cleanup, width = W, height = H, window_title = "V02 Elemental Orbs", logger = { func = slog.func } })
}
