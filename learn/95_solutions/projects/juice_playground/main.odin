/*
Juice Playground
================
A tiny platformer whose ONLY purpose is to teach game feel.

The lesson: a plain white box that reacts to what the player does reads as
more polished than detailed art that moves stiffly. Feel before art.

What is in here and WHY it sells "polish":
  - Jump dust:   puff kicks off the feet the instant you launch.
  - Landing dust: wide flat burst on touchdown; bigger the harder you fall.
  - Run dust:    small puffs trail behind while running on the ground.
  - Squash/stretch: body squishes on land, stretches on jump, eases back.
  - Screen shake: tiny decaying jolt on a hard landing for weight.

Every effect is the SAME Particle struct with different spawn numbers.
Tuning those numbers is the actual craft. Go change them.

Controls:
  A/D or arrows : move
  Space / W / Up: jump
  R             : reset
*/

package juice_playground

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540

// --- self-contained RNG -----------------------------------------------------
// We deliberately do NOT use core:math/rand here. That package reads
// context.random_generator, and inside sokol's `"c"` callbacks the Odin
// context is fragile; a failed assert there crashes with a "contextless"
// error (exactly the MTKView-draw crash you saw). This tiny xorshift needs
// no context and never asserts, so it is safe to call from frame/event.
rng_state: u32 = 0x12345678

rng_f32 :: proc() -> f32 { // uniform [0, 1)
	rng_state ~= rng_state << 13
	rng_state ~= rng_state >> 17
	rng_state ~= rng_state << 5
	return f32(rng_state) / f32(max(u32))
}

rng_range :: proc(lo, hi: f32) -> f32 {
	if hi <= lo { return lo } // guard: never assert on inverted/empty range
	return lo + rng_f32() * (hi - lo)
}

rng_int :: proc(n: int) -> int { // [0, n)
	if n <= 0 { return 0 }
	return int(rng_f32() * f32(n))
}

FLOOR_Y    :: f32(H - 70)
GRAVITY    :: 2000.0
JUMP_VEL   :: -720.0
MOVE_SPEED :: 320.0

MAX_PARTICLES :: 512
PI :: 3.14159265

Particle :: struct {
	active:   bool,
	x, y:     f32,
	vx, vy:   f32,
	size:     f32,
	life:     f32,
	max_life: f32,
	drag:     f32, // velocity multiplier toward 0 per second (1 = none)
	grav:     f32,
	r, g, b:  u8,
}

Player :: struct {
	x, y:        f32,
	w, h:        f32,
	vx, vy:      f32,
	on_ground:   bool,
	scale_x:     f32, // squash/stretch
	scale_y:     f32,
	run_timer:   f32, // controls how often run dust spawns
}

player: Player
particles: [MAX_PARTICLES]Particle

key_left, key_right, jump_pressed: bool
shake_timer, shake_strength: f32

pass_action: sg.Pass_Action
blend_pip: sgl.Pipeline
rt_ctx: runtime.Context

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

draw_rect_a :: proc(x, y, w, h: f32, r, g, b, a: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(x,   y,   r, g, b, a)
	sgl.v2f_c4b(x+w, y,   r, g, b, a)
	sgl.v2f_c4b(x+w, y+h, r, g, b, a)
	sgl.v2f_c4b(x,   y+h, r, g, b, a)
	sgl.end()
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	draw_rect_a(x, y, w, h, r, g, b, 255)
}

// ---------------------------------------------------------------------------
// Particle pool
// ---------------------------------------------------------------------------

emit :: proc(x, y, vx, vy, size, life, drag, grav: f32, r, g, b: u8) {
	for &p in particles {
		if p.active do continue
		p.active = true
		p.x = x; p.y = y
		p.vx = vx; p.vy = vy
		p.size = size
		p.life = life; p.max_life = life
		p.drag = drag; p.grav = grav
		p.r = r; p.g = g; p.b = b
		return
	}
}

// Launch puff: dust pushed DOWN + outward as the body shoots up.
spawn_jump_dust :: proc(cx, feet_y: f32) {
	for i in 0..<10 {
		ang := rng_range(0.2, PI - 0.2) // lower half: outward + down
		spd := rng_range(60, 160)
		emit(
			cx + rng_range(-8, 8), feet_y,
			math.cos(ang) * spd, math.sin(ang) * spd,
			rng_range(3, 6),
			rng_range(0.2, 0.4),
			0.1, 300,
			210, 205, 195,
		)
	}
}

// Touchdown burst: mostly FLAT and sideways. Harder fall -> more + faster.
// This is the single biggest "weight" cue.
spawn_land_dust :: proc(cx, feet_y, impact: f32) {
	count := int(8 + impact * 22) // impact in ~0..1
	for i in 0..<count {
		// near-horizontal spray, slight up
		ang := PI*0.5 + rng_range(-0.5, 0.5)
		side := rng_range(-1, 1)
		spd := rng_range(80, 120) * (1 + impact*2)
		emit(
			cx + side*10, feet_y,
			math.cos(ang)*spd + side*spd, -rng_range(10, 60),
			rng_range(3, 7),
			rng_range(0.25, 0.5),
			0.05, 260,
			u8(200 + impact*55), u8(195 + impact*40), 190,
		)
	}
}

// Trailing run dust: spawned periodically while grounded + moving.
spawn_run_dust :: proc(cx, feet_y, dir: f32) {
	emit(
		cx - dir*8, feet_y,
		-dir*rng_range(20, 60), -rng_range(20, 50),
		rng_range(3, 5),
		rng_range(0.2, 0.35),
		0.1, 240,
		200, 195, 185,
	)
}

update_particles :: proc(dt: f32) {
	for &p in particles {
		if !p.active do continue
		p.life -= dt
		if p.life <= 0 { p.active = false; continue }
		damp := math.pow(p.drag, dt)
		p.vx *= damp
		p.vy *= damp
		p.vy += p.grav * dt
		p.x += p.vx * dt
		p.y += p.vy * dt
	}
}

// Draw ALL particles inside a SINGLE begin_quads/end pair. sokol-gl counts
// each begin/end as one "command"; doing one per particle wastes commands and
// can overflow the buffer on big bursts. One batch = one command, many quads.
draw_particles :: proc() {
	sgl.begin_quads()
	for &p in particles {
		if !p.active do continue
		t := p.life / p.max_life
		a := u8(clamp(t, 0, 1) * 255)
		s := p.size * (0.4 + 0.6*t) // shrink as it dies
		x := p.x - s*0.5
		y := p.y - s*0.5
		sgl.v2f_c4b(x,   y,   p.r, p.g, p.b, a)
		sgl.v2f_c4b(x+s, y,   p.r, p.g, p.b, a)
		sgl.v2f_c4b(x+s, y+s, p.r, p.g, p.b, a)
		sgl.v2f_c4b(x,   y+s, p.r, p.g, p.b, a)
	}
	sgl.end()
}

start_shake :: proc(strength: f32) {
	shake_timer = 0.18
	shake_strength = strength
}

// ---------------------------------------------------------------------------
// Sokol callbacks
// ---------------------------------------------------------------------------

reset :: proc() {
	player = {
		x = W/2, y = FLOOR_Y - 56,
		w = 36, h = 56,
		scale_x = 1, scale_y = 1,
		on_ground = true,
	}
	for &p in particles { p.active = false }
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .A, .LEFT:        key_left = true
		case .D, .RIGHT:       key_right = true
		case .SPACE, .W, .UP:  jump_pressed = true
		case .R:               reset()
		}
	case .KEY_UP:
		#partial switch e.key_code {
		case .A, .LEFT:  key_left = false
		case .D, .RIGHT: key_right = false
		}
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	// Raise sokol-gl's internal buffers. The defaults are small, and every
	// begin/end pair is one "command". Particle bursts (jump/land) push a lot
	// of geometry in a single frame; without more room sokol-gl asserts inside
	// the Metal draw and the app crashes. These numbers are generous + cheap.
	sgl.setup({
		max_vertices = 256 * 1024,
		max_commands = 16 * 1024,
		logger = { func = slog.func },
	})
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.09, g = 0.10, b = 0.14, a = 1 } } },
	}
	// "over" alpha blend so particle fade is true transparency.
	blend_pip = sgl.make_pipeline({
		colors = { 0 = { blend = {
			enabled = true,
			src_factor_rgb   = .SRC_ALPHA,
			dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
			src_factor_alpha = .ONE,
			dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		}}},
	})
	reset()
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	if dt <= 0 || dt > 0.1 { dt = 1.0/60.0 }

	was_on_ground := player.on_ground

	// --- horizontal movement ---
	player.vx = 0
	if key_left  { player.vx -= MOVE_SPEED }
	if key_right { player.vx += MOVE_SPEED }
	player.x += player.vx * dt
	if player.x < 0 { player.x = 0 }
	if player.x + player.w > W { player.x = W - player.w }

	// --- jump ---
	if jump_pressed && player.on_ground {
		player.vy = JUMP_VEL
		player.on_ground = false
		player.scale_x = 0.7  // stretch tall on launch
		player.scale_y = 1.3
		spawn_jump_dust(player.x + player.w/2, FLOOR_Y)
	}
	jump_pressed = false

	// --- gravity + floor ---
	player.vy += GRAVITY * dt
	player.y += player.vy * dt
	player.on_ground = false
	if player.y + player.h >= FLOOR_Y {
		player.y = FLOOR_Y - player.h
		player.on_ground = true
	}

	// --- landing this frame ---
	if !was_on_ground && player.on_ground {
		impact := clamp((player.vy) / 900.0, 0, 1) // how fast we hit
		player.vy = 0
		player.scale_x = 1.4  // squash flat on land
		player.scale_y = 0.6
		spawn_land_dust(player.x + player.w/2, FLOOR_Y, impact)
		if impact > 0.4 { start_shake(4 + impact*8) }
	}

	// --- run dust while grounded + moving ---
	if player.on_ground && player.vx != 0 {
		player.run_timer -= dt
		if player.run_timer <= 0 {
			player.run_timer = 0.06
			dir := player.vx > 0 ? f32(1) : f32(-1)
			spawn_run_dust(player.x + player.w/2, FLOOR_Y, dir)
		}
	}

	// --- ease squash/stretch back to 1 ---
	ease := 1 - math.pow(f32(0.0005), dt)
	player.scale_x += (1 - player.scale_x) * ease
	player.scale_y += (1 - player.scale_y) * ease

	update_particles(dt)

	// --- screen shake ---
	shake_x, shake_y: f32
	if shake_timer > 0 {
		shake_timer -= dt
		mag := shake_strength * (shake_timer / 0.18)
		shake_x = rng_range(-mag, mag)
		shake_y = rng_range(-mag, mag)
	}

	// --- render ---
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)
	sgl.matrix_mode_modelview()
	sgl.load_identity()
	sgl.translate(shake_x, shake_y, 0)
	sgl.load_pipeline(blend_pip)

	// ground
	draw_rect(0, FLOOR_Y, W, H - FLOOR_Y, 46, 54, 64)
	draw_rect(0, FLOOR_Y, W, 4, 70, 84, 100) // ground top edge highlight

	// player drawn around its center using squash/stretch scales
	cx := player.x + player.w/2
	bottom := player.y + player.h
	dw := player.w * player.scale_x
	dh := player.h * player.scale_y
	dx := cx - dw/2
	dy := bottom - dh // keep feet planted while squashing
	draw_rect_a(dx+6, bottom-6, dw-12, 8, 0, 0, 0, 90) // foot shadow
	draw_rect(dx, dy, dw, dh, 120, 200, 255)
	draw_rect(dx, dy, dw, 6, 180, 225, 255) // top highlight

	draw_particles()

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
		window_title = "Juice Playground",
		logger = { func = slog.func },
	})
}
