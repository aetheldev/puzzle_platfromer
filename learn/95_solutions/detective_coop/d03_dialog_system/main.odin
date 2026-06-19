/*
D03 — Branching Dialog System
=============================
A witness conversation as a DATA-DRIVEN graph of nodes. Each node has the
speaker's line + a list of choices; each choice routes to the next node and may
grant a clue. Some choices are GATED behind a clue you must already have.

READ THESE BLOCKS:
  - Node_Id / Choice / Node / NODES : the whole script as data
  - current / choose : the entire runtime engine (a few lines)
  - frame : draw line + visible (gated) choices as clickable rows

CONTROLS: left mouse = pick a choice ; number keys 1-4 also pick ; R = restart
*/

package d03_dialog_system

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

// clues the conversation can grant / gate on
Clue :: enum {
	none,
	alibi_shaky,
	saw_weapon,
	photo,
}
clues: [Clue]bool

CLUE_NAMES := [Clue]string {
	.none        = "",
	.alibi_shaky = "alibi shaky",
	.saw_weapon  = "saw weapon",
	.photo       = "photo",
}

has_clue :: proc(c: Clue) -> bool {return c == .none || clues[c]}
grant_clue :: proc(c: Clue) {
	if c != .none && !clues[c] {
		clues[c] = true
		fmt.println("[clue logged]", c)
	}
}

// --- dialog graph ---
Node_Id :: enum {
	start,
	ask_alibi,
	ask_weapon,
	accuse,
	end,
}

Choice :: struct {
	text:       string,
	next:       Node_Id,
	gives:      Clue,
	needs_clue: Clue, // .none = always shown
}

Node :: struct {
	speaker_line: string,
	choices:      []Choice,
}

NODES := [Node_Id]Node {
	.start = {
		"Witness: I already told the other officer everything.",
		[]Choice{
			{"Where were you at 9pm?", .ask_alibi, .none, .none},
			{"Did you see the weapon?", .ask_weapon, .none, .none},
			{"[Show the photo] Recognize this?", .accuse, .none, .photo},
			{"That's all for now.", .end, .none, .none},
		},
	},
	.ask_alibi = {
		"Witness: I was... home. Alone. All night. Why?",
		[]Choice{
			{"\"Alone\" - no one to confirm that? (note it)", .start, .alibi_shaky, .none},
			{"Back.", .start, .none, .none},
		},
	},
	.ask_weapon = {
		"Witness: There was a knife on the table. I saw it, yes.",
		[]Choice{
			{"You're sure it was a knife? (note it)", .start, .saw_weapon, .none},
			{"Back.", .start, .none, .none},
		},
	},
	.accuse = {
		"Witness: ...Where did you get that photo?",
		[]Choice{
			{"It places you at the scene. Talk.", .end, .none, .none},
			{"Never mind. Back.", .start, .none, .none},
		},
	},
	.end = {"Witness: This conversation is over, detective.", []Choice{}},
}

current: Node_Id = .start

choose :: proc(c: Choice) {
	grant_clue(c.gives)
	current = c.next
}

mouse_x, mouse_y: f32
clicked: bool
choice_key: int = -1 // 0..3 from number keys
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

// build the list of currently-visible choices (gating applied)
visible_choices :: proc(out: ^[dynamic]Choice) {
	clear(out)
	for c in NODES[current].choices {
		if has_clue(c.needs_clue) {append(out, c)}
	}
}

CHOICE_H :: f32(40)
choice_rect :: proc(i: int) -> Rect {
	return {60, 300 + f32(i) * (CHOICE_H + 10), W - 120, CHOICE_H}
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
		case .R:
			current = .start;clues = {};fmt.println("(restart)")
		case ._1:
			choice_key = 0
		case ._2:
			choice_key = 1
		case ._3:
			choice_key = 2
		case ._4:
			choice_key = 3
		// the witness also gives you the photo at start so you can test gating
		case .P:
			grant_clue(.photo)
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
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.06, g = 0.07, b = 0.11, a = 1}}},
	}
	fmt.println("Talk to the witness. Click a reply (or 1-4). Press P to 'have the photo'.")
}

vis: [dynamic]Choice

frame :: proc "c" () {
	context = rt_ctx
	visible_choices(&vis)

	// resolve input -> a chosen index
	chosen := -1
	if clicked {
		clicked = false
		for i in 0 ..< len(vis) {
			if point_in_rect(mouse_x, mouse_y, choice_rect(i)) {chosen = i;break}
		}
	}
	if choice_key >= 0 {
		if choice_key < len(vis) {chosen = choice_key}
		choice_key = -1
	}
	if chosen >= 0 {choose(vis[chosen]);visible_choices(&vis)}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// speaker panel (top)
	draw_rect({40, 60, W - 80, 180}, 26, 28, 38)
	draw_outline({40, 60, W - 80, 180}, 70, 80, 110)
	// (text is logged to console; on-screen we use a colored speaker bar)
	draw_rect({60, 80, 200, 24}, 150, 170, 210)

	// choices
	for i in 0 ..< len(vis) {
		r := choice_rect(i)
		hot := point_in_rect(mouse_x, mouse_y, r)
		draw_rect(r, hot ? 50 : 34, hot ? 56 : 38, hot ? 70 : 48)
		draw_outline(r, 120, 130, 160)
		// a little tag if this choice grants a clue
		if vis[i].gives != .none {draw_rect({r.x + r.w - 28, r.y + 8, 16, 16}, 90, 200, 110)}
	}

	// clue tray (bottom) so you SEE what you've logged
	idx := 0
	for c in Clue {
		if c == .none {continue}
		on := clues[c]
		draw_rect({12 + f32(idx) * 40, H - 36, 30, 24}, on ? 90 : 40, on ? 200 : 44, on ? 110 : 52)
		idx += 1
	}

	// --- on-screen text overlay ---
	sdtx.canvas(W, H)
	label(20, 16, 200, 210, 240, "D03 - Branching Dialog")
	label(20, 36, 130, 140, 170, "Click a reply or press 1-4.  P = pretend you have the photo.  R = restart.")

	// witness's current line, inside the speaker panel
	label(60, 90, 210, 220, 240, NODES[current].speaker_line)

	// each visible choice's text, inside its row
	for i in 0 ..< len(vis) {
		r := choice_rect(i)
		txt := fmt.tprintf("%d. %s", i + 1, vis[i].text)
		if vis[i].gives != .none {txt = fmt.tprintf("%s (+clue)", txt)}
		label(r.x + 10, r.y + 12, 220, 225, 235, txt)
	}

	// clue tray labels (above each tick)
	tidx := 0
	for c in Clue {
		if c == .none {continue}
		if clues[c] {
			label(12 + f32(tidx) * 40, H - 52, 130, 220, 150, CLUE_NAMES[c])
		}
		tidx += 1
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
		width = W, height = H, window_title = "D03 — Branching Dialog",
		logger = {func = slog.func},
	})
}
