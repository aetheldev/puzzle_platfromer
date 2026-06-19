/*
D06 — Two-Detective Co-op Case (capstone)
=========================================
Single screen, split-role, local co-op. Wires together d01-d05:
  FIELD (Detective A, MOUSE, left half) : crime scene, pick up + inspect
        evidence -> discover() clues.
  DESK  (Detective B, KEYBOARD, right half) : notebook of discovered clues +
        bit_set deduction (d05). The final deduction NEEDS a clue only A can
        find -> forced co-op.

Every action is an Intent {who, action, target} so this is networking-ready
(see d06 LESSON exercise 4 and learn/85_networking).

READ THESE BLOCKS:
  - Role / Action / Intent : the action model
  - event : mouse -> field (left), keys -> desk (right)
  - field side : hotspots, pickups, inspect -> discover()
  - desk side  : clue chips (discovered only), try_deduce, win
  - frame : screen split + "tell your partner" nudge

CONTROLS:
  A (mouse, LEFT half) : click evidence to collect; right-click a slot to
                         inspect; click the photo detail to reveal its clue.
  B (keys, RIGHT half) : 1-4 toggle a discovered clue, SPACE = Deduce.
  R = reset
*/

package d06_two_detective_coop

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sdtx  "../../../../sauce/sokol/debugtext" // on-screen text labels
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"

W :: 960
H :: 540
HALF :: f32(W) / 2

Rect :: struct {
	x, y, w, h: f32,
}
point_in_rect :: proc(px, py: f32, r: Rect) -> bool {
	return px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h
}

// --- action model (networking-ready) ---
Role :: enum {
	field,
	desk,
}
Action :: enum {
	pick,
	inspect,
	toggle_clue,
	deduce,
}
Intent :: struct {
	who:    Role,
	action: Action,
	target: int,
}

// --- evidence / clues ---
Item :: enum {
	none,
	torn_photo,
	tape,
	bloody_knife,
}
ITEM_COLORS := [Item][3]u8 {
	.none         = {0, 0, 0},
	.torn_photo   = {200, 170, 160},
	.tape         = {220, 220, 120},
	.bloody_knife = {200, 70, 70},
}
ITEM_NAMES := [Item]string {
	.none         = "",
	.torn_photo   = "torn photo",
	.tape         = "tape",
	.bloody_knife = "bloody knife",
}

Clue :: enum {
	knife_weapon,
	photo_address,
	shaky_alibi,
}
CLUE_NAMES := [Clue]string {
	.knife_weapon  = "knife = weapon",
	.photo_address = "photo address",
	.shaky_alibi   = "shaky alibi",
}
clues_found: bit_set[Clue]

discover :: proc(c: Clue) {
	if c not_in clues_found {
		clues_found += {c}
		nudge_timer = 2.5 // "tell your partner!"
		fmt.println("[A found a clue]", c, " -> TELL YOUR PARTNER")
	}
}

// --- deduction (d05) ; the killer rule needs photo_address (A-only) ---
Conclusion :: enum {
	none,
	killer_identified,
}
CONCL_NAMES := [Conclusion]string {
	.none              = "",
	.killer_identified = "KILLER IDENTIFIED",
}
Deduction :: struct {
	needs:  bit_set[Clue],
	yields: Conclusion,
}
DEDUCTIONS := []Deduction{{{.knife_weapon, .photo_address, .shaky_alibi}, .killer_identified}}
try_deduce :: proc(sel: bit_set[Clue]) -> (Conclusion, bool) {
	for d in DEDUCTIONS {
		if (d.needs & sel) == d.needs {return d.yields, true}
	}
	return .none, false
}

// --- FIELD state (A) ---
Hotspot_Id :: enum {
	photo,
	tape,
	knife,
}
HOTSPOTS := [Hotspot_Id]Rect {
	.photo = {80, 140, 80, 60},
	.tape  = {180, 360, 60, 40},
	.knife = {300, 300, 70, 24},
}
HOTSPOT_ITEM := [Hotspot_Id]Item {
	.photo = .torn_photo,
	.tape  = .tape,
	.knife = .bloody_knife,
}
taken: [Item]bool
inventory: [dynamic]Item
inspect_mode: bool
inspecting: Item
photo_detail_found: bool

// --- DESK state (B) ---
selected: bit_set[Clue]
reached: [Conclusion]bool

// shared
State :: enum {
	playing,
	solved,
}
state: State
nudge_timer: f32
mouse_x, mouse_y: f32
clicked_l, clicked_r: bool
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

reset_all :: proc() {
	clues_found = {}
	taken = {}
	clear(&inventory)
	inspect_mode = false
	photo_detail_found = false
	selected = {}
	reached = {}
	state = .playing
	nudge_timer = 0
	fmt.println("(case reset)")
}

// ---- FIELD (A) input ----
INSPECT_DETAIL :: Rect{HALF / 2 - 30, 360, 60, 24}
SLOT :: f32(40)
slot_rect :: proc(i: int) -> Rect {return {12 + f32(i) * (SLOT + 6), H - SLOT - 10, SLOT, SLOT}}

field_pick :: proc() {
	ids := [?]Hotspot_Id{.knife, .tape, .photo}
	for id in ids {
		if !taken[HOTSPOT_ITEM[id]] && point_in_rect(mouse_x, mouse_y, HOTSPOTS[id]) {
			it := HOTSPOT_ITEM[id]
			taken[it] = true
			append(&inventory, it)
			// some pickups are immediately a clue
			if it == .bloody_knife {discover(.knife_weapon)}
			fmt.println("[A] collected", it)
			return
		}
	}
}

field_inspect_slot :: proc() {
	for it, i in inventory {
		if point_in_rect(mouse_x, mouse_y, slot_rect(i)) {
			inspect_mode = true
			inspecting = it
			fmt.println("[A] inspecting", it)
			return
		}
	}
}

field_click_l :: proc() {
	if inspect_mode {
		// clicking the photo's detail reveals the address clue (A-only)
		if inspecting == .torn_photo && point_in_rect(mouse_x, mouse_y, INSPECT_DETAIL) {
			photo_detail_found = true
			discover(.photo_address)
		} else {
			inspect_mode = false
		}
		return
	}
	field_pick()
}

// ---- DESK (B) input ----
clue_for_key :: proc(n: int) -> (Clue, bool) {
	switch n {
	case 0:
		return .knife_weapon, true
	case 1:
		return .photo_address, true
	case 2:
		return .shaky_alibi, true
	}
	return .knife_weapon, false
}

desk_toggle :: proc(n: int) {
	if c, ok := clue_for_key(n); ok {
		if c not_in clues_found {
			fmt.println("[B] that clue isn't in the notebook yet - ask A!")
			return
		}
		if c in selected {selected -= {c}} else {selected += {c}}
	}
}

desk_deduce :: proc() {
	if concl, ok := try_deduce(selected); ok {
		reached[concl] = true
		if concl == .killer_identified {
			state = .solved
			fmt.println("CASE SOLVED. Both detectives cracked it.")
		}
	} else {
		fmt.println("[B] not enough to conclude. What else did A find?")
	}
}

draw_rect :: proc(r: Rect, cr, cg, cb: u8) {
	sgl.begin_quads()
	sgl.c3f(f32(cr) / 255, f32(cg) / 255, f32(cb) / 255)
	sgl.v2f(r.x, r.y);sgl.v2f(r.x + r.w, r.y)
	sgl.v2f(r.x + r.w, r.y + r.h);sgl.v2f(r.x, r.y + r.h)
	sgl.end()
}
draw_outline :: proc(r: Rect, cr, cg, cb: u8) {
	sgl.begin_line_strip()
	sgl.c3f(f32(cr) / 255, f32(cg) / 255, f32(cb) / 255)
	sgl.v2f(r.x, r.y);sgl.v2f(r.x + r.w, r.y);sgl.v2f(r.x + r.w, r.y + r.h)
	sgl.v2f(r.x, r.y + r.h);sgl.v2f(r.x, r.y)
	sgl.end()
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x;mouse_y = e.mouse_y
	case .MOUSE_DOWN:
		// A only acts on the LEFT half (the field)
		if mouse_x < HALF || inspect_mode {
			if e.mouse_button == .LEFT {clicked_l = true}
			if e.mouse_button == .RIGHT {clicked_r = true}
		}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .R:
			reset_all()
		case ._1:
			desk_toggle(0)
		case ._2:
			desk_toggle(1)
		case ._3:
			desk_toggle(2)
		case .SPACE:
			desk_deduce()
		}
	}
}

label :: proc(px, py: f32, r, g, b: u8, str: string) {
	sdtx.font(0)
	sdtx.color3b(r, g, b)
	sdtx.pos(px / 8, py / 8)
	sdtx.printf("%s", str)
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	d: sdtx.Desc
	d.fonts[0] = sdtx.font_kc853()
	d.logger = {func = slog.func}
	sdtx.setup(d)
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.05, g = 0.06, b = 0.09, a = 1}}},
	}
	// Detective B starts knowing the alibi from an off-screen interview.
	clues_found += {.shaky_alibi}
	fmt.println("A (mouse, left) works the scene. B (1-3 + SPACE) deduces. Solve together.")
}

frame :: proc "c" () {
	context = rt_ctx
	dt := f32(sapp.frame_duration())
	if nudge_timer > 0 {nudge_timer -= dt}

	if clicked_l {clicked_l = false;field_click_l()}
	if clicked_r {clicked_r = false;if !inspect_mode {field_inspect_slot()}}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// ---- FIELD panel (left) ----
	draw_rect({0, 0, HALF, H}, 50, 46, 54)
	draw_rect({0, H - 70, HALF, 70}, 34, 30, 30) // floor/inventory band

	if inspect_mode {
		draw_rect({0, 0, HALF, H}, 16, 16, 22)
		c := ITEM_COLORS[inspecting]
		draw_rect({HALF / 2 - 80, 120, 160, 160}, c[0], c[1], c[2])
		if inspecting == .torn_photo {
			draw_rect(INSPECT_DETAIL, photo_detail_found ? 90 : 150, photo_detail_found ? 200 : 150, 110)
			draw_outline(INSPECT_DETAIL, 240, 220, 90)
		}
	} else {
		for id in Hotspot_Id {
			if !taken[HOTSPOT_ITEM[id]] {
				cc := ITEM_COLORS[HOTSPOT_ITEM[id]]
				draw_rect(HOTSPOTS[id], cc[0], cc[1], cc[2])
			}
		}
		// hover
		for id in Hotspot_Id {
			if !taken[HOTSPOT_ITEM[id]] && point_in_rect(mouse_x, mouse_y, HOTSPOTS[id]) {
				draw_outline(HOTSPOTS[id], 240, 220, 90)
			}
		}
		for it, i in inventory {
			r := slot_rect(i)
			draw_rect(r, 28, 30, 38)
			c := ITEM_COLORS[it]
			draw_rect({r.x + 5, r.y + 5, SLOT - 10, SLOT - 10}, c[0], c[1], c[2])
		}
	}

	// ---- divider ----
	draw_rect({HALF - 2, 0, 4, H}, 20, 20, 26)

	// ---- DESK panel (right) ----
	draw_rect({HALF, 0, HALF, H}, 28, 30, 40)
	// clue chips (only discovered ones are bright/usable)
	chip_order := [?]Clue{.knife_weapon, .photo_address, .shaky_alibi}
	for c, i in chip_order {
		r := Rect{HALF + 40, 90 + f32(i) * 56, HALF - 100, 44}
		found := c in clues_found
		sel := c in selected
		if !found {
			draw_rect(r, 30, 30, 36) // locked/unknown
			draw_outline(r, 60, 60, 70)
		} else {
			draw_rect(r, sel ? 70 : 40, sel ? 110 : 46, sel ? 150 : 58)
			draw_outline(r, sel ? 120 : 90, sel ? 180 : 100, sel ? 240 : 130)
		}
	}
	// deduce hint button
	draw_rect({HALF + 40, H - 90, 160, 44}, 60, 110, 80)
	draw_outline({HALF + 40, H - 90, 160, 44}, 140, 220, 160)

	// win banner
	if state == .solved {
		draw_rect({HALF + 30, 300, HALF - 60, 60}, 60, 180, 90)
		draw_outline({HALF + 30, 300, HALF - 60, 60}, 150, 240, 170)
	}

	// "tell your partner" nudge across the top
	if nudge_timer > 0 {
		draw_rect({HALF / 2 - 120, 30, 240, 26}, 220, 180, 70)
	}

	// ---- text overlay ----
	sdtx.canvas(W, H)
	// panel headers
	label(12, 10, 230, 220, 180, "FIELD - Detective A (mouse)")
	label(HALF + 12, 10, 200, 220, 240, "DESK - Detective B (keys)")

	// FIELD side
	if !inspect_mode {
		for id in Hotspot_Id {
			if !taken[HOTSPOT_ITEM[id]] {
				r := HOTSPOTS[id]
				label(r.x, r.y - 14, 240, 230, 180, ITEM_NAMES[HOTSPOT_ITEM[id]])
			}
		}
		for it, i in inventory {
			r := slot_rect(i)
			label(r.x, r.y - 14, 200, 210, 230, ITEM_NAMES[it])
		}
		label(12, H - 90, 150, 150, 160, "click evidence to collect, right-click a slot to inspect")
	} else {
		label(HALF / 2 - 50, 100, 240, 230, 180, ITEM_NAMES[inspecting])
		if inspecting == .torn_photo {
			label(INSPECT_DETAIL.x, INSPECT_DETAIL.y - 14, 240, 220, 90, "[back]")
			if photo_detail_found {
				label(HALF / 2 - 50, 310, 120, 240, 140, "found: address!")
			}
		}
		label(HALF / 2 - 80, 470, 150, 150, 160, "click detail / click away to exit")
	}

	// DESK side
	for c, i in chip_order {
		r := Rect{HALF + 40, 90 + f32(i) * 56, HALF - 100, 44}
		if c in clues_found {
			txt := CLUE_NAMES[c]
			if c in selected {txt = fmt.tprintf("%s [x]", CLUE_NAMES[c])}
			label(r.x + 8, r.y + 14, 210, 230, 250, txt)
		} else {
			label(r.x + 8, r.y + 14, 110, 110, 120, "??? (ask A)")
		}
	}
	label(HALF + 50, H - 90 + 14, 200, 240, 200, "DEDUCE (Space)")
	label(HALF + 40, H - 40, 150, 150, 160, "1-3 toggle clue, Space = deduce")

	if nudge_timer > 0 {
		label(HALF / 2 - 90, 36, 255, 230, 70, "TELL YOUR PARTNER!")
	}

	if state == .solved {
		label(HALF + 60, 320, 120, 240, 150, "CASE SOLVED!")
		label(HALF + 60, 340, 200, 240, 180, CONCL_NAMES[.killer_identified])
	}

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()
	sdtx.draw()
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	sdtx.shutdown()
	sgl.shutdown()
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run({
		init_cb = init, frame_cb = frame, event_cb = event, cleanup_cb = cleanup,
		width = W, height = H, window_title = "D06 — Two-Detective Co-op Case",
		logger = {func = slog.func},
	})
}
