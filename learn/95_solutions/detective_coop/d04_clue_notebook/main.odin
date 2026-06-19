/*
D04 — Clue Notebook
===================
A shared notebook: a fixed CATALOG of all clues (data) + per-clue flags for
"discovered" and "pinned". d02 inspect and d03 dialog both feed it through ONE
function: discover(). The notebook lists discovered clues, opens their body,
and lets you pin clues for the d05 deduction step.

READ THESE BLOCKS:
  - Clue / Clue_Entry / CLUES / discovered / pinned : catalog + flags
  - discover() : the single entry point for finding a clue
  - frame : TAB toggles notebook; list only discovered; click row = open body;
            click pin box = toggle pinned

CONTROLS:
  TAB        = open/close notebook
  1-4        = (demo) discover a clue, simulating d02/d03 feeding it
  left mouse = open an entry / toggle its pin
  R          = reset
*/

package d04_clue_notebook

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
	none,
	shaky_alibi,
	knife_weapon,
	photo_address,
	muddy_boots,
}

Clue_Entry :: struct {
	title: string,
	body:  string,
}

CLUES := [Clue]Clue_Entry {
	.none          = {"", ""},
	.shaky_alibi   = {"Shaky alibi", "Witness claims he was home alone all night. Nobody can confirm."},
	.knife_weapon  = {"The weapon", "Witness admits there was a knife on the table."},
	.photo_address = {"Photo address", "The repaired photo has an address written on the back."},
	.muddy_boots   = {"Muddy boots", "Boots by the door are caked with red clay - like the alley."},
}

discovered: [Clue]bool
pinned: [Clue]bool

// THE single entry point: d02 inspect + d03 dialog both call this.
discover :: proc(c: Clue) {
	if c != .none && !discovered[c] {
		discovered[c] = true
		fmt.println("[notebook] new clue:", CLUES[c].title)
	}
}

notebook_open: bool
opened_clue: Clue = .none

mouse_x, mouse_y: f32
clicked: bool
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

reset_all :: proc() {
	discovered = {}
	pinned = {}
	opened_clue = .none
	notebook_open = false
	fmt.println("(reset)")
}

// rows: list only discovered clues in enum order
ROW_H :: f32(44)
row_rect :: proc(i: int) -> Rect {return {60, 110 + f32(i) * (ROW_H + 8), 360, ROW_H}}
pin_rect :: proc(i: int) -> Rect {
	r := row_rect(i)
	return {r.x + r.w - 34, r.y + 8, 26, 26}
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
		if e.mouse_button == .LEFT {clicked = true}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .TAB:
			notebook_open = !notebook_open
		case .R:
			reset_all()
		case ._1:
			discover(.shaky_alibi)
		case ._2:
			discover(.knife_weapon)
		case ._3:
			discover(.photo_address)
		case ._4:
			discover(.muddy_boots)
		}
	}
}

label :: proc(px, py: f32, r, g, b: u8, str: string) {
	sdtx.font(0)
	sdtx.color3b(r, g, b)
	sdtx.pos(px / 8, py / 8)
	sdtx.printf("%s", str)
}

// draw a long string wrapped to `cols` characters per line, starting at (px,py)
label_wrap :: proc(px, py: f32, r, g, b: u8, str: string, cols: int) {
	sdtx.font(0)
	sdtx.color3b(r, g, b)
	line_y := py
	start := 0
	for start < len(str) {
		end := start + cols
		if end > len(str) { end = len(str) }
		sdtx.pos(px / 8, line_y / 8)
		sdtx.printf("%s", str[start:end])
		line_y += 12
		start = end
	}
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
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.06, g = 0.07, b = 0.10, a = 1}}},
	}
	fmt.println("Press 1-4 to find clues, TAB to open the notebook, click to open/pin.")
}

frame :: proc "c" () {
	context = rt_ctx

	if clicked && notebook_open {
		clicked = false
		i := 0
		for c in Clue {
			if c == .none || !discovered[c] {continue}
			if point_in_rect(mouse_x, mouse_y, pin_rect(i)) {
				pinned[c] = !pinned[c]
			} else if point_in_rect(mouse_x, mouse_y, row_rect(i)) {
				opened_clue = c
			}
			i += 1
		}
	} else if clicked {
		clicked = false
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// a plain scene placeholder
	draw_rect({0, 0, W, H}, 40, 38, 46)

	// badge: clues found
	found := 0
	for c in Clue {if c != .none && discovered[c] {found += 1}}
	draw_rect({W - 60, 16, f32(found) * 12 + 4, 16}, 90, 200, 110)

	if notebook_open {
		// notebook panel
		draw_rect({40, 60, W - 80, H - 120}, 24, 24, 30)
		draw_outline({40, 60, W - 80, H - 120}, 90, 90, 120)

		// entry list (discovered only)
		i := 0
		for c in Clue {
			if c == .none || !discovered[c] {continue}
			r := row_rect(i)
			sel := (c == opened_clue)
			draw_rect(r, sel ? 50 : 34, sel ? 56 : 38, sel ? 70 : 48)
			draw_outline(r, 110, 120, 150)
			// pin box (green when pinned)
			pr := pin_rect(i)
			draw_rect(pr, pinned[c] ? 90 : 50, pinned[c] ? 200 : 52, pinned[c] ? 110 : 60)
			i += 1
		}

		// opened entry body panel (right side)
		if opened_clue != .none {
			draw_rect({460, 110, 440, 200}, 30, 32, 42)
			draw_outline({460, 110, 440, 200}, 120, 130, 160)
			draw_rect({476, 126, 180, 20}, 150, 170, 210) // title bar placeholder
		}
	}

	// --- on-screen text overlay ---
	sdtx.canvas(W, H)
	label(16, 16, 230, 230, 240, "D04 - Clue Notebook")
	label(16, 32, 150, 160, 190, "1-4 = find a clue   TAB = open/close notebook   click row = open, click box = pin   R = reset")
	label(W - 58, 18, 20, 30, 20, fmt.tprintf("clues: %d", found))

	if notebook_open {
		label(60, 78, 200, 210, 230, "NOTEBOOK")
		ti := 0
		for c in Clue {
			if c == .none || !discovered[c] {continue}
			rr := row_rect(ti)
			label(rr.x + 10, rr.y + 14, 230, 230, 240, CLUES[c].title)
			pr := pin_rect(ti)
			label(pr.x - 30, pr.y + 8, 200, 210, 230, pinned[c] ? "PINNED" : "PIN")
			ti += 1
		}

		if opened_clue != .none {
			label(476, 126, 20, 20, 30, CLUES[opened_clue].title)
			label_wrap(476, 160, 220, 225, 235, CLUES[opened_clue].body, 52)
		}
	} else {
		label(W / 2 - 110, H / 2, 200, 200, 160, "Press TAB to open the notebook")
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
		width = W, height = H, window_title = "D04 — Clue Notebook",
		logger = {func = slog.func},
	})
}
