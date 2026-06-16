/*
PRACTICE GAME 08 - Platformer Juice
===================================
GOAL: A small complete platformer that FEELS good. The simulation is
      nothing you have not built before — the whole lesson is the gap
      between "correct" and "alive".

WHAT THIS COMBINES (nothing new!):
  - t04: gravity, jump velocity, variable jump height
  - t05: coyote time + jump buffer (invisible input forgiveness)
  - t07: string-array tilemap, axis-separated AABB collision
  - t08: smooth camera follow (lerp + clamp)
  - t10: particle pool + screen shake
  - s00/s06: render-to-texture post pass (vignette + color grade)

CONTROLS:
  - A/D or arrows: move
  - SPACE / W / UP: jump (hold = higher, release early = shorter)
  - R: restart

TASKS FOR YOU (after building your own — compare effect by effect):
  [ ] Find every place `dt` is manipulated (hitstop, win slow-mo).
  [ ] Verify squash/stretch never touches player.w / player.h.
  [ ] Landing dust count scales with fall speed — find the formula.
  [ ] Delete the post pass (two blocks) — game still runs untouched.
  [ ] Set COYOTE_TIME and JUMP_BUFFER_TIME to 0 and feel the loss.

DESIGN NOTES:
  - The sim writes to visuals; visuals NEVER write back to the sim.
  - Effects are proportional to cause (dust ~ fall speed).
  - Time is a juice channel: hitstop on pickup, slow-mo on win.
  - All pools are fixed-size with `active` flags. Zero heap per frame.
  - Post pass: the scene renders into an offscreen texture (via an
    sgl offscreen context), then one fullscreen quad samples it with
    a hand-written MSL fragment shader (same approach as s00/s06 —
    the bundled sokol-shdc does not match these bindings, and writing
    the MSL by hand teaches you exactly what a shader is).
*/

package p08_platformer_juice

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strings"

W :: 960
H :: 540
TILE :: 32

COLS :: 60
ROWS :: 18
WORLD_W :: f32(COLS * TILE) // 1920
WORLD_H :: f32(ROWS * TILE) // 576

// --- movement tuning ---
GRAVITY          :: 1800.0
JUMP_VEL         :: -640.0
MAX_SPEED        :: 320.0
GROUND_ACCEL     :: 2400.0
GROUND_DECEL     :: 2800.0
AIR_ACCEL        :: 1500.0
COYOTE_TIME      :: 0.10
JUMP_BUFFER_TIME :: 0.12
MAX_FALL         :: 900.0

// --- juice tuning ---
HITSTOP_TIME    :: 0.03   // frozen seconds on coin pickup
HARD_LAND_SPEED :: 620.0  // fall speed that earns a screen shake
SLOWMO_DURATION :: 1.0    // win slow-motion length
SLOWMO_SCALE    :: 0.25
CAM_LERP        :: 8.0

MAX_PARTICLES :: 512
MAX_COINS     :: 64

// Level legend: '#' solid, '^' spike, 'o' coin, 'P' player start, 'F' goal flag.
// 60 columns x 18 rows. Row 0 is the top.
LEVEL :: `
............................................................
............................................................
............................................................
............................................................
..........................o.o.o.............................
.........................#######............................
............................................................
..............o.....o.................o....o................
.............###...###...............##....##...............
............................................................
........o...................o..o.....................o.o....
.......###.................######...................######..
............................................................
......o..........................................o......F...
.....###........o..o............................###....#####
..P............######.........^^^...........................
#####..^^^...................#####..^^^.....................
############################################################
`

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

Player :: struct {
	x, y, w, h: f32,
	vx, vy:     f32,
	on_ground:  bool,
	facing:     f32, // -1 or 1, for eyes + run dust direction
	// input forgiveness (t05)
	coyote_timer:      f32,
	jump_buffer_timer: f32,
	// squash & stretch — DRAW ONLY, never touches w/h
	scale_x, scale_y: f32,
}

Particle :: struct {
	active:   bool,
	x, y:     f32,
	vx, vy:   f32,
	size:     f32,
	life:     f32,
	max_life: f32,
	grav:     f32, // per-particle gravity (confetti floats, dust drops)
	r, g, b:  u8,
}

Coin :: struct {
	active: bool, // currently collectible
	x, y:   f32,  // center
}

Camera :: struct {
	x, y: f32,
}

Game_State :: enum {
	playing,
	won,
}

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------

tiles: [ROWS][COLS]u8 // 0 empty, 1 solid, 2 spike
spawn_x, spawn_y: f32
flag_col, flag_row: int

player: Player
cam: Camera
particles: [MAX_PARTICLES]Particle
coins: [MAX_COINS]Coin
coin_count: int // how many parsed from the level

state: Game_State
coins_collected: int
deaths: int
total_time: f32 // scaled time, drives idle animations

key_left, key_right: bool

// time manipulation
hitstop_timer: f32
win_timer: f32

// screen shake
shake_timer: f32
shake_duration: f32
shake_strength: f32

// run dust trickle
run_dust_timer: f32

rt_ctx: runtime.Context

// ---------------------------------------------------------------------------
// Post-fx GPU resources (s00/s06 pattern)
// ---------------------------------------------------------------------------

// The fullscreen post shader: vignette + subtle color grade.
// Shadows are lifted slightly toward blue, highlights warmed —
// the classic "cinematic" two-tone grade, smallest possible dose.
POST_VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float2 uv; };
vertex vs_out _main(vs_in in [[stage_in]]) { vs_out o; o.position=float4(in.position,0,1); o.uv=in.uv; return o; }
`
POST_FS :: `
#include <metal_stdlib>
using namespace metal;
struct Params { float time; float pad0,pad1,pad2; };
fragment float4 _main(float2 uv [[stage_in]],
                      texture2d<float> scene [[texture(0)]],
                      sampler smp [[sampler(0)]],
                      constant Params& p [[buffer(0)]]) {
    float3 col = scene.sample(smp, uv).rgb;

    // COLOR GRADE — luminance-keyed two-tone:
    float l = dot(col, float3(0.299, 0.587, 0.114));
    // lift shadows slightly toward blue...
    col += (1.0 - smoothstep(0.0, 0.45, l)) * float3(0.015, 0.025, 0.060);
    // ...and warm the highlights.
    col *= mix(float3(1.0), float3(1.07, 1.02, 0.92), smoothstep(0.45, 1.0, l));

    // VIGNETTE — darken toward edges, never fully black.
    float2 c = uv - 0.5;
    float vig = smoothstep(0.85, 0.35, length(c));
    col *= mix(0.72, 1.0, vig);

    return float4(col, 1.0);
}
`

Post_Params :: struct #align(16) {
	time: f32,
	_pad: [3]f32,
}

offscreen_sgl: sgl.Context   // sgl draws the whole game through this
color_img:     sg.Image      // the offscreen texture the scene renders into
smp:           sg.Sampler
attachments:   sg.Attachments
post_pip:      sg.Pipeline
quad_vbuf:     sg.Buffer

scene_action: sg.Pass_Action
disp_action:  sg.Pass_Action

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

lerp :: proc(a, b, t: f32) -> f32 { return a + (b - a) * t }

overlaps :: proc(ax, ay, aw, ah, bx, by, bw, bh: f32) -> bool {
	return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8, a: u8 = 255) {
	sgl.begin_quads()
	sgl.v2f_c4b(x,     y,     r, g, b, a)
	sgl.v2f_c4b(x + w, y,     r, g, b, a)
	sgl.v2f_c4b(x + w, y + h, r, g, b, a)
	sgl.v2f_c4b(x,     y + h, r, g, b, a)
	sgl.end()
}

// ---------------------------------------------------------------------------
// Level
// ---------------------------------------------------------------------------

load_level :: proc() {
	lvl := string(LEVEL)
	row := 0
	for line in strings.split_lines_iterator(&lvl) {
		if len(line) == 0 { continue }
		for ch, col in line {
			if col >= COLS || row >= ROWS { continue }
			switch ch {
			case '#':
				tiles[row][col] = 1
			case '^':
				tiles[row][col] = 2
			case 'o':
				if coin_count < MAX_COINS {
					coins[coin_count] = {
						active = true,
						x = f32(col) * TILE + TILE / 2,
						y = f32(row) * TILE + TILE / 2,
					}
					coin_count += 1
				}
			case 'P':
				spawn_x = f32(col) * TILE + 4
				spawn_y = f32(row) * TILE
			case 'F':
				flag_col = col
				flag_row = row
			}
		}
		row += 1
	}
}

is_solid :: proc(col, row: int) -> bool {
	if col < 0 || col >= COLS { return true } // walls at world edges
	if row < 0 || row >= ROWS { return false } // open sky / pit
	return tiles[row][col] == 1
}

// ---------------------------------------------------------------------------
// Particles — one pool, many flavors
// ---------------------------------------------------------------------------

spawn_particle :: proc(x, y, vx, vy, size, life, grav: f32, r, g, b: u8) {
	for &p in particles {
		if p.active { continue }
		p = {
			active = true,
			x = x, y = y, vx = vx, vy = vy,
			size = size, life = life, max_life = life,
			grav = grav, r = r, g = g, b = b,
		}
		return
	}
}

// Landing / running dust: sandy gray puffs that kick outward and up.
spawn_dust :: proc(x, y: f32, count: int, dir: f32) {
	for _ in 0 ..< count {
		ang := rand.float32_range(-0.9, -2.2) // upward fan (radians)
		spd := rand.float32_range(40, 160)
		spawn_particle(
			x + rand.float32_range(-8, 8), y,
			math.cos(ang) * spd + dir * rand.float32_range(0, 60),
			math.sin(ang) * spd,
			rand.float32_range(3, 7),
			rand.float32_range(0.25, 0.5),
			500,
			200, 190, 165,
		)
	}
}

// Coin sparkle: bright yellow-white burst, weightless.
spawn_sparkle :: proc(x, y: f32) {
	for i in 0 ..< 14 {
		ang := f32(i) / 14.0 * math.TAU + rand.float32_range(-0.2, 0.2)
		spd := rand.float32_range(60, 200)
		bright := u8(rand.int_max(60))
		spawn_particle(
			x, y,
			math.cos(ang) * spd, math.sin(ang) * spd,
			rand.float32_range(2, 5),
			rand.float32_range(0.2, 0.45),
			0,
			255, 230 - bright, 90,
		)
	}
}

// Spike death: heavy red burst.
spawn_red_burst :: proc(x, y: f32) {
	for i in 0 ..< 28 {
		ang := f32(i) / 28.0 * math.TAU + rand.float32_range(-0.15, 0.15)
		spd := rand.float32_range(80, 320)
		spawn_particle(
			x, y,
			math.cos(ang) * spd, math.sin(ang) * spd - 80,
			rand.float32_range(3, 8),
			rand.float32_range(0.3, 0.7),
			900,
			230, u8(30 + rand.int_max(50)), 40,
		)
	}
}

CONFETTI_COLORS := [6][3]u8{
	{240, 90, 90}, {90, 200, 240}, {255, 210, 80},
	{120, 230, 120}, {220, 120, 240}, {250, 250, 250},
}

// Win celebration: colorful, floaty, falls slowly.
spawn_confetti :: proc(x, y: f32) {
	c := CONFETTI_COLORS[rand.int_max(len(CONFETTI_COLORS))]
	spawn_particle(
		x + rand.float32_range(-120, 120),
		y + rand.float32_range(-40, 10),
		rand.float32_range(-120, 120),
		rand.float32_range(-260, -80),
		rand.float32_range(3, 6),
		rand.float32_range(0.9, 1.6),
		260, // gentle gravity → flutter
		c[0], c[1], c[2],
	)
}

update_particles :: proc(dt: f32) {
	for &p in particles {
		if !p.active { continue }
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		p.vy += p.grav * dt
		p.x += p.vx * dt
		p.y += p.vy * dt
	}
}

draw_particles :: proc() {
	for p in particles {
		if !p.active { continue }
		alpha := p.life / p.max_life
		size := p.size * (0.5 + alpha)
		sgl.begin_quads()
		sgl.v2f_c4f(p.x,        p.y,        f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.v2f_c4f(p.x + size, p.y,        f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.v2f_c4f(p.x + size, p.y + size, f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.v2f_c4f(p.x,        p.y + size, f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, alpha)
		sgl.end()
	}
}

// ---------------------------------------------------------------------------
// Screen shake
// ---------------------------------------------------------------------------

start_shake :: proc(strength, duration: f32) {
	// a new shake never weakens an ongoing one
	if strength >= shake_strength || shake_timer <= 0 {
		shake_strength = strength
		shake_duration = duration
		shake_timer = duration
	}
}

shake_offset :: proc() -> (f32, f32) {
	if shake_timer <= 0 { return 0, 0 }
	s := shake_strength * (shake_timer / shake_duration)
	t := f32(sapp.frame_count()) * 0.45
	return math.sin(t * 3.1) * s, math.cos(t * 4.2) * s * 0.6
}

// ---------------------------------------------------------------------------
// 7-segment digits (no font, just rects)
// ---------------------------------------------------------------------------

// bit 0..6 = segments A(top) B(tr) C(br) D(bottom) E(bl) F(tl) G(middle)
SEG_TABLE := [10]u8{
	0x3F, // 0
	0x06, // 1
	0x5B, // 2
	0x4F, // 3
	0x66, // 4
	0x6D, // 5
	0x7D, // 6
	0x07, // 7
	0x7F, // 8
	0x6F, // 9
}

draw_digit :: proc(x, y: f32, d: int, r, g, b: u8) {
	dw, dh, t: f32 = 12, 22, 3
	half := dh / 2
	segs := SEG_TABLE[d]
	if segs & 0x01 != 0 { draw_rect(x + t, y, dw - 2*t, t, r, g, b) }                  // A
	if segs & 0x02 != 0 { draw_rect(x + dw - t, y + t, t, half - t, r, g, b) }         // B
	if segs & 0x04 != 0 { draw_rect(x + dw - t, y + half, t, half - t, r, g, b) }      // C
	if segs & 0x08 != 0 { draw_rect(x + t, y + dh - t, dw - 2*t, t, r, g, b) }         // D
	if segs & 0x10 != 0 { draw_rect(x, y + half, t, half - t, r, g, b) }               // E
	if segs & 0x20 != 0 { draw_rect(x, y + t, t, half - t, r, g, b) }                  // F
	if segs & 0x40 != 0 { draw_rect(x + t, y + half - t/2, dw - 2*t, t, r, g, b) }     // G
}

// up to 3 digits, left-aligned
draw_number :: proc(x, y: f32, n: int, r, g, b: u8) {
	v := clamp(n, 0, 999)
	digits: [3]int
	count := 1
	digits[0] = v % 10
	if v >= 10  { digits[1] = (v / 10) % 10; count = 2 }
	if v >= 100 { digits[2] = v / 100; count = 3 }
	for i in 0 ..< count {
		draw_digit(x + f32(count-1-i) * 18, y, digits[i], r, g, b)
	}
}

// ---------------------------------------------------------------------------
// Game flow
// ---------------------------------------------------------------------------

respawn :: proc() {
	player.x = spawn_x
	player.y = spawn_y
	player.vx = 0
	player.vy = 0
	player.on_ground = false
	player.coyote_timer = 0
	player.jump_buffer_timer = 0
	player.scale_x = 1
	player.scale_y = 1
	player.facing = 1
}

reset :: proc() {
	for i in 0 ..< coin_count { coins[i].active = true }
	for &p in particles { p.active = false }
	coins_collected = 0
	deaths = 0
	state = .playing
	win_timer = 0
	hitstop_timer = 0
	shake_timer = 0
	respawn()
	cam.x = clamp(player.x + player.w/2 - W/2, 0, WORLD_W - W)
	cam.y = clamp(player.y + player.h/2 - H/2, 0, WORLD_H - H)
	fmt.println("p08 ready. A/D move, SPACE jump (hold = higher), R restart.")
}

die :: proc() {
	deaths += 1
	spawn_red_burst(player.x + player.w/2, player.y + player.h/2)
	start_shake(14, 0.3)
	respawn()
	fmt.println("ouch. deaths:", deaths)
}

win :: proc() {
	state = .won
	win_timer = 0
	start_shake(6, 0.25)
	fmt.println("flag reached! coins:", coins_collected, "/", coin_count, " deaths:", deaths, "- R to restart")
}

// ---------------------------------------------------------------------------
// Player update — the entire simulation lives here
// ---------------------------------------------------------------------------

resolve_axis :: proc(axis: int) {
	right := player.x + player.w - 1
	bottom := player.y + player.h - 1
	corners := [4][2]f32{
		{player.x,            player.y},
		{right,               player.y},
		{player.x,            bottom},
		{right,               bottom},
	}
	for corner in corners {
		col := int(corner[0] / TILE)
		row := int(corner[1] / TILE)
		if !is_solid(col, row) { continue }
		tx := f32(col) * TILE
		ty := f32(row) * TILE
		if axis == 0 {
			ol := (player.x + player.w) - tx
			or_ := (tx + TILE) - player.x
			if ol < or_ {
				player.x -= ol
			} else {
				player.x += or_
			}
			player.vx = 0
		} else {
			ot := (player.y + player.h) - ty
			ob := (ty + TILE) - player.y
			if ot < ob {
				player.y -= ot
				player.vy = 0
				player.on_ground = true
			} else {
				player.y += ob
				player.vy = 0
			}
		}
	}
}

update_player :: proc(dt: f32) {
	// --- horizontal: accelerate toward a target speed ---
	target: f32 = 0
	if key_left  { target -= MAX_SPEED }
	if key_right { target += MAX_SPEED }
	if target != 0 { player.facing = math.sign(target) }

	accel: f32 = AIR_ACCEL
	if player.on_ground {
		accel = target != 0 ? GROUND_ACCEL : GROUND_DECEL
	}
	if player.vx < target {
		player.vx = min(player.vx + accel * dt, target)
	} else if player.vx > target {
		player.vx = max(player.vx - accel * dt, target)
	}
	player.x += player.vx * dt
	resolve_axis(0)

	// --- timers (t05) ---
	player.coyote_timer -= dt
	player.jump_buffer_timer -= dt

	// --- jump: buffered press + ground-or-coyote ---
	can_jump := player.on_ground || player.coyote_timer > 0
	if player.jump_buffer_timer > 0 && can_jump {
		player.vy = JUMP_VEL
		player.on_ground = false
		player.coyote_timer = 0
		player.jump_buffer_timer = 0
		// JUICE: stretch on takeoff (draw scale only!)
		player.scale_x = 0.65
		player.scale_y = 1.35
		spawn_dust(player.x + player.w/2, player.y + player.h, 4, 0)
	}

	// --- gravity + vertical ---
	was_on_ground := player.on_ground
	fall_speed := player.vy // remember impact speed BEFORE resolve zeroes it
	player.on_ground = false
	player.vy = min(player.vy + GRAVITY * dt, MAX_FALL)
	player.y += player.vy * dt
	fall_speed = player.vy
	resolve_axis(1)

	// start coyote window the moment we walk off a ledge
	if was_on_ground && !player.on_ground && player.vy >= 0 {
		player.coyote_timer = COYOTE_TIME
	}

	// --- landing: squash + dust proportional to impact ---
	if !was_on_ground && player.on_ground {
		impact := fall_speed
		t := clamp(impact / MAX_FALL, 0, 1)
		player.scale_x = 1 + 0.45 * t
		player.scale_y = 1 - 0.40 * t
		spawn_dust(player.x + player.w/2, player.y + player.h, 3 + int(t * 12), 0)
		if impact > HARD_LAND_SPEED {
			start_shake(4 + 8 * t, 0.2)
		}
	}

	// --- run dust trickle while moving on ground ---
	if player.on_ground && abs(player.vx) > 140 {
		run_dust_timer -= dt
		if run_dust_timer <= 0 {
			run_dust_timer = 0.07
			spawn_dust(player.x + player.w/2 - player.facing * 8, player.y + player.h, 1, -player.facing)
		}
	} else {
		run_dust_timer = 0
	}

	// --- squash/stretch eases back to 1 (purely visual) ---
	ease := min(1, 10 * dt)
	player.scale_x = lerp(player.scale_x, 1, ease)
	player.scale_y = lerp(player.scale_y, 1, ease)

	// --- fell out of the world? ---
	if player.y > WORLD_H + 100 {
		die()
	}
}

check_pickups_and_hazards :: proc() {
	// coins: AABB vs a small box around the coin center
	for i in 0 ..< coin_count {
		c := &coins[i]
		if !c.active { continue }
		if overlaps(player.x, player.y, player.w, player.h, c.x - 8, c.y - 8, 16, 16) {
			c.active = false
			coins_collected += 1
			spawn_sparkle(c.x, c.y)
			hitstop_timer = HITSTOP_TIME // JUICE: tiny freeze sells the pickup
		}
	}

	// spikes: check the tiles around the player against an inset hitbox
	c0 := max(0, int(player.x / TILE) - 1)
	c1 := min(COLS - 1, int((player.x + player.w) / TILE) + 1)
	r0 := max(0, int(player.y / TILE) - 1)
	r1 := min(ROWS - 1, int((player.y + player.h) / TILE) + 1)
	for row in r0 ..= r1 {
		for col in c0 ..= c1 {
			if tiles[row][col] != 2 { continue }
			// spikes only hurt on their pointy upper half, slightly inset
			sx := f32(col) * TILE + 6
			sy := f32(row) * TILE + TILE/2
			if overlaps(player.x, player.y, player.w, player.h, sx, sy, TILE - 12, TILE/2) {
				die()
				return
			}
		}
	}

	// goal flag
	fx := f32(flag_col) * TILE
	fy := f32(flag_row) * TILE
	if state == .playing &&
	   overlaps(player.x, player.y, player.w, player.h, fx + 8, fy - 16, 16, TILE + 16) {
		win()
	}
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

draw_background :: proc() {
	// vertical gradient sky (per-vertex colors interpolate)
	sgl.begin_quads()
	sgl.v2f_c4b(0, 0, 42, 50, 82, 255)
	sgl.v2f_c4b(W, 0, 42, 50, 82, 255)
	sgl.v2f_c4b(W, H, 16, 18, 32, 255)
	sgl.v2f_c4b(0, H, 16, 18, 32, 255)
	sgl.end()
}

// Parallax layers scroll at a fraction of camera speed. Drawn in screen
// space; the offset wraps so a handful of shapes covers any camera x.
draw_parallax :: proc() {
	// far layer: big soft hills (triangles), 20% of camera speed
	{
		spacing: f32 = 340
		off := math.mod(cam.x * 0.2, spacing)
		for i in -1 ..< 5 {
			base_x := f32(i) * spacing - off
			sgl.begin_triangles()
			sgl.v2f_c4b(base_x,       H,       30, 38, 62, 255)
			sgl.v2f_c4b(base_x + 170, H - 190, 30, 38, 62, 255)
			sgl.v2f_c4b(base_x + 340, H,       30, 38, 62, 255)
			sgl.end()
		}
	}
	// mid layer: mesas (rects), 45% of camera speed
	{
		spacing: f32 = 260
		off := math.mod(cam.x * 0.45, spacing)
		for i in -1 ..< 6 {
			base_x := f32(i) * spacing - off
			h := 90 + f32((i*7) %% 3) * 35
			draw_rect(base_x, H - h, 110, h, 24, 30, 50)
			draw_rect(base_x, H - h, 110, 6, 34, 42, 66) // top highlight
		}
	}
}

draw_tiles :: proc() {
	// only the columns the camera can see
	c0 := max(0, int(cam.x / TILE) - 1)
	c1 := min(COLS - 1, int((cam.x + W) / TILE) + 1)
	for row in 0 ..< ROWS {
		for col in c0 ..= c1 {
			x := f32(col) * TILE
			y := f32(row) * TILE
			switch tiles[row][col] {
			case 1:
				// lighter top face illusion (t07)
				draw_rect(x, y,     TILE, 5,        120, 165, 110)
				draw_rect(x, y + 5, TILE, TILE - 5, 72,  110, 70)
			case 2:
				// two spikes per tile
				for s in 0 ..< 2 {
					sx := x + f32(s) * (TILE / 2)
					sgl.begin_triangles()
					sgl.v2f_c4b(sx,            y + TILE, 175, 80, 85, 255)
					sgl.v2f_c4b(sx + TILE/4,   y + 6,    215, 110, 110, 255)
					sgl.v2f_c4b(sx + TILE/2,   y + TILE, 175, 80, 85, 255)
					sgl.end()
				}
			}
		}
	}
}

draw_coins :: proc() {
	for i in 0 ..< coin_count {
		c := coins[i]
		if !c.active { continue }
		bob := math.sin(total_time * 4 + c.x * 0.05) * 3
		s: f32 = 7
		// diamond
		sgl.begin_quads()
		sgl.v2f_c4b(c.x,     c.y - s + bob, 255, 210, 70, 255)
		sgl.v2f_c4b(c.x + s, c.y + bob,     255, 230, 110, 255)
		sgl.v2f_c4b(c.x,     c.y + s + bob, 230, 180, 50, 255)
		sgl.v2f_c4b(c.x - s, c.y + bob,     255, 230, 110, 255)
		sgl.end()
	}
}

draw_flag :: proc() {
	x := f32(flag_col) * TILE
	y := f32(flag_row) * TILE
	// pole
	draw_rect(x + 14, y - 16, 4, TILE + 16, 200, 200, 210)
	// waving banner (triangle whose tip oscillates)
	wave := math.sin(total_time * 6) * 4
	sgl.begin_triangles()
	sgl.v2f_c4b(x + 18, y - 16,           90, 220, 130, 255)
	sgl.v2f_c4b(x + 18 + 22 + wave, y - 6, 70, 190, 110, 255)
	sgl.v2f_c4b(x + 18, y + 4,            90, 220, 130, 255)
	sgl.end()
}

draw_player :: proc() {
	// squash & stretch: scale around the bottom-center anchor so the
	// feet stay planted. The collision box (w/h) is NOT touched.
	cw := player.w * player.scale_x
	ch := player.h * player.scale_y
	px := player.x + player.w/2 - cw/2
	py := player.y + player.h - ch
	draw_rect(px, py, cw, ch, 240, 200, 80)
	// eyes (look where you run — free charm)
	eye_off := player.facing * 4
	draw_rect(px + cw/2 - 6 + eye_off, py + ch * 0.22, 4, 6, 40, 36, 30)
	draw_rect(px + cw/2 + 2 + eye_off, py + ch * 0.22, 4, 6, 40, 36, 30)
}

draw_hud :: proc() {
	// coin icon (diamond) + count
	cx, cy: f32 = 24, 28
	sgl.begin_quads()
	sgl.v2f_c4b(cx,     cy - 8, 255, 210, 70, 255)
	sgl.v2f_c4b(cx + 8, cy,     255, 230, 110, 255)
	sgl.v2f_c4b(cx,     cy + 8, 230, 180, 50, 255)
	sgl.v2f_c4b(cx - 8, cy,     255, 230, 110, 255)
	sgl.end()
	draw_number(42, 17, coins_collected, 255, 220, 120)

	// death icon (red X) + count
	dy: f32 = 52
	draw_rect(17, dy + 6, 14, 4, 220, 90, 90)
	draw_rect(22, dy + 1, 4, 14, 220, 90, 90)
	draw_number(42, dy - 3, deaths, 230, 120, 120)
}

// ---------------------------------------------------------------------------
// Sokol callbacks
// ---------------------------------------------------------------------------

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .A, .LEFT:  key_left = true
		case .D, .RIGHT: key_right = true
		case .SPACE, .W, .UP:
			player.jump_buffer_timer = JUMP_BUFFER_TIME
		case .R:
			reset()
		}
	case .KEY_UP:
		#partial switch e.key_code {
		case .A, .LEFT:  key_left = false
		case .D, .RIGHT: key_right = false
		case .SPACE, .W, .UP:
			// variable jump height: release early = shorter jump
			if player.vy < 0 {
				player.vy *= 0.45
			}
		}
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})

	// --- offscreen target the whole game renders into (s00 pattern) ---
	color_img = sg.make_image({
		render_target = true,
		width = W, height = H,
		pixel_format = .RGBA8,
		sample_count = 1,
	})
	smp = sg.make_sampler({
		min_filter = .LINEAR, mag_filter = .LINEAR,
		wrap_u = .CLAMP_TO_EDGE, wrap_v = .CLAMP_TO_EDGE,
	})
	attachments = sg.make_attachments({colors = {0 = {image = color_img}}})

	// sgl needs a context whose formats match the offscreen target
	offscreen_sgl = sgl.make_context({
		max_vertices = 65536,
		max_commands = 16384,
		color_format = .RGBA8,
		depth_format = .NONE,
		sample_count = 1,
	})

	scene_action = {colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.06, g = 0.07, b = 0.11, a = 1}}}}
	disp_action  = {colors = {0 = {load_action = .CLEAR}}}

	// --- fullscreen quad + post pipeline (s06 pattern) ---
	fq := [?]f32{-1, -1, 0, 1, 1, -1, 1, 1, 1, 1, 1, 0, -1, -1, 0, 1, 1, 1, 1, 0, -1, 1, 0, 0}
	quad_vbuf = sg.make_buffer({data = {ptr = raw_data(fq[:]), size = size_of(fq)}})

	post_shd := sg.make_shader({
		vertex_func   = {source = POST_VS, entry = "_main"},
		fragment_func = {source = POST_FS, entry = "_main"},
		uniform_blocks = {0 = {stage = .FRAGMENT, size = u32(size_of(Post_Params)), msl_buffer_n = 0}},
		images   = {0 = {stage = .FRAGMENT, image_type = ._2D, sample_type = .FLOAT}},
		samplers = {0 = {stage = .FRAGMENT, sampler_type = .FILTERING}},
		image_sampler_pairs = {0 = {stage = .FRAGMENT, image_slot = 0, sampler_slot = 0}},
	})
	post_pip = sg.make_pipeline({
		shader = post_shd,
		layout = {attrs = {0 = {format = .FLOAT2}, 1 = {format = .FLOAT2}}},
	})

	load_level()
	player.w = 22
	player.h = 30
	reset()
}

frame :: proc "c" () {
	context = rt_ctx
	real_dt := min(f32(sapp.frame_duration()), 1.0 / 30.0)

	// --- time manipulation: the cheapest juice there is ---
	time_scale: f32 = 1
	if state == .won {
		win_timer += real_dt
		if win_timer < SLOWMO_DURATION {
			time_scale = SLOWMO_SCALE
		} else {
			time_scale = min(1, SLOWMO_SCALE + (win_timer - SLOWMO_DURATION) * 1.5)
		}
		// confetti storm during the celebration
		if win_timer < 1.4 {
			fx := f32(flag_col) * TILE + TILE/2
			fy := f32(flag_row) * TILE - 40
			for _ in 0 ..< 3 {
				spawn_confetti(fx, fy)
			}
		}
	}
	dt := real_dt * time_scale
	if hitstop_timer > 0 {
		hitstop_timer -= real_dt
		dt = 0 // the world holds its breath
	}

	total_time += dt

	if dt > 0 {
		update_player(dt)
		check_pickups_and_hazards()
		update_particles(dt)
	}

	// --- camera: lerp toward player center, clamp to world ---
	target_x := player.x + player.w/2 - W/2
	target_y := player.y + player.h/2 - H/2
	cam.x = lerp(cam.x, target_x, min(1, CAM_LERP * real_dt))
	cam.y = lerp(cam.y, target_y, min(1, CAM_LERP * real_dt))
	cam.x = clamp(cam.x, 0, WORLD_W - W)
	cam.y = clamp(cam.y, 0, WORLD_H - H)
	shx, shy := shake_offset()

	// --- record the whole scene into the offscreen sgl context ---
	sgl.set_context(offscreen_sgl)
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	draw_background()
	draw_parallax()

	sgl.matrix_mode_modelview()
	sgl.push_matrix()
	sgl.translate(-cam.x + shx, -cam.y + shy, 0)

	draw_tiles()
	draw_coins()
	draw_flag()
	draw_player()
	draw_particles()

	sgl.pop_matrix()

	draw_hud()

	// ---- PASS 1: scene -> offscreen texture ----
	sg.begin_pass({action = scene_action, attachments = attachments})
	sgl.context_draw(offscreen_sgl)
	sg.end_pass()

	// ---- PASS 2: fullscreen quad through the post shader ----
	params := Post_Params{time = total_time}
	sg.begin_pass({action = disp_action, swapchain = sglue.swapchain()})
	sg.apply_pipeline(post_pip)
	sg.apply_bindings({
		vertex_buffers = {0 = quad_vbuf},
		images = {0 = color_img},
		samplers = {0 = smp},
	})
	sg.apply_uniforms(0, {ptr = &params, size = size_of(Post_Params)})
	sg.draw(0, 6, 1)
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
		window_title = "P08 - Platformer Juice",
		logger = {func = slog.func},
	})
}
