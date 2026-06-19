/*
D02 — Inspect & Combine Items
=============================
Two adventure staples on top of d01's inventory:
  - INSPECT: a modal "zoom" on one item; a detail hotspot can reveal a clue.
  - COMBINE: two items -> a new one, via a data-driven RECIPE table.

READ THESE BLOCKS:
  - Mode / inspecting : the modal state; frame branches on it
  - RECIPES / try_combine : order-independent recipe lookup
  - click handler : two-step combine (first slot, then second slot)
  - inspect view : big item + a detail hotspot that reveals a flag

CONTROLS:
  left mouse  = select slot / pick / use ; if a slot is already armed for
                combine, clicking another slot combines them
  right mouse = inspect the slot under the cursor (or exit inspect)
  C           = arm/disarm combine on the selected slot
  R           = reset
*/

package d02_inspect_combine

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

Item :: enum {
	none,
	torn_photo,
	tape,
	repaired_photo,
	magnifier,
}
ITEM_COLORS := [Item][3]u8 {
	.none           = {0, 0, 0},
	.torn_photo     = {200, 170, 160},
	.tape           = {220, 220, 120},
	.repaired_photo = {200, 200, 210},
	.magnifier      = {120, 200, 220},
}
ITEM_NAMES := [Item]string {
	.none           = "nothing",
	.torn_photo     = "torn photo",
	.tape           = "roll of tape",
	.repaired_photo = "repaired photo",
	.magnifier      = "magnifier",
}

// --- recipe table: A + B -> result (order-independent in try_combine) ---
Recipe :: struct {
	a, b, result: Item,
}
RECIPES := []Recipe{{.torn_photo, .tape, .repaired_photo}}

try_combine :: proc(x, y: Item) -> (Item, bool) {
	for r in RECIPES {
		if (r.a == x && r.b == y) || (r.a == y && r.b == x) {
			return r.result, true
		}
	}
	return .none, false
}

// --- scene hotspots that grant the starting items ---
Hotspot_Id :: enum {
	photo_pickup,
	tape_pickup,
	magnifier_pickup,
}
HOTSPOTS := [Hotspot_Id]Rect {
	.photo_pickup     = {140, 180, 80, 60},
	.tape_pickup      = {380, 360, 60, 40},
	.magnifier_pickup = {620, 360, 70, 30},
}
HOTSPOT_ITEM := [Hotspot_Id]Item {
	.photo_pickup     = .torn_photo,
	.tape_pickup      = .tape,
	.magnifier_pickup = .magnifier,
}
taken: [Item]bool

// --- inventory (from d01) ---
inventory: [dynamic]Item
selected: int = -1
combine_arm: int = -1 // slot armed to be combined with the next clicked slot

// --- modal state ---
Mode :: enum {
	scene,
	inspect,
}
mode: Mode
inspecting: Item
found_address: bool // clue revealed by inspecting the repaired photo

mouse_x, mouse_y: f32
clicked_l, clicked_r: bool
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

selected_item :: proc() -> Item {
	if selected < 0 || selected >= len(inventory) {return .none}
	return inventory[selected]
}

pick_up :: proc(it: Item) {
	if taken[it] {return}
	taken[it] = true
	append(&inventory, it)
	fmt.println("Collected:", ITEM_NAMES[it])
}

reset_room :: proc() {
	clear(&inventory)
	selected = -1
	combine_arm = -1
	taken = {}
	mode = .scene
	found_address = false
	fmt.println("(scene reset)")
}

do_combine :: proc(i, j: int) {
	if i == j {return}
	a := inventory[i]
	b := inventory[j]
	if res, ok := try_combine(a, b); ok {
		// remove higher index first so the lower stays valid
		hi := max(i, j);lo := min(i, j)
		ordered_remove(&inventory, hi)
		ordered_remove(&inventory, lo)
		append(&inventory, res)
		selected = -1;combine_arm = -1
		fmt.println("Combined ->", ITEM_NAMES[res])
	} else {
		combine_arm = -1
		fmt.println("Those don't go together.")
	}
}

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

hotspot_under_mouse :: proc() -> (Hotspot_Id, bool) {
	ids := [?]Hotspot_Id{.magnifier_pickup, .tape_pickup, .photo_pickup}
	for id in ids {
		if !taken[HOTSPOT_ITEM[id]] && point_in_rect(mouse_x, mouse_y, HOTSPOTS[id]) {
			return id, true
		}
	}
	return .photo_pickup, false
}

// detail hotspot shown in inspect mode (back of the repaired photo)
INSPECT_DETAIL :: Rect{W / 2 - 40, H / 2 + 40, 80, 30}

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
		if e.mouse_button == .LEFT {clicked_l = true}
		if e.mouse_button == .RIGHT {clicked_r = true}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .R:
			reset_room()
		case .C:
			combine_arm = selected
			fmt.println("Combine armed on slot", combine_arm, "- click another slot")
		case .ESCAPE:
			mode = .scene
		}
	}
}

// draw a string at PIXEL position (x,y). sdtx is cell-based (one char = 8x8 px),
// so we set canvas = window size and divide by 8.
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
	fmt.println("Collect photo + tape, combine (C then click), inspect (right-click).")
}

handle_clicks :: proc() {
	if mode == .inspect {
		if clicked_l {
			clicked_l = false
			if inspecting == .repaired_photo && point_in_rect(mouse_x, mouse_y, INSPECT_DETAIL) {
				found_address = true
				fmt.println("On the back: an address. (clue found)")
			} else {
				mode = .scene // click elsewhere leaves inspect
			}
		}
		if clicked_r {clicked_r = false;mode = .scene}
		return
	}

	// scene mode
	if clicked_r {
		clicked_r = false
		if slot, ok := slot_under_mouse(); ok {
			mode = .inspect
			inspecting = inventory[slot]
			fmt.println("Inspecting:", ITEM_NAMES[inspecting])
		}
	}
	if clicked_l {
		clicked_l = false
		if slot, ok := slot_under_mouse(); ok {
			if combine_arm >= 0 && combine_arm < len(inventory) {
				do_combine(combine_arm, slot)
			} else {
				selected = (selected == slot) ? -1 : slot
			}
		} else if id, ok := hotspot_under_mouse(); ok {
			pick_up(HOTSPOT_ITEM[id])
		}
	}
}

frame :: proc "c" () {
	context = rt_ctx
	handle_clicks()

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	if mode == .inspect {
		// dim background + big item
		draw_rect({0, 0, W, H}, 16, 16, 22)
		c := ITEM_COLORS[inspecting]
		draw_rect({W / 2 - 120, H / 2 - 120, 240, 200}, c[0], c[1], c[2])
		if inspecting == .repaired_photo {
			draw_rect(INSPECT_DETAIL, found_address ? 90 : 150, found_address ? 200 : 150, 110)
			draw_outline(INSPECT_DETAIL, 240, 220, 90)
		}
	} else {
		// scene
		draw_rect({0, 0, W, 440}, 52, 48, 55)
		draw_rect({0, 440, W, 100}, 35, 30, 28)
		for id in Hotspot_Id {
			if !taken[HOTSPOT_ITEM[id]] {
				cc := ITEM_COLORS[HOTSPOT_ITEM[id]]
				draw_rect(HOTSPOTS[id], cc[0], cc[1], cc[2])
			}
		}
		if id, ok := hotspot_under_mouse(); ok {
			draw_outline(HOTSPOTS[id], 240, 220, 90)
		}
		// inventory bar
		for it, i in inventory {
			r := slot_rect(i)
			draw_rect(r, 30, 32, 40)
			c := ITEM_COLORS[it]
			draw_rect({r.x + 6, r.y + 6, SLOT - 12, SLOT - 12}, c[0], c[1], c[2])
			if i == selected {draw_outline(r, 240, 220, 90)}
			if i == combine_arm {draw_outline(r, 90, 200, 240)} // armed = blue
		}
	}

	// --- text overlay ---
	sdtx.canvas(W, H)
	label(12, 10, 235, 235, 245, "D02 - Inspect & Combine")
	label(12, 26, 150, 160, 175, "Left=collect/select  Right=inspect  C=arm combine then click  R=reset")

	if mode == .inspect {
		label(W / 2 - 60, 100, 245, 240, 200, ITEM_NAMES[inspecting])
		if inspecting == .repaired_photo {
			label(INSPECT_DETAIL.x, INSPECT_DETAIL.y - 14, 240, 220, 90, "[back of photo]")
			if found_address {
				label(W / 2 - 60, H / 2 + 90, 120, 240, 140, "Clue: an address!")
			}
		}
		label(W / 2 - 90, H - 40, 160, 170, 185, "click elsewhere / Esc to exit")
	} else {
		// label visible scene pickups
		for id in Hotspot_Id {
			if !taken[HOTSPOT_ITEM[id]] {
				r := HOTSPOTS[id]
				label(r.x, r.y - 14, 220, 215, 200, ITEM_NAMES[HOTSPOT_ITEM[id]])
			}
		}
		// label inventory slots
		for it, i in inventory {
			r := slot_rect(i)
			label(r.x, r.y - 14, 200, 205, 215, ITEM_NAMES[it])
		}
		// status line near bottom
		sel := selected_item()
		armed := "none"
		if combine_arm >= 0 && combine_arm < len(inventory) {
			armed = ITEM_NAMES[inventory[combine_arm]]
		}
		label(12, H - 30, 200, 210, 220,
			fmt.tprintf("selected: %s   combine armed: %s", ITEM_NAMES[sel], armed))
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
		width = W, height = H, window_title = "D02 — Inspect & Combine",
		logger = {func = slog.func},
	})
}
