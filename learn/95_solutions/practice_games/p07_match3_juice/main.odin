/*
PRACTICE GAME 07 - Match-3 Juice
================================
GOAL: A complete match-3 (click-select, swap, match, cascade) that FEELS
      great: easing, fall bounces, particles, screen shake, score popups,
      animated shader background. The logic is p04-grade; the juice is
      the lesson.

WHAT THIS COMBINES (nothing new!):
  - t07: grid thinking, pixel <-> cell math
  - t13: mouse hit-testing, click-to-select
  - t10: particle pool + screen shake (lifted wholesale)
  - t03: dt movement, easing toward a target
  - o05: Phase enum + switch (the board state machine)
  - s00: hand-written fragment shader with a time uniform (background)

CONTROLS:
  - Left click: select a gem / click an adjacent gem to swap
  - R: reshuffle the board (resets score)

DESIGN NOTES (the pillars, see LESSON.md):
  - The logic grid (gem kinds) is AUTHORITATIVE and snaps instantly.
    Each gem also carries a visual position that eases toward its cell.
    All animation is visual-only; logic never waits for a tween.
  - One Phase at a time: idle -> swapping -> clearing -> falling ->
    (cascade? clearing : idle). Invalid swaps are just "swap, find no
    match, swap back" — the visuals chase the logic both times.
  - Fixed pools everywhere (particles, popups). Zero per-frame allocation.
  - Background = fullscreen quad + Metal fragment shader (same approach
    as the s-lesson solutions: hand-written MSL, no shader compiler).

TASKS FOR YOU:
  [ ] Run it. Make a few matches. Find a cascade.
  [ ] Set LERP_SPEED to 1000 and FALL_GRAVITY to 1e6 — see the "ugly
      instant" version the visual layer is painted over.
  [ ] Change BOUNCE_DAMP and feel how landings change.
  [ ] Make combo shake stronger. Find the "too much" point.
  [ ] Add a 4-match bomb gem (stretch goal in LESSON.md).
*/

package p07_match3_juice

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/rand"

W :: 960
H :: 540

GRID  :: 8
KINDS :: 6
CELL  :: 56
BOARD_X :: (W - GRID * CELL) / 2 // 256
BOARD_Y :: (H - GRID * CELL) / 2 // 46

LERP_SPEED     :: 13.0   // visual ease speed for swaps/reverts
FALL_GRAVITY   :: 2800.0 // px/s^2 for falling gems
BOUNCE_DAMP    :: 0.22   // landing velocity kept on bounce
BOUNCE_MIN_VEL :: 160.0  // land slower than this = settle, no bounce
CLEAR_TIME     :: 0.28   // shrink-and-pop duration
SHAKE_TIME     :: 0.30
BURST_COUNT    :: 14     // particles per cleared gem
MAX_PARTICLES  :: 512
MAX_POPUPS     :: 16
POPUP_LIFE     :: 1.0

// ---------------------------------------------------------------------------
// Background shader (hand-written MSL, same per-backend approach as the
// s-lesson solutions in learn/95_solutions/shaders — macOS/Metal only).
// A fullscreen quad; the fragment shader animates slow waves from a single
// time uniform. Drawn first each frame, gems are sgl-drawn on top.
// ---------------------------------------------------------------------------

BG_VS :: `
#include <metal_stdlib>
using namespace metal;
struct vs_in  { float2 position [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct vs_out { float4 position [[position]];      float2 uv; };
vertex vs_out _main(vs_in in [[stage_in]]) { vs_out o; o.position=float4(in.position,0,1); o.uv=in.uv; return o; }
`

BG_FS :: `
#include <metal_stdlib>
using namespace metal;
struct Params { float time; float pad0,pad1,pad2; };
fragment float4 _main(float2 uv [[stage_in]],
                      constant Params& p [[buffer(0)]]) {
    float t = p.time;
    // slow two-tone gradient, warped by drifting sine waves
    float wave = sin(uv.x*5.0 + t*0.40)*0.5 + sin(uv.y*3.0 - t*0.25)*0.5;
    float3 deep = float3(0.045, 0.040, 0.095);
    float3 glow = float3(0.100, 0.070, 0.200);
    float3 col  = mix(deep, glow, clamp(uv.y + wave*0.12, 0.0, 1.0));
    // faint diagonal bands drifting through
    col += 0.018 * sin((uv.x + uv.y)*18.0 - t*0.6);
    // baked vignette so the corners stay calm under the board
    float2 d = uv - 0.5;
    col *= 1.0 - dot(d, d)*0.9;
    return float4(col, 1.0);
}
`

Bg_Params :: struct #align(16) {
	time: f32,
	_pad: [3]f32,
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

// One board cell. `kind` is the LOGIC (authoritative, snaps instantly).
// Everything else is the VISUAL layer chasing it.
Gem :: struct {
	kind:         int, // 0..KINDS-1, -1 = empty (mid-resolve only)
	vis_x, vis_y: f32, // visual top-left of the gem's cell, in pixels
	vy:           f32, // fall velocity (visual)
	falling:      bool,
	clearing:     bool, // mid shrink-and-pop
}

// The board state machine. One phase at a time, ever.
Phase :: enum {
	idle,      // waiting for input
	swapping,  // two gems gliding to swapped cells; then match-check
	reverting, // invalid swap gliding back
	clearing,  // matched gems shrinking; then particles + gravity
	falling,   // gems dropping into holes; then cascade-check
}

Cell :: struct {
	col, row: int,
}

Particle :: struct {
	active:   bool,
	x, y:     f32,
	vx, vy:   f32,
	size:     f32,
	life:     f32,
	max_life: f32,
	r, g, b:  u8,
}

Popup :: struct {
	active: bool,
	x, y:   f32, // center
	value:  int,
	life:   f32,
}

KIND_COLORS := [KINDS][3]u8{
	{235,  80,  90}, // 0 red    diamond
	{ 70, 170, 245}, // 1 blue   circle
	{250, 200,  70}, // 2 yellow square
	{ 90, 215, 110}, // 3 green  triangle
	{180, 110, 245}, // 4 purple hexagon
	{245, 140,  60}, // 5 orange star
}

// 7-segment masks for digits 0-9. Bits: 1 top, 2 top-right, 4 bottom-right,
// 8 bottom, 16 bottom-left, 32 top-left, 64 middle.
SEG_MASK := [10]u8{63, 6, 91, 79, 102, 109, 125, 7, 127, 111}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

grid:    [GRID][GRID]Gem  // [col][row], row 0 = top
matched: [GRID][GRID]bool // scratch output of find_matches

phase:       Phase
phase_timer: f32

sel_col, sel_row: int = -1, -1
swap_a, swap_b:   Cell

score: int
combo: int // current cascade depth; 0 outside a resolve

particles: [MAX_PARTICLES]Particle
popups:    [MAX_POPUPS]Popup

shake_timer, shake_strength: f32
t_now:            f32
mouse_x, mouse_y: f32

bg_pip:      sg.Pipeline
bg_vbuf:     sg.Buffer
gem_pip:     sgl.Pipeline // sgl pipeline with alpha blending
pass_action: sg.Pass_Action
rt_ctx:      runtime.Context

// ---------------------------------------------------------------------------
// Board logic (the authoritative part — everything here SNAPS)
// ---------------------------------------------------------------------------

cell_px :: proc(col: int) -> f32 { return f32(BOARD_X + col * CELL) }
cell_py :: proc(row: int) -> f32 { return f32(BOARD_Y + row * CELL) }

// would placing `kind` at col,row complete a 3-run with already-filled
// neighbors above/left? (used only for the initial no-free-matches fill)
makes_match_at :: proc(col, row, kind: int) -> bool {
	if col >= 2 && grid[col-1][row].kind == kind && grid[col-2][row].kind == kind {
		return true
	}
	if row >= 2 && grid[col][row-1].kind == kind && grid[col][row-2].kind == kind {
		return true
	}
	return false
}

reset_board :: proc() {
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			kind := rand.int_max(KINDS)
			for makes_match_at(col, row, kind) {
				kind = rand.int_max(KINDS)
			}
			g := &grid[col][row]
			g.kind = kind
			g.vis_x = cell_px(col)
			// start above the screen, staggered per column: the whole board
			// rains in. Pure flourish — and it exercises the fall code.
			g.vis_y = cell_py(row) - f32(GRID*CELL) - f32(col)*14 - rand.float32_range(0, 30)
			g.vy = 0
			g.falling = true
			g.clearing = false
		}
	}
	matched = {}
	sel_col, sel_row = -1, -1
	score = 0
	combo = 0
	phase = .falling
}

// swap the two Gem structs. Visual positions travel WITH the gems, so after
// a swap each gem simply eases toward its new cell. Revert = call it again.
swap_gems :: proc(a, b: Cell) {
	grid[a.col][a.row], grid[b.col][b.row] = grid[b.col][b.row], grid[a.col][a.row]
}

// mark every gem in a 3+ run (rows and columns) in `matched`; return count.
find_matches :: proc() -> int {
	matched = {}
	for row in 0 ..< GRID { // horizontal runs
		run := 1
		for col in 1 ..= GRID {
			same := col < GRID &&
				grid[col][row].kind >= 0 &&
				grid[col][row].kind == grid[col-1][row].kind
			if same {
				run += 1
			} else {
				if run >= 3 && grid[col-1][row].kind >= 0 {
					for k in col - run ..< col do matched[k][row] = true
				}
				run = 1
			}
		}
	}
	for col in 0 ..< GRID { // vertical runs
		run := 1
		for row in 1 ..= GRID {
			same := row < GRID &&
				grid[col][row].kind >= 0 &&
				grid[col][row].kind == grid[col][row-1].kind
			if same {
				run += 1
			} else {
				if run >= 3 && grid[col][row-1].kind >= 0 {
					for k in row - run ..< row do matched[col][k] = true
				}
				run = 1
			}
		}
	}
	count := 0
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			if matched[col][row] do count += 1
		}
	}
	return count
}

// matched gems start their shrink-and-pop. Combo, score, shake, popup.
start_clear :: proc() {
	combo += 1
	count := 0
	sum_x, sum_y: f32
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			if !matched[col][row] do continue
			g := &grid[col][row]
			g.clearing = true
			count += 1
			sum_x += g.vis_x + CELL / 2
			sum_y += g.vis_y + CELL / 2
		}
	}
	points := count * 10 * combo // combo IS the score multiplier
	score += points
	spawn_popup(sum_x / f32(count), sum_y / f32(count), points)
	if combo >= 2 {
		start_shake(min(f32(combo) * 4.0, 16.0)) // scaled by combo, capped
	}
	phase = .clearing
	phase_timer = CLEAR_TIME
}

// shrink animation done: burst particles in each gem's color, empty the cells.
finish_clear :: proc() {
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			g := &grid[col][row]
			if !g.clearing do continue
			c := KIND_COLORS[g.kind]
			spawn_burst(g.vis_x + CELL/2, g.vis_y + CELL/2, BURST_COUNT, c[0], c[1], c[2])
			g.kind = -1
			g.clearing = false
		}
	}
}

// compact each column downward (logic snaps!), spawn new gems above the
// board with visual positions stacked off-screen so they fall in.
apply_gravity :: proc() {
	for col in 0 ..< GRID {
		write := GRID - 1
		for row := GRID - 1; row >= 0; row -= 1 {
			if grid[col][row].kind < 0 do continue
			if write != row {
				grid[col][write] = grid[col][row] // visual pos travels along
				grid[col][write].falling = true
				grid[col][write].vy = 0
				grid[col][row].kind = -1
			}
			write -= 1
		}
		// rows 0..write are holes: rain new gems in from above
		for row in 0 ..= write {
			g := &grid[col][row]
			g.kind = rand.int_max(KINDS)
			g.vis_x = cell_px(col)
			g.vis_y = f32(BOARD_Y) - f32(write-row+1) * CELL
			g.vy = 0
			g.falling = true
			g.clearing = false
		}
	}
}

gem_settled :: proc(col, row: int) -> bool {
	g := grid[col][row]
	if g.falling {
		return false
	}
	return abs(g.vis_x - cell_px(col)) < 0.6 && abs(g.vis_y - cell_py(row)) < 0.6
}

all_settled :: proc() -> bool {
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			if !gem_settled(col, row) do return false
		}
	}
	return true
}

// ---------------------------------------------------------------------------
// Juice pools (t10 pattern: fixed arrays, `active` flags, no allocation)
// ---------------------------------------------------------------------------

spawn_burst :: proc(x, y: f32, count: int, r, g, b: u8) {
	for _ in 0 ..< count {
		for &p in &particles {
			if p.active do continue
			ang := rand.float32() * math.TAU
			spd := rand.float32_range(50, 230)
			p.active = true
			p.x, p.y = x, y
			p.vx = math.cos(ang) * spd
			p.vy = math.sin(ang)*spd - 60 // slight upward bias reads "pop"
			p.size = rand.float32_range(2.5, 5.5)
			p.life = rand.float32_range(0.30, 0.55)
			p.max_life = p.life
			p.r, p.g, p.b = r, g, b
			break
		}
	}
}

spawn_popup :: proc(x, y: f32, value: int) {
	for &p in &popups {
		if p.active do continue
		p.active = true
		p.x, p.y = x, y
		p.value = value
		p.life = POPUP_LIFE
		return
	}
}

start_shake :: proc(strength: f32) {
	shake_timer = SHAKE_TIME
	shake_strength = strength
}

// ---------------------------------------------------------------------------
// Per-frame updates
// ---------------------------------------------------------------------------

// THE pillar in code: every gem's visual position chases its logical cell.
// x eases exponentially (swaps/reverts); y either falls with gravity+bounce
// (cascades, refills) or eases (vertical swaps).
update_gems :: proc(dt: f32) {
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			g := &grid[col][row]
			if g.kind < 0 do continue
			tx := cell_px(col)
			ty := cell_py(row)

			g.vis_x += (tx - g.vis_x) * min(1, dt * LERP_SPEED)
			if abs(g.vis_x - tx) < 0.5 do g.vis_x = tx

			if g.falling {
				g.vy += FALL_GRAVITY * dt
				g.vis_y += g.vy * dt
				if g.vis_y >= ty {
					g.vis_y = ty
					if g.vy > BOUNCE_MIN_VEL {
						// little landing dust sells the bounce
						c := KIND_COLORS[g.kind]
						spawn_burst(g.vis_x + CELL/2, ty + CELL - 6, 3, c[0], c[1], c[2])
						g.vy = -g.vy * BOUNCE_DAMP
					} else {
						g.vy = 0
						g.falling = false
					}
				}
			} else {
				g.vis_y += (ty - g.vis_y) * min(1, dt * LERP_SPEED)
				if abs(g.vis_y - ty) < 0.5 do g.vis_y = ty
			}
		}
	}
}

// the board state machine. Note how every transition happens on SETTLED
// visuals, but reads/writes only the logic grid.
update_phase :: proc(dt: f32) {
	switch phase {
	case .idle:
		// waiting for clicks (handled in event)
	case .swapping:
		if gem_settled(swap_a.col, swap_a.row) && gem_settled(swap_b.col, swap_b.row) {
			if find_matches() > 0 {
				start_clear()
			} else {
				swap_gems(swap_a, swap_b) // no match: snap logic back...
				phase = .reverting        // ...and let the visuals chase it
			}
		}
	case .reverting:
		if gem_settled(swap_a.col, swap_a.row) && gem_settled(swap_b.col, swap_b.row) {
			phase = .idle
		}
	case .clearing:
		phase_timer -= dt
		if phase_timer <= 0 {
			finish_clear()
			apply_gravity()
			phase = .falling
		}
	case .falling:
		if all_settled() {
			if find_matches() > 0 {
				start_clear() // cascade! combo increments inside
			} else {
				combo = 0
				phase = .idle
			}
		}
	}
}

update_particles :: proc(dt: f32) {
	for &p in &particles {
		if !p.active do continue
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		p.vy += 700 * dt
		p.x += p.vx * dt
		p.y += p.vy * dt
	}
}

update_popups :: proc(dt: f32) {
	for &p in &popups {
		if !p.active do continue
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		p.y -= 26 * dt // rise
	}
}

// ---------------------------------------------------------------------------
// Drawing helpers (all sgl, all shapes — no textures, no fonts)
// ---------------------------------------------------------------------------

draw_rect_a :: proc(x, y, w, h: f32, r, g, b, a: f32) {
	sgl.begin_quads()
	sgl.v2f_c4f(x,     y,     r, g, b, a)
	sgl.v2f_c4f(x + w, y,     r, g, b, a)
	sgl.v2f_c4f(x + w, y + h, r, g, b, a)
	sgl.v2f_c4f(x,     y + h, r, g, b, a)
	sgl.end()
}

// thick line as a quad (for the combo "x" glyph)
draw_seg :: proc(x0, y0, x1, y1, th: f32, r, g, b, a: f32) {
	dx := x1 - x0
	dy := y1 - y0
	l := math.sqrt(dx*dx + dy*dy)
	if l < 0.001 {
		return
	}
	nx := -dy / l * th * 0.5
	ny := dx / l * th * 0.5
	sgl.begin_quads()
	sgl.v2f_c4f(x0 + nx, y0 + ny, r, g, b, a)
	sgl.v2f_c4f(x1 + nx, y1 + ny, r, g, b, a)
	sgl.v2f_c4f(x1 - nx, y1 - ny, r, g, b, a)
	sgl.v2f_c4f(x0 - nx, y0 - ny, r, g, b, a)
	sgl.end()
}

// 7-segment digit from plain rects. h = digit height.
draw_digit :: proc(x, y, h: f32, d: int, r, g, b, a: f32) {
	w := h * 0.55
	t := h * 0.14
	m := SEG_MASK[d]
	if m & 1  != 0 { draw_rect_a(x,         y,             w, t,   r, g, b, a) } // top
	if m & 2  != 0 { draw_rect_a(x + w - t, y,             t, h/2, r, g, b, a) } // top-right
	if m & 4  != 0 { draw_rect_a(x + w - t, y + h/2,       t, h/2, r, g, b, a) } // bottom-right
	if m & 8  != 0 { draw_rect_a(x,         y + h - t,     w, t,   r, g, b, a) } // bottom
	if m & 16 != 0 { draw_rect_a(x,         y + h/2,       t, h/2, r, g, b, a) } // bottom-left
	if m & 32 != 0 { draw_rect_a(x,         y,             t, h/2, r, g, b, a) } // top-left
	if m & 64 != 0 { draw_rect_a(x,         y + h/2 - t/2, w, t,   r, g, b, a) } // middle
}

digit_count :: proc(value: int) -> int {
	n := 1
	v := value / 10
	for v > 0 {
		n += 1
		v /= 10
	}
	return n
}

number_width :: proc(value: int, h: f32) -> f32 {
	adv := h*0.55 + h*0.25
	return f32(digit_count(value)) * adv - h * 0.25
}

draw_number :: proc(x, y, h: f32, value: int, r, g, b, a: f32) {
	digits: [12]int
	n := 0
	v := max(value, 0)
	if v == 0 {
		n = 1 // digits[0] already 0
	} else {
		for v > 0 {
			digits[n] = v % 10
			v /= 10
			n += 1
		}
	}
	adv := h*0.55 + h*0.25
	for i in 0 ..< n {
		draw_digit(x + f32(i)*adv, y, h, digits[n-1-i], r, g, b, a)
	}
}

draw_plus :: proc(x, y, h: f32, r, g, b, a: f32) {
	t := h * 0.14
	draw_rect_a(x, y + h*0.5 - t*0.5, h*0.5, t, r, g, b, a)
	draw_rect_a(x + h*0.25 - t*0.5, y + h*0.25, t, h*0.5, r, g, b, a)
}

// each kind gets a distinct SILHOUETTE, not just a color: regular polygon
// fan with a per-kind point count / rotation / inner radius (star).
gem_shape :: proc(kind: int) -> (n: int, rot: f32, inner: f32) {
	inner = 1
	switch kind {
	case 0:  n = 4;  rot = -math.PI / 2                // diamond
	case 1:  n = 18; rot = 0                           // circle
	case 2:  n = 4;  rot = math.PI / 4                 // square
	case 3:  n = 3;  rot = -math.PI / 2                // triangle
	case 4:  n = 6;  rot = math.PI / 6                 // hexagon
	case 5:  n = 10; rot = -math.PI / 2; inner = 0.5   // 5-point star
	case:    n = 4;  rot = 0
	}
	return
}

gem_point :: proc(i, n: int, rot, radius, inner: f32) -> (f32, f32) {
	a := rot + f32(i) / f32(n) * math.TAU
	r := radius
	if inner < 1 && i % 2 == 1 {
		r = radius * inner
	}
	return math.cos(a) * r, math.sin(a) * r
}

gem_fan :: proc(kind: int, cx, cy, radius: f32, r, g, b, a: f32) {
	n, rot, inner := gem_shape(kind)
	sgl.begin_triangles()
	for i in 0 ..< n {
		x0, y0 := gem_point(i, n, rot, radius, inner)
		x1, y1 := gem_point((i + 1) % n, n, rot, radius, inner)
		sgl.v2f_c4f(cx,      cy,      r, g, b, a)
		sgl.v2f_c4f(cx + x0, cy + y0, r, g, b, a)
		sgl.v2f_c4f(cx + x1, cy + y1, r, g, b, a)
	}
	sgl.end()
}

// shadow + body + brighter core + sparkle. whiten pushes toward white
// (used by the clear flash).
draw_gem :: proc(kind: int, cx, cy, radius, whiten, alpha: f32) {
	c := KIND_COLORS[kind]
	r := f32(c[0]) / 255.0
	g := f32(c[1]) / 255.0
	b := f32(c[2]) / 255.0
	r += (1 - r) * whiten
	g += (1 - g) * whiten
	b += (1 - b) * whiten
	gem_fan(kind, cx + 2, cy + 3, radius, 0, 0, 0, 0.30 * alpha)
	gem_fan(kind, cx, cy, radius, r, g, b, alpha)
	gem_fan(kind, cx, cy, radius * 0.55, min(1, r + 0.25), min(1, g + 0.25), min(1, b + 0.25), alpha)
	draw_rect_a(cx - radius*0.35, cy - radius*0.45, 3, 3, 1, 1, 1, 0.8 * alpha)
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x
		mouse_y = e.mouse_y
	case .MOUSE_DOWN:
		if e.mouse_button != .LEFT || phase != .idle {
			return
		}
		mx := e.mouse_x - BOARD_X
		my := e.mouse_y - BOARD_Y
		col := int(mx / CELL)
		row := int(my / CELL)
		if mx < 0 || my < 0 || col >= GRID || row >= GRID {
			sel_col, sel_row = -1, -1
			return
		}
		if sel_col < 0 {
			sel_col, sel_row = col, row
		} else if col == sel_col && row == sel_row {
			sel_col, sel_row = -1, -1 // click again = deselect
		} else if abs(col - sel_col) + abs(row - sel_row) == 1 {
			// adjacent: snap the LOGIC swap now; visuals glide after it.
			combo = 0
			swap_a = {sel_col, sel_row}
			swap_b = {col, row}
			swap_gems(swap_a, swap_b)
			phase = .swapping
			sel_col, sel_row = -1, -1
		} else {
			sel_col, sel_row = col, row // not adjacent: move selection
		}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .R:
			reset_board()
			fmt.println("board reshuffled. score reset.")
		}
	}
}

// ---------------------------------------------------------------------------
// Sokol lifecycle
// ---------------------------------------------------------------------------

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})

	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.04, g = 0.04, b = 0.09, a = 1}}},
	}

	// sgl pipeline with alpha blending: particles/popups fade, shadows tint.
	gem_pip = sgl.make_pipeline({
		colors = {0 = {blend = {
			enabled = true,
			src_factor_rgb = .SRC_ALPHA,
			dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
			src_factor_alpha = .ONE,
			dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		}}},
	})

	// fullscreen background quad: NDC position + uv, two triangles.
	fq := [?]f32{-1, -1, 0, 1, 1, -1, 1, 1, 1, 1, 1, 0, -1, -1, 0, 1, 1, 1, 1, 0, -1, 1, 0, 0}
	bg_vbuf = sg.make_buffer({data = {ptr = raw_data(fq[:]), size = size_of(fq)}})
	bg_shd := sg.make_shader({
		vertex_func = {source = BG_VS, entry = "_main"},
		fragment_func = {source = BG_FS, entry = "_main"},
		uniform_blocks = {0 = {stage = .FRAGMENT, size = u32(size_of(Bg_Params)), msl_buffer_n = 0}},
	})
	bg_pip = sg.make_pipeline({
		shader = bg_shd,
		layout = {attrs = {0 = {format = .FLOAT2}, 1 = {format = .FLOAT2}}},
	})

	reset_board()
	fmt.println("match-3 ready. click a gem, click a neighbor. R reshuffles.")
}

frame :: proc "c" () {
	context = rt_ctx
	dt := min(f32(sapp.frame_duration()), 0.05)
	t_now += dt

	update_gems(dt)
	update_phase(dt)
	update_particles(dt)
	update_popups(dt)

	// screen shake offset (t10 pattern: decaying strength, sin/cos wobble)
	shake_x, shake_y: f32
	if shake_timer > 0 {
		shake_timer -= dt
		k := shake_strength * (shake_timer / SHAKE_TIME)
		tt := t_now * 55
		shake_x = math.sin(tt * 1.1) * k
		shake_y = math.cos(tt * 1.7) * k * 0.7
	}

	sgl.defaults()
	sgl.load_pipeline(gem_pip)
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)
	sgl.matrix_mode_modelview()
	sgl.push_matrix()
	sgl.translate(shake_x, shake_y, 0)

	// --- board panel: checkered cells + frame -----------------------------
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			shade: f32 = 0.30 if (col+row) % 2 == 0 else 0.42
			draw_rect_a(cell_px(col), cell_py(row), CELL, CELL, 0.02, 0.02, 0.05, shade)
		}
	}
	bx := f32(BOARD_X)
	by := f32(BOARD_Y)
	bs := f32(GRID * CELL)
	draw_rect_a(bx - 3, by - 3, bs + 6, 3, 0.45, 0.40, 0.65, 0.9) // top
	draw_rect_a(bx - 3, by + bs, bs + 6, 3, 0.45, 0.40, 0.65, 0.9) // bottom
	draw_rect_a(bx - 3, by, 3, bs, 0.45, 0.40, 0.65, 0.9)          // left
	draw_rect_a(bx + bs, by, 3, bs, 0.45, 0.40, 0.65, 0.9)         // right

	// hover hint
	if phase == .idle {
		hc := int((mouse_x - BOARD_X) / CELL)
		hr := int((mouse_y - BOARD_Y) / CELL)
		if mouse_x >= BOARD_X && mouse_y >= BOARD_Y && hc < GRID && hr < GRID {
			draw_rect_a(cell_px(hc), cell_py(hr), CELL, CELL, 1, 1, 1, 0.06)
		}
	}

	// selection highlight: pulsing border
	if sel_col >= 0 {
		pulse := 0.45 + 0.30 * math.sin(t_now * 8)
		x := cell_px(sel_col)
		y := cell_py(sel_row)
		t := f32(3)
		draw_rect_a(x, y, CELL, t, 1, 1, 0.85, pulse)
		draw_rect_a(x, y + CELL - t, CELL, t, 1, 1, 0.85, pulse)
		draw_rect_a(x, y, t, CELL, 1, 1, 0.85, pulse)
		draw_rect_a(x + CELL - t, y, t, CELL, 1, 1, 0.85, pulse)
	}

	// --- gems --------------------------------------------------------------
	for col in 0 ..< GRID {
		for row in 0 ..< GRID {
			g := grid[col][row]
			if g.kind < 0 do continue
			cx := g.vis_x + CELL / 2
			cy := g.vis_y + CELL / 2
			radius := f32(CELL) * 0.36
			whiten := f32(0)
			alpha := f32(1)
			if g.clearing {
				// shrink + flash white + fade over CLEAR_TIME
				s := max(phase_timer, 0) / CLEAR_TIME // 1 -> 0
				radius *= 0.25 + 0.95 * s
				whiten = 1 - s
				alpha = 0.25 + 0.75 * s
			} else if col == sel_col && row == sel_row {
				radius *= 1 + 0.08 * math.sin(t_now * 10) // selected gem breathes
			}
			draw_gem(g.kind, cx, cy, radius, whiten, alpha)
		}
	}

	// --- particles (t10, in board space so they shake too) ------------------
	for p in particles {
		if !p.active do continue
		a := p.life / p.max_life
		size := p.size * (0.5 + a)
		draw_rect_a(p.x, p.y, size, size, f32(p.r)/255, f32(p.g)/255, f32(p.b)/255, a)
	}

	// --- score popups: "+NNN" in 7-segment rects, rising and fading ---------
	for p in popups {
		if !p.active do continue
		a := p.life / POPUP_LIFE
		h := f32(15)
		total := h*0.75 + number_width(p.value, h)
		sx := p.x - total / 2
		draw_plus(sx, p.y, h, 1, 0.95, 0.55, a)
		draw_number(sx + h*0.75, p.y, h, p.value, 1, 0.95, 0.55, a)
	}

	sgl.pop_matrix()

	// --- HUD (screen space, no shake) ---------------------------------------
	draw_number(16, 14, 20, score, 0.92, 0.92, 1, 0.95)
	if combo >= 2 {
		// "xN" pulses with the cascade
		h := 20 + 3*math.sin(t_now * 12)
		cx := f32(W - 110)
		draw_seg(cx, 16, cx + 13, 32, 4, 1, 0.75, 0.30, 1)
		draw_seg(cx + 13, 16, cx, 32, 4, 1, 0.75, 0.30, 1)
		draw_number(cx + 21, 14, h, combo, 1, 0.75, 0.30, 1)
	}

	// --- render: shader background first, then everything sgl on top --------
	bg_params := Bg_Params{time = t_now}
	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sg.apply_pipeline(bg_pip)
	sg.apply_bindings({vertex_buffers = {0 = bg_vbuf}})
	sg.apply_uniforms(0, {ptr = &bg_params, size = size_of(Bg_Params)})
	sg.draw(0, 6, 1)
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
		window_title = "P07 - Match-3 Juice",
		logger = {func = slog.func},
	})
}
