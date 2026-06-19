/*
D05 — Clues & Deduction
=======================
Turn clues into conclusions with a DATA-DRIVEN rule system built on bit_set
(see o19). A deduction is "these required clues (and none of the forbidden
ones) => this conclusion". The player toggles pinned clues into a working set
and presses Deduce.

READ THESE BLOCKS:
  - Conclusion / Deduction / DEDUCTIONS : rules as data
  - selected : bit_set[Clue] + toggle logic
  - try_deduce : the set-algebra engine (subset + intersection)
  - frame : clue chips (click to toggle) + Deduce button + reached list

CONTROLS: left mouse = toggle clue chip / press Deduce ; R = reset
*/

package d05_clues_deduction

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

Rect :: struct {
	x, y, w, h: f32,
}
point_in_rect :: proc(px, py: f32, r: Rect) -> bool {
	return px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h
}

Clue :: enum {
	shaky_alibi,
	knife_weapon,
	photo_address,
	muddy_boots,
	clean_hands, // a red herring
}
CLUE_NAMES := [Clue]string {
	.shaky_alibi   = "shaky alibi",
	.knife_weapon  = "knife weapon",
	.photo_address = "photo address",
	.muddy_boots   = "muddy boots",
	.clean_hands   = "clean hands",
}

Conclusion :: enum {
	none,
	suspect_lied,
	weapon_is_knife,
	killer_identified,
}
CONCL_NAMES := [Conclusion]string {
	.none              = "",
	.suspect_lied      = "Suspect lied about the alibi",
	.weapon_is_knife   = "Weapon was the knife",
	.killer_identified = "Killer identified",
}

Deduction :: struct {
	needs:   bit_set[Clue],
	yields:  Conclusion,
	forbids: bit_set[Clue],
}

DEDUCTIONS := []Deduction {
	{{.shaky_alibi, .photo_address}, .suspect_lied, {}},
	{{.knife_weapon}, .weapon_is_knife, {}},
	// killer needs three clues AND must NOT include the red herring
	{{.shaky_alibi, .photo_address, .muddy_boots}, .killer_identified, {.clean_hands}},
}

try_deduce :: proc(sel: bit_set[Clue]) -> (Conclusion, bool) {
	for d in DEDUCTIONS {
		if (d.needs & sel) == d.needs && (d.forbids & sel) == {} {
			return d.yields, true
		}
	}
	return .none, false
}

// in d06 these come from the notebook's pinned clues; here all are available
available: bit_set[Clue] = {.shaky_alibi, .knife_weapon, .photo_address, .muddy_boots, .clean_hands}
selected: bit_set[Clue]
reached: [Conclusion]bool
wrong_guesses: int

mouse_x, mouse_y: f32
clicked: bool
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

reset_all :: proc() {
	selected = {}
	reached = {}
	wrong_guesses = 0
	fmt.println("(reset)")
}

CHIP_W :: f32(150)
CHIP_H :: f32(40)
chip_rect :: proc(i: int) -> Rect {
	col := i % 3
	row := i / 3
	return {60 + f32(col) * (CHIP_W + 12), 120 + f32(row) * (CHIP_H + 12), CHIP_W, CHIP_H}
}
DEDUCE_BTN :: Rect{W - 220, H - 90, 160, 50}

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

do_deduce :: proc() {
	if concl, ok := try_deduce(selected); ok && !reached[concl] {
		reached[concl] = true
		fmt.println("DEDUCED:", CONCL_NAMES[concl])
		selected = {}
	} else if ok {
		fmt.println("You already concluded that.")
	} else {
		wrong_guesses += 1
		fmt.println("That doesn't add up.", wrong_guesses == 3 ? "(maybe a clue is a red herring?)" : "")
	}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x;mouse_y = e.mouse_y
	case .MOUSE_DOWN:
		if e.mouse_button == .LEFT {clicked = true}
	case .KEY_DOWN:
		if e.key_code == .R {reset_all()}
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
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.07, g = 0.08, b = 0.11, a = 1}}},
	}
	fmt.println("Toggle clue chips, press Deduce. Find all 3 conclusions.")
}

frame :: proc "c" () {
	context = rt_ctx

	if clicked {
		clicked = false
		// chip toggles
		i := 0
		for c in Clue {
			if c not_in available {continue}
			if point_in_rect(mouse_x, mouse_y, chip_rect(i)) {
				if c in selected {selected -= {c}} else {selected += {c}}
			}
			i += 1
		}
		// deduce button
		if point_in_rect(mouse_x, mouse_y, DEDUCE_BTN) {do_deduce()}
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	draw_rect({0, 0, W, H}, 40, 42, 52)

	// clue chips
	i := 0
	for c in Clue {
		if c not_in available {continue}
		r := chip_rect(i)
		on := c in selected
		draw_rect(r, on ? 70 : 36, on ? 110 : 40, on ? 150 : 52)
		draw_outline(r, on ? 120 : 90, on ? 180 : 100, on ? 240 : 130)
		i += 1
	}

	// deduce button
	hot := point_in_rect(mouse_x, mouse_y, DEDUCE_BTN)
	draw_rect(DEDUCE_BTN, hot ? 90 : 60, hot ? 160 : 110, hot ? 120 : 80)
	draw_outline(DEDUCE_BTN, 140, 220, 160)

	// reached conclusions (green ticks down the right)
	idx := 0
	for cc in Conclusion {
		if cc == .none {continue}
		on := reached[cc]
		draw_rect({W - 260, 120 + f32(idx) * 40, 30, 26}, on ? 90 : 40, on ? 200 : 44, on ? 110 : 52)
		idx += 1
	}

	// text overlay
	sdtx.canvas(W, H)
	label(20, 24, 220, 220, 230, "D05 - Clues & Deduction")
	label(20, 60, 150, 160, 180, "Click clue chips to toggle, then click Deduce. Find all conclusions. R = reset")

	ti := 0
	for c in Clue {
		if c not_in available {continue}
		cr := chip_rect(ti)
		label(cr.x + 8, cr.y + 14, 220, 230, 240, CLUE_NAMES[c])
		ti += 1
	}

	label(DEDUCE_BTN.x + 30, DEDUCE_BTN.y + 16, 220, 255, 220, "DEDUCE")

	cidx := 0
	for cc in Conclusion {
		if cc == .none {continue}
		on := reached[cc]
		label(W - 220, 124 + f32(cidx) * 40, on ? 120 : 90, on ? 220 : 100, on ? 140 : 110, CONCL_NAMES[cc])
		cidx += 1
	}

	label(20, H - 30, 220, 150, 150, fmt.tprintf("wrong: %d", wrong_guesses))

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
		width = W, height = H, window_title = "D05 — Clues & Deduction",
		logger = {func = slog.func},
	})
}
