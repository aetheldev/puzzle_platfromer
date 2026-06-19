/*
D01 — Multi-Slot Inventory
==========================
Grows t13's one-slot "hand" into a real inventory: a LIST of items + a selected
index. A detective collects several pieces of evidence, selects one, and uses
it on the scene.

KEY STATE:
  inventory : [dynamic]Item   -- what you carry (pickup order)
  selected  : int             -- index into inventory, -1 = none

READ THESE BLOCKS:
  - inventory / selected / selected_item / remove_selected : the model
  - slot_rect / slot_under_mouse : the bar as data (like hotspots)
  - frame : click resolution (BAR before SCENE), bar drawing with highlight

CONTROLS: left mouse = interact / select slot ; R = reset
*/

package d01_multi_inventory

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

// --- items that can exist in the world / inventory ---
Item :: enum {
	none,
	magnifier,
	key,
	photo,
}

ITEM_COLORS := [Item][3]u8 {
	.none      = {0, 0, 0},
	.magnifier = {120, 200, 220},
	.key       = {210, 190, 90},
	.photo     = {200, 200, 210},
}

ITEM_NAMES := [Item]string {
	.none      = "",
	.magnifier = "magnifier",
	.key       = "key",
	.photo     = "photo",
}

HOTSPOT_LABELS := [Hotspot_Id]string {
	.magnifier_on_desk = "magnifier",
	.key_on_hook       = "key",
	.photo_on_wall     = "photo",
	.drawer            = "drawer",
}

// --- hotspots (clickable scene regions) ---
Hotspot_Id :: enum {
	magnifier_on_desk,
	key_on_hook,
	photo_on_wall,
	drawer,
}

HOTSPOTS := [Hotspot_Id]Rect {
	.magnifier_on_desk = {120, 360, 70, 30},
	.key_on_hook       = {300, 150, 36, 50},
	.photo_on_wall     = {520, 120, 90, 70},
	.drawer            = {380, 360, 150, 70},
}

// world flags: has this item been taken yet?
taken: [Item]bool
drawer_open: bool

// --- inventory model ---
inventory: [dynamic]Item
selected: int = -1

selected_item :: proc() -> Item {
	if selected < 0 || selected >= len(inventory) {return .none}
	return inventory[selected]
}

remove_selected :: proc() {
	if selected < 0 || selected >= len(inventory) {return}
	ordered_remove(&inventory, selected)
	selected = -1
}

pick_up :: proc(it: Item) {
	if taken[it] {return}
	if len(inventory) >= 6 {
		fmt.println("Your evidence bag is full.")
		return
	}
	taken[it] = true
	append(&inventory, it)
	fmt.println("Collected:", it)
}

mouse_x, mouse_y: f32
clicked: bool
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

reset_room :: proc() {
	clear(&inventory)
	selected = -1
	taken = {}
	drawer_open = false
	fmt.println("(scene reset)")
}

interact :: proc(id: Hotspot_Id) {
	switch id {
	case .magnifier_on_desk:
		pick_up(.magnifier)
	case .key_on_hook:
		pick_up(.key)
	case .photo_on_wall:
		pick_up(.photo)
	case .drawer:
		if drawer_open {
			fmt.println("The drawer is already open.")
		} else if selected_item() == .key {
			drawer_open = true
			remove_selected() // consume the key
			fmt.println("The key fits. The drawer slides open.")
		} else {
			fmt.println("Locked. Maybe a key, and it must be SELECTED in your bag.")
		}
	}
}

hotspot_active :: proc(id: Hotspot_Id) -> bool {
	switch id {
	case .magnifier_on_desk:
		return !taken[.magnifier]
	case .key_on_hook:
		return !taken[.key]
	case .photo_on_wall:
		return !taken[.photo]
	case .drawer:
		return true
	}
	return false
}

hotspot_under_mouse :: proc() -> (Hotspot_Id, bool) {
	ids := [?]Hotspot_Id{.drawer, .photo_on_wall, .key_on_hook, .magnifier_on_desk}
	for id in ids {
		if hotspot_active(id) && point_in_rect(mouse_x, mouse_y, HOTSPOTS[id]) {
			return id, true
		}
	}
	return .drawer, false
}

// --- inventory bar: each slot is a rect, like a hotspot ---
SLOT :: f32(44)
slot_rect :: proc(i: int) -> Rect {
	return {12 + f32(i) * (SLOT + 8), H - SLOT - 12, SLOT, SLOT}
}
slot_under_mouse :: proc() -> (int, bool) {
	for i in 0 ..< len(inventory) {
		if point_in_rect(mouse_x, mouse_y, slot_rect(i)) {return i, true}
	}
	return -1, false
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
			reset_room()
		}
	}
}

// --- text helper: draw a string at PIXEL position (x,y). sdtx is cell-based
// (one char = 8x8 px), so we set canvas = window size and divide by 8. ---
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
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.07, g = 0.07, b = 0.10, a = 1}}},
	}
	fmt.println("Crime scene. Click to collect; select a slot; use it. (R resets)")
}

frame :: proc "c" () {
	context = rt_ctx

	// CLICK RESOLUTION: inventory bar first, then the scene.
	if clicked {
		clicked = false
		if slot, ok := slot_under_mouse(); ok {
			selected = (selected == slot) ? -1 : slot // click again = deselect
		} else if id, ok := hotspot_under_mouse(); ok {
			interact(id)
		}
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// scene background
	draw_rect({0, 0, W, 440}, 52, 48, 55)
	draw_rect({0, 440, W, 100}, 35, 30, 28)

	// scene items (only if not yet taken)
	if !taken[.magnifier] {draw_rect(HOTSPOTS[.magnifier_on_desk], 120, 200, 220)}
	if !taken[.key] {draw_rect(HOTSPOTS[.key_on_hook], 210, 190, 90)}
	if !taken[.photo] {draw_rect(HOTSPOTS[.photo_on_wall], 200, 200, 210)}

	// drawer
	draw_rect(HOTSPOTS[.drawer], drawer_open ? 110 : 80, drawer_open ? 85 : 60, 45)

	// hover highlight on a clickable hotspot
	if id, ok := hotspot_under_mouse(); ok {
		draw_outline(HOTSPOTS[id], 240, 220, 90)
	}

	// inventory bar
	for it, i in inventory {
		r := slot_rect(i)
		draw_rect(r, 30, 32, 40)
		c := ITEM_COLORS[it]
		draw_rect({r.x + 6, r.y + 6, SLOT - 12, SLOT - 12}, c[0], c[1], c[2])
		if i == selected {
			draw_outline(r, 240, 220, 90) // selected highlight
		}
	}

	// ---- TEXT OVERLAY (sokol_debugtext) ----
	sdtx.canvas(W, H)
	// title + controls
	label(12, 10, 230, 230, 240, "D01 - Multi-Slot Inventory")
	label(12, 26, 150, 150, 170, "Click items to collect. Click a slot to select. R = reset.")

	// label each scene item under its rect
	if !taken[.magnifier] {label(HOTSPOTS[.magnifier_on_desk].x, HOTSPOTS[.magnifier_on_desk].y - 14, 200, 220, 240, "magnifier")}
	if !taken[.key] {label(HOTSPOTS[.key_on_hook].x, HOTSPOTS[.key_on_hook].y - 14, 230, 210, 120, "key")}
	if !taken[.photo] {label(HOTSPOTS[.photo_on_wall].x, HOTSPOTS[.photo_on_wall].y - 14, 220, 220, 230, "photo")}
	label(HOTSPOTS[.drawer].x, HOTSPOTS[.drawer].y - 14, 200, 170, 120, drawer_open ? "drawer (open)" : "drawer (locked)")

	// label each inventory slot with the item name
	for it, i in inventory {
		r := slot_rect(i)
		label(r.x, r.y - 14, 220, 220, 200, ITEM_NAMES[it])
	}

	// what is selected, and a hover hint
	if sel := selected_item(); sel != .none {
		label(180, H - 30, 240, 220, 90, fmt.tprintf("selected: %s", ITEM_NAMES[sel]))
	} else {
		label(180, H - 30, 120, 120, 140, "selected: nothing")
	}
	if id, ok := hotspot_under_mouse(); ok {
		label(mouse_x + 12, mouse_y - 4, 250, 240, 180, HOTSPOT_LABELS[id])
	}

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()   // shapes first
	sdtx.draw()  // text on top, same pass
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
		width = W, height = H, window_title = "D01 — Multi-Slot Inventory",
		logger = {func = slog.func},
	})
}
