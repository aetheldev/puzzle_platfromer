/*
TICKET 10 - Particles & Screen Shake
====================================
GOAL: Add game-feel juice. When the player lands or you press X, spawn
      particles and shake the camera.

CONCEPTS:
  - Particles
      Tiny short-lived objects with position, velocity, size, color, life.
      They are not special. They are just many small structs updated each frame.
  - Fixed-capacity pool
      We keep a `[MAX_PARTICLES]Particle` array and reuse dead slots.
      This avoids heap allocation every time an effect happens.
  - Lifetime
      `life -= dt`. If `life <= 0`, particle is inactive.
  - Camera shake
      Add a temporary offset to the camera when something impactful happens.
      The shake decays over time so it starts strong and settles quickly.

TASKS FOR YOU:
  [ ] Run it. Jump and land to see dust + shake.
  [ ] Press X to spawn a burst manually.
  [ ] Change BURST_COUNT and SHAKE_STRENGTH.
  [ ] Change particle gravity and colors.
  [ ] Add wall-jump particles later by reusing `spawn_burst`.
*/

package t10

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

FLOOR_Y        :: f32(H - 60)
GRAVITY        :: 1800.0
JUMP_VEL       :: -620.0
MOVE_SPEED     :: 300.0
BURST_COUNT    :: 20
MAX_PARTICLES  :: 256
SHAKE_TIME     :: 0.22
SHAKE_STRENGTH :: 12.0

Player :: struct {
	x, y: f32,
	w, h: f32,
	vel_y: f32,
	on_ground: bool,
}

Particle :: struct {
	active: bool,
	x, y: f32,
	vx, vy: f32,
	size: f32,
	life: f32,
	max_life: f32,
	r, g, b: u8,
}

player: Player
particles: [MAX_PARTICLES]Particle

key_left, key_right: bool
jump_pressed: bool
burst_pressed: bool

shake_timer: f32

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

spawn_burst :: proc(x, y: f32, count: int, upward: bool) {
	for i in 0..<count {
		for &p in &particles {
			if p.active do continue

			angle := (f32(i) / max(1, f32(count))) * 3.14159265
			if upward {
				angle += 3.14159265
			}
			speed := 80.0 + f32(i%5) * 35.0
			p.active = true
			p.x = x
			p.y = y
			p.vx = math.cos(angle) * speed
			p.vy = math.sin(angle) * speed
			if upward {
				p.vy *= 0.5
			}
			p.size = 4 + f32(i%3) * 2
			p.life = 0.35 + f32(i%4) * 0.04
			p.max_life = p.life
			p.r = 240
			p.g = u8(170 + (i % 4) * 15)
			p.b = 80
			break
		}
	}
}

start_shake :: proc() {
	shake_timer = SHAKE_TIME
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(x,   y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
	sgl.v2f_c4b(x,   y+h, r, g, b, 255)
	sgl.end()
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .A, .LEFT:  key_left = true
		case .D, .RIGHT: key_right = true
		case .SPACE, .W, .UP: jump_pressed = true
		case .X: burst_pressed = true
		}
	case .KEY_UP:
		#partial switch e.key_code {
		case .A, .LEFT:  key_left = false
		case .D, .RIGHT: key_right = false
		case .SPACE, .W, .UP:
			if player.vel_y < 0 {
				player.vel_y *= 0.5
			}
		}
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.05, g = 0.06, b = 0.10, a = 1 } } },
	}
	player = { x = 120, y = FLOOR_Y - 48, w = 32, h = 48, on_ground = true }
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	was_on_ground := player.on_ground

	vx: f32 = 0
	if key_left  { vx -= MOVE_SPEED }
	if key_right { vx += MOVE_SPEED }
	player.x += vx * dt
	if player.x < 0 { player.x = 0 }
	if player.x + player.w > W { player.x = W - player.w }

	if jump_pressed && player.on_ground {
		player.vel_y = JUMP_VEL
		player.on_ground = false
	}
	if burst_pressed {
		spawn_burst(player.x + player.w/2, player.y + player.h/2, BURST_COUNT, false)
		start_shake()
	}
	jump_pressed = false
	burst_pressed = false

	player.vel_y += GRAVITY * dt
	player.y += player.vel_y * dt
	player.on_ground = false
	if player.y + player.h >= FLOOR_Y {
		player.y = FLOOR_Y - player.h
		player.vel_y = 0
		player.on_ground = true
	}

	if !was_on_ground && player.on_ground {
		spawn_burst(player.x + player.w/2, FLOOR_Y, BURST_COUNT, true)
		start_shake()
	}

	for &p in &particles {
		if !p.active do continue
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		p.vy += 900 * dt
		p.x += p.vx * dt
		p.y += p.vy * dt
	}

	shake_x, shake_y: f32
	if shake_timer > 0 {
		shake_timer -= dt
		strength := SHAKE_STRENGTH * (shake_timer / SHAKE_TIME)
		t := f32(sapp.frame_count()) * 0.45
		shake_x = math.sin(t * 3.1) * strength
		shake_y = math.cos(t * 4.2) * strength * 0.6
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)
	sgl.matrix_mode_modelview()
	sgl.push_matrix()
	sgl.translate(shake_x, shake_y, 0)

	draw_rect(0, FLOOR_Y, W, H - FLOOR_Y, 70, 120, 70)
	draw_rect(player.x, player.y, player.w, player.h, 240, 200, 80)

	for p in particles {
		if !p.active do continue
		alpha := p.life / p.max_life
		size := p.size * (0.5 + alpha)
		sgl.begin_quads()
		sgl.v2f_c4f(p.x,        p.y,        f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.v2f_c4f(p.x + size, p.y,        f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.v2f_c4f(p.x + size, p.y + size, f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.v2f_c4f(p.x,        p.y + size, f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.end()
	}

	sgl.pop_matrix()

	// Small screen-space HUD bar showing remaining shake.
	if shake_timer > 0 {
		draw_rect(16, 16, 160 * (shake_timer / SHAKE_TIME), 8, 80, 200, 255)
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
	sapp.run({
		init_cb = init,
		frame_cb = frame,
		event_cb = event,
		cleanup_cb = cleanup,
		width = W,
		height = H,
		window_title = "T10 - Particles & Screen Shake",
		logger = { func = slog.func },
	})
}
