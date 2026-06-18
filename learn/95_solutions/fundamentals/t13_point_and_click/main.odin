// TICKET 13 - Point And Click
// ===========================
// GOAL: A one-room Rusty-Lake-style escape scene. Click objects to
//       inspect, collect, combine, and solve a color-code door.
//
// WHAT THIS TEACHES:
//   - Hit-testing: point-in-rect (the heart of every point-and-click)
//   - Hotspots as data (array of clickable regions)
//   - Game state as flags driving what is visible/clickable
//   - A one-slot inventory ("selected item")
//   - Win condition from an ordered sequence
//
// THE ROOM:
//   - A painting. Click it -> it slides aside, revealing a key.
//   - The key. Click it -> goes to your "hand" (inventory).
//   - A drawer. Locked. Click with key in hand -> opens, shows the
//     color code: the note inside displays three colored squares.
//   - The door has three buttons (red, green, blue). Press them in
//     the order the note shows -> door opens. Walk free.
//
// CONTROLS:
//   - Left mouse: interact
//   - R: reset room

package t13

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
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

// --- Hotspots: clickable things, as data ---
Hotspot_Id :: enum {
	painting,
	key,
	drawer,
	btn_red,
	btn_green,
	btn_blue,
	door,
}

HOTSPOTS := [Hotspot_Id]Rect{
	.painting  = {120, 120, 140, 110},
	.key       = {150, 250, 60, 26},   // hidden behind painting
	.drawer    = {380, 330, 150, 90},
	.btn_red   = {660, 200, 40, 40},
	.btn_green = {710, 200, 40, 40},
	.btn_blue  = {760, 200, 40, 40},
	.door      = {640, 120, 200, 320},
}

// --- Room state: flags decide what exists and what clicks do ---
painting_moved: bool
key_taken:      bool
drawer_open:    bool
door_open:      bool

// one-slot inventory: what is in your hand?
Held_Item :: enum {
	nothing,
	key,
}
held: Held_Item

// the secret code shown by the note, and the player's progress in it
CODE := [3]Hotspot_Id{.btn_green, .btn_red, .btn_blue}
code_progress: int

mouse_x, mouse_y: f32
clicked: bool // true for exactly one frame after a click

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

reset_room :: proc() {
	painting_moved = false
	key_taken = false
	drawer_open = false
	door_open = false
	held = .nothing
	code_progress = 0
	fmt.println("(room reset)")
}

press_button :: proc(id: Hotspot_Id) {
	if !drawer_open {
		fmt.println("Buttons do nothing... maybe a hint is hidden somewhere.")
		return
	}
	if id == CODE[code_progress] {
		code_progress += 1
		fmt.println("*click*", id, "-", code_progress, "of", len(CODE))
		if code_progress == len(CODE) {
			door_open = true
			fmt.println("The door swings open. YOU ESCAPED.")
		}
	} else {
		code_progress = 0
		fmt.println("*bzzt* wrong order. The lock resets.")
	}
}

interact :: proc(id: Hotspot_Id) {
	switch id {
	case .painting:
		painting_moved = !painting_moved
		fmt.println(painting_moved ? "You slide the painting aside." : "You push the painting back.")
	case .key:
		key_taken = true
		held = .key
		fmt.println("You take the small key.")
	case .drawer:
		if drawer_open {
			fmt.println("The note shows three colors. Look closely.")
		} else if held == .key {
			drawer_open = true
			held = .nothing
			fmt.println("The key fits. Inside: a note with three colored squares.")
		} else {
			fmt.println("Locked. There is a small keyhole.")
		}
	case .btn_red, .btn_green, .btn_blue:
		press_button(id)
	case .door:
		fmt.println(door_open ? "Freedom." : "Heavy. Sealed. Three buttons beside it.")
	}
}

// is this hotspot currently clickable at all?
hotspot_active :: proc(id: Hotspot_Id) -> bool {
	switch id {
	case .key:
		return painting_moved && !key_taken
	case .painting, .drawer, .btn_red, .btn_green, .btn_blue, .door:
		return true
	}
	return false
}

// topmost active hotspot under the mouse (later entries drawn on top)
hotspot_under_mouse :: proc() -> (Hotspot_Id, bool) {
	// key sits over painting region, so check in reverse declaration order
	ids := [?]Hotspot_Id{.door, .btn_blue, .btn_green, .btn_red, .drawer, .key, .painting}
	for id in ids {
		if hotspot_active(id) && point_in_rect(mouse_x, mouse_y, HOTSPOTS[id]) {
			return id, true
		}
	}
	return .painting, false
}

draw_rect :: proc(r: Rect, cr, cg, cb: u8) {
	sgl.begin_quads()
	sgl.c3f(f32(cr)/255, f32(cg)/255, f32(cb)/255)
	sgl.v2f(r.x,       r.y)
	sgl.v2f(r.x + r.w, r.y)
	sgl.v2f(r.x + r.w, r.y + r.h)
	sgl.v2f(r.x,       r.y + r.h)
	sgl.end()
}

draw_outline :: proc(r: Rect, cr, cg, cb: u8) {
	sgl.begin_line_strip()
	sgl.c3f(f32(cr)/255, f32(cg)/255, f32(cb)/255)
	sgl.v2f(r.x,       r.y)
	sgl.v2f(r.x + r.w, r.y)
	sgl.v2f(r.x + r.w, r.y + r.h)
	sgl.v2f(r.x,       r.y + r.h)
	sgl.v2f(r.x,       r.y)
	sgl.end()
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x
		mouse_y = e.mouse_y
	case .MOUSE_DOWN:
		if e.mouse_button == .LEFT {
			clicked = true
		}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .R: reset_room()
		}
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.07, g = 0.07, b = 0.10, a = 1}}},
	}
	fmt.println("You wake in a dim room. (click things; R resets)")
}

frame :: proc "c" () {
	context = rt_ctx

	// --- input: one click, resolved against topmost hotspot ---
	if clicked {
		clicked = false
		if id, ok := hotspot_under_mouse(); ok {
			interact(id)
		}
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// --- draw scene: state flags decide the picture ---
	// floor + wall
	draw_rect({0, 440, W, 100}, 35, 30, 28)
	draw_rect({0, 0, W, 440}, 52, 48, 55)

	// door (frame changes color when open)
	if door_open {
		draw_rect(HOTSPOTS[.door], 20, 20, 24) // dark opening
		draw_outline(HOTSPOTS[.door], 120, 220, 140)
	} else {
		draw_rect(HOTSPOTS[.door], 92, 70, 50)
		draw_outline(HOTSPOTS[.door], 60, 45, 30)
	}

	// door buttons
	draw_rect(HOTSPOTS[.btn_red], 170, 60, 60)
	draw_rect(HOTSPOTS[.btn_green], 60, 150, 70)
	draw_rect(HOTSPOTS[.btn_blue], 60, 80, 170)

	// drawer (and the note inside when open)
	draw_rect(HOTSPOTS[.drawer], drawer_open ? 110 : 80, drawer_open ? 85 : 60, 45)
	if drawer_open {
		// the note: shows the code as three small colored squares
		draw_rect({395, 345, 120, 50}, 220, 210, 180)
		draw_rect({405, 360, 24, 24}, 60, 150, 70)  // green
		draw_rect({445, 360, 24, 24}, 170, 60, 60)  // red
		draw_rect({485, 360, 24, 24}, 60, 80, 170)  // blue
	}

	// key (only exists if revealed and not taken)
	if painting_moved && !key_taken {
		draw_rect(HOTSPOTS[.key], 210, 190, 90)
	}

	// painting (slides right when moved)
	p := HOTSPOTS[.painting]
	if painting_moved {
		p.x += 100
	}
	draw_rect(p, 140, 100, 80)
	draw_outline(p, 200, 170, 110)

	// --- hover highlight: show what is clickable ---
	if id, ok := hotspot_under_mouse(); ok {
		r := HOTSPOTS[id]
		if id == .painting && painting_moved {
			r.x += 100
		}
		draw_outline(r, 240, 220, 90)
	}

	// --- inventory bar ---
	draw_rect({8, H - 48, 160, 40}, 30, 32, 40)
	if held == .key {
		draw_rect({16, H - 40, 40, 24}, 210, 190, 90)
	}

	// progress pips for the code
	for i in 0 ..< len(CODE) {
		on := i < code_progress
		draw_rect({f32(W - 110 + i * 34), f32(H - 40), 24, 24}, on ? 90 : 45, on ? 200 : 50, on ? 110 : 60)
	}

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
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
		window_title = "T13 - Point And Click",
		logger = {func = slog.func},
	})
}
