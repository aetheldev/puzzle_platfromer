/*
Sokoban Starter Project (JUICED)
================================
Goal: turn fundamentals into a full puzzle game, then make it FEEL good.

Plain rules are simple. The reason this version looks alive is "juice":
small extra layers of feedback that cost little but read as polish.

What got added on top of the plain version, and WHY:
  1. Particles
     A fixed pool of tiny structs. When you step, dust puffs at your feet.
     When you push a box, a sharp burst fires in the push direction.
     Particles fade out (alpha) and shrink so they read as "dissipating".
  2. Screen shake
     A short decaying camera offset on every box push. Tiny, but it sells
     impact. The whole grid jolts, not just the box.
  3. Smooth player slide
     The player's logical position snaps instantly (so the puzzle stays
     honest), but the DRAWN position eases toward it. Movement reads smooth
     without changing any game rules.
  4. Layered tiles + shadows
     Each tile gets a darker base + a lighter top inset, goals pulse, the
     box has a highlight edge. Cheap depth, big upgrade over flat squares.

Controls:
  - WASD / arrows: move one grid step
  - R: reset level
  - N: next level
  - P: previous level
  - Enter: next level after win

Learning next:
  - add undo
  - load many levels
  - add ice, switches, teleporters, one-way floors
*/

package sokoban

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:strings"

// --- self-contained RNG -----------------------------------------------------
// We deliberately avoid core:math/rand. It reads context.random_generator, and
// inside sokol's `"c"` callbacks the Odin context is fragile; a failed assert
// there crashes with a "contextless" error (the MTKView-draw crash). This tiny
// xorshift needs no context and never asserts, safe from frame/event.
rng_state: u32 = 0x9e3779b9

rng_f32 :: proc() -> f32 { // uniform [0, 1)
	rng_state ~= rng_state << 13
	rng_state ~= rng_state >> 17
	rng_state ~= rng_state << 5
	return f32(rng_state) / f32(max(u32))
}

rng_range :: proc(lo, hi: f32) -> f32 {
	if hi <= lo { return lo }
	return lo + rng_f32() * (hi - lo)
}

rng_int :: proc(n: int) -> int {
	if n <= 0 { return 0 }
	return int(rng_f32() * f32(n))
}

W :: 960
H :: 540
TILE :: 48
COLS :: 12
ROWS :: 10

MAX_PARTICLES :: 512
PI :: 3.14159265

Cell :: enum u8 {
	empty,
	wall,
	goal,
}

// One tiny short-lived dot. A particle is not special: it is just a struct
// we update every frame and stop drawing when its life runs out.
Particle :: struct {
	active:   bool,
	x, y:     f32,
	vx, vy:   f32,
	size:     f32,
	life:     f32, // counts down to 0
	max_life: f32, // for computing fade ratio
	drag:     f32, // velocity multiplier per second (1 = none)
	r, g, b:  u8,
}

cells: [ROWS][COLS]Cell
boxes: [ROWS][COLS]bool
player_x, player_y: int   // logical grid position (puzzle truth)
draw_px, draw_py: f32     // smoothed pixel position (visual only)
move_count: int
won: bool
win_timer: f32            // for the win pulse animation
current_level: int

particles: [MAX_PARTICLES]Particle
shake_timer: f32
shake_strength: f32
anim_time: f32            // global clock for pulses

LEVELS :: [3]string{
	#load("levels/level_01.txt"),
	#load("levels/level_02.txt"),
	#load("levels/level_03.txt"),
}

pass_action: sg.Pass_Action
rt_ctx: runtime.Context
blend_pip: sgl.Pipeline // alpha-blend pipeline so particle fade is real transparency

// ---------------------------------------------------------------------------
// Drawing helpers
// ---------------------------------------------------------------------------

// Filled rect with explicit alpha. Alpha is what makes particles fade.
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
// Particles
// ---------------------------------------------------------------------------

// Find a free slot and fill it. If the pool is full we just skip (cheap, safe).
emit :: proc(x, y, vx, vy, size, life, drag: f32, r, g, b: u8) {
	for &p in particles {
		if p.active do continue
		p.active   = true
		p.x = x; p.y = y
		p.vx = vx; p.vy = vy
		p.size = size
		p.life = life; p.max_life = life
		p.drag = drag
		p.r = r; p.g = g; p.b = b
		return
	}
}

// Soft puff under the feet when you step. Low speed, mostly sideways + up,
// warm grey. Reads as kicked-up dust.
spawn_step_dust :: proc(cx, cy: f32) {
	for i in 0..<10 {
		ang := rng_range(-PI, 0) // upper half: dust rises
		spd := rng_range(20, 70)
		emit(
			cx + rng_range(-6, 6),
			cy + rng_range(-2, 4),
			math.cos(ang) * spd,
			math.sin(ang) * spd * 0.6,
			rng_range(3, 6),
			rng_range(0.25, 0.45),
			0.1, // strong drag: dust slows fast
			200, 195, 180,
		)
	}
}

// Sharp directional burst when a box is pushed. Fires opposite-ish to the
// push so it looks like grit blasting out from under the box edge.
spawn_push_burst :: proc(cx, cy, dx, dy: f32) {
	base := math.atan2(dy, dx)
	for i in 0..<18 {
		ang := base + rng_range(-0.7, 0.7)
		spd := rng_range(120, 320)
		emit(
			cx, cy,
			math.cos(ang) * spd,
			math.sin(ang) * spd,
			rng_range(3, 7),
			rng_range(0.2, 0.4),
			0.2,
			255, u8(200 + rng_int(40)), 120,
		)
	}
}

// Celebration confetti on win.
spawn_win_burst :: proc(cx, cy: f32) {
	for i in 0..<60 {
		ang := rng_range(0, 2*PI)
		spd := rng_range(80, 380)
		emit(
			cx, cy,
			math.cos(ang) * spd,
			math.sin(ang) * spd,
			rng_range(3, 8),
			rng_range(0.5, 1.1),
			0.4,
			u8(120 + rng_int(135)), u8(180 + rng_int(75)), u8(120 + rng_int(135)),
		)
	}
}

update_particles :: proc(dt: f32) {
	for &p in particles {
		if !p.active do continue
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		// drag pulls velocity toward 0 over time (frame-rate independent)
		damp := math.pow(p.drag, dt)
		p.vx *= damp
		p.vy *= damp
		p.vy += 220 * dt // light gravity so dust settles
		p.x += p.vx * dt
		p.y += p.vy * dt
	}
}

// Draw ALL particles in ONE begin_quads/end pair. sokol-gl counts each
// begin/end as a "command"; one per particle can overflow the command buffer
// on big bursts (push grit, win confetti) and crash inside the Metal draw.
// One batch = one command, many quads.
draw_particles :: proc() {
	sgl.begin_quads()
	for &p in particles {
		if !p.active do continue
		t := p.life / p.max_life      // 1 -> 0 over lifetime
		a := u8(clamp(t, 0, 1) * 255)
		s := p.size * (0.4 + 0.6 * t) // shrink as it dies
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
	shake_timer = 0.22
	shake_strength = strength
}

// ---------------------------------------------------------------------------
// Level + rules (unchanged logic, this is the honest puzzle layer)
// ---------------------------------------------------------------------------

load_level :: proc(index: int) {
	current_level = index
	levels := LEVELS
	for row in 0..<ROWS {
		for col in 0..<COLS {
			cells[row][col] = .empty
			boxes[row][col] = false
		}
	}
	level_text := levels[index]
	row := 0
	for line in strings.split_lines_iterator(&level_text) {
		if len(line) == 0 { continue }
		for ch, col in line {
			if row >= ROWS || col >= COLS { continue }
			switch ch {
			case '#': cells[row][col] = .wall
			case 'G': cells[row][col] = .goal
			case 'B': boxes[row][col] = true
			case 'P':
				player_x = col
				player_y = row
			}
		}
		row += 1
	}
	move_count = 0
	won = false
	win_timer = 0
	// snap the visual position so we don't slide across the screen on load
	off_x, off_y := grid_offset()
	draw_px = off_x + f32(player_x*TILE)
	draw_py = off_y + f32(player_y*TILE)
	for &p in particles { p.active = false }
}

reset_level :: proc() {
	load_level(current_level)
}

change_level :: proc(dir: int) {
	count := len(LEVELS)
	new_index := (current_level + dir + count) % count
	load_level(new_index)
}

in_bounds :: proc(x, y: int) -> bool {
	return x >= 0 && x < COLS && y >= 0 && y < ROWS
}

is_blocked :: proc(x, y: int) -> bool {
	if !in_bounds(x, y) { return true }
	return cells[y][x] == .wall || boxes[y][x]
}

check_win :: proc() {
	for row in 0..<ROWS {
		for col in 0..<COLS {
			if cells[row][col] == .goal && !boxes[row][col] {
				won = false
				return
			}
		}
	}
	won = true
	win_timer = 0
	off_x, off_y := grid_offset()
	spawn_win_burst(off_x + f32(player_x*TILE) + TILE/2, off_y + f32(player_y*TILE) + TILE/2)
	start_shake(8)
	fmt.println("Solved in", move_count, "moves")
}

try_move :: proc(dx, dy: int) {
	if won do return
	nx := player_x + dx
	ny := player_y + dy
	if !in_bounds(nx, ny) { return }
	if cells[ny][nx] == .wall { return }

	off_x, off_y := grid_offset()

	pushed := false
	if boxes[ny][nx] {
		bx := nx + dx
		by := ny + dy
		if is_blocked(bx, by) { return } // box blocked -> whole move cancels
		boxes[ny][nx] = false
		boxes[by][bx] = true
		pushed = true
	}

	player_x = nx
	player_y = ny
	move_count += 1

	// --- juice on a successful move ---
	feet_x := off_x + f32(player_x*TILE) + TILE/2
	feet_y := off_y + f32(player_y*TILE) + TILE - 6
	spawn_step_dust(feet_x, feet_y)

	if pushed {
		// burst at the box's new cell, blasting in push direction
		bcx := off_x + f32((nx+dx)*TILE) + TILE/2
		bcy := off_y + f32((ny+dy)*TILE) + TILE/2
		spawn_push_burst(bcx, bcy, f32(dx), f32(dy))
		start_shake(7)
	}

	check_win()
}

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

grid_offset :: proc() -> (f32, f32) {
	return f32((W - COLS*TILE) / 2), f32((H - ROWS*TILE) / 2)
}

// ---------------------------------------------------------------------------
// Sokol callbacks
// ---------------------------------------------------------------------------

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN do return
	#partial switch e.key_code {
	case .ENTER:
		if won {
			change_level(1)
		}
	case .W, .UP:    try_move(0, -1)
	case .S, .DOWN:  try_move(0, 1)
	case .A, .LEFT:  try_move(-1, 0)
	case .D, .RIGHT: try_move(1, 0)
	case .R:         reset_level()
	case .N:         change_level(1)
	case .P:         change_level(-1)
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	// Raise sokol-gl's internal buffers. Defaults are small; particle bursts
	// (box-push grit, win confetti) push lots of geometry in one frame, and
	// without more room sokol-gl asserts inside the Metal draw and crashes.
	sgl.setup({
		max_vertices = 256 * 1024,
		max_commands = 16 * 1024,
		logger = { func = slog.func },
	})
	// enable alpha blending so particle fade works
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.07, g = 0.08, b = 0.11, a = 1 } } },
	}
	// Standard "over" alpha blend: src*srcA + dst*(1-srcA).
	// Without this, alpha<255 would just draw opaque and "fade" would not work.
	blend_pip = sgl.make_pipeline({
		colors = { 0 = { blend = {
			enabled = true,
			src_factor_rgb   = .SRC_ALPHA,
			dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
			src_factor_alpha = .ONE,
			dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		}}},
	})
	load_level(0)
}

frame :: proc "c" () {
	context = rt_ctx

	// variable timestep: how long the last frame took
	dt := f32(sapp.frame_duration())
	if dt <= 0 || dt > 0.1 { dt = 1.0/60.0 } // clamp on hitches
	anim_time += dt

	// update simulation-y visual state
	update_particles(dt)

	off_x, off_y := grid_offset()
	target_px := off_x + f32(player_x*TILE)
	target_py := off_y + f32(player_y*TILE)
	// Frame-rate independent exponential ease toward the logical position.
	// Smaller base = snappier settle. This is pure visual smoothing; the
	// puzzle logic already snapped player_x/player_y instantly.
	ease := 1 - math.pow(f32(0.000001), dt)
	draw_px += (target_px - draw_px) * ease
	draw_py += (target_py - draw_py) * ease

	// screen shake decays to 0
	shake_x, shake_y: f32
	if shake_timer > 0 {
		shake_timer -= dt
		mag := shake_strength * (shake_timer / 0.22)
		shake_x = rng_range(-mag, mag)
		shake_y = rng_range(-mag, mag)
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)
	// apply shake by translating everything
	sgl.matrix_mode_modelview()
	sgl.load_identity()
	sgl.translate(shake_x, shake_y, 0)

	// use the alpha-blend pipeline for everything this frame so
	// particle fade and the semi-transparent shadows blend correctly
	sgl.load_pipeline(blend_pip)

	// --- tiles ---
	for row in 0..<ROWS {
		for col in 0..<COLS {
			x := off_x + f32(col*TILE)
			y := off_y + f32(row*TILE)

			switch cells[row][col] {
			case .wall:
				// dark base + lighter top inset = fake bevel/depth
				draw_rect(x, y, TILE, TILE, 48, 60, 78)
				draw_rect(x+3, y+3, TILE-6, TILE-10, 78, 98, 124)
			case .goal:
				draw_rect(x, y, TILE, TILE, 36, 41, 51)
				// pulsing goal marker so the eye is drawn to targets
				pulse := 0.5 + 0.5 * math.sin(anim_time*4 + f32(row+col))
				g := u8(120 + pulse * 90)
				inset := 8 + pulse * 3
				draw_rect_a(x+inset, y+inset, TILE-inset*2, TILE-inset*2, 70, g, 110, 220)
			case .empty:
				// subtle checkerboard so the floor isn't a flat slab
				if (row+col) % 2 == 0 {
					draw_rect(x, y, TILE, TILE, 40, 45, 55)
				} else {
					draw_rect(x, y, TILE, TILE, 35, 40, 49)
				}
			}

			if boxes[row][col] {
				on_goal := cells[row][col] == .goal
				// drop shadow
				draw_rect_a(x+8, y+10, TILE-12, TILE-12, 0, 0, 0, 90)
				// body (greener when correctly placed = instant feedback)
				if on_goal {
					draw_rect(x+6, y+6, TILE-12, TILE-12, 150, 210, 110)
					draw_rect(x+6, y+6, TILE-12, 6, 190, 240, 150) // top highlight
				} else {
					draw_rect(x+6, y+6, TILE-12, TILE-12, 210, 150, 70)
					draw_rect(x+6, y+6, TILE-12, 6, 240, 195, 110) // top highlight
				}
			}
		}
	}

	// --- player (uses smoothed draw position) ---
	bob := math.sin(anim_time*6) * 1.5 // gentle idle bob
	draw_rect_a(draw_px+10, draw_py+12, TILE-16, TILE-14, 0, 0, 0, 90) // shadow
	if won {
		s := 0.5 + 0.5 * math.sin(win_timer*10)
		win_timer += dt
		draw_rect(draw_px+8, draw_py+8+bob, TILE-16, TILE-16, u8(120+s*100), 240, u8(120+s*60))
	} else {
		draw_rect(draw_px+8, draw_py+8+bob, TILE-16, TILE-16, 90, 170, 255)
		draw_rect(draw_px+8, draw_py+8+bob, TILE-16, 5, 150, 210, 255) // highlight
	}

	// --- particles on top ---
	draw_particles()

	// --- HUD ---
	for i in 0..<move_count {
		draw_rect(20 + f32(i*6), 20, 4, 12, 255, 220, 90)
	}
	for i in 0..<len(LEVELS) {
		if i == current_level {
			draw_rect(20 + f32(i*20), 40, 14, 10, 100, 180, 255)
		} else {
			draw_rect(20 + f32(i*20), 40, 14, 10, 70, 80, 95)
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
	sapp.run({
		init_cb = init,
		frame_cb = frame,
		event_cb = event,
		cleanup_cb = cleanup,
		width = W,
		height = H,
		window_title = "Sokoban (juiced)",
		logger = { func = slog.func },
	})
}
