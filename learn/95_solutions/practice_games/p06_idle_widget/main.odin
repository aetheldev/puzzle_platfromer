// PRACTICE GAME 06 - Idle Widget (tamagotchi mode)
// ================================================
// GOAL: p05's idle RPG as a TINY WINDOW you park in a screen corner.
//       It fights by itself. You glance at it now and then: did it
//       level? what dropped? enough gold for an upgrade? PAUSE it to
//       manage gear: equip, SELL, buy.
//
// WHAT THIS COMBINES:
//   - p05's game design (stats, drops, rarity, gold)
//   - t02 rects, t13 point-in-rect clicking
//   - p01's tick timer (auto-combat beat)
//   - o17 enumerated arrays, o18 Maybe(Item) slots
//   - sokol debugtext (sdtx) — bundled retro text, zero font files
//
// THE SCREEN (340x460):
//   - header: PAUSE/RESUME button (or SPACE)
//   - arena: hero vs monster, names, HP bars + numbers, hit flashes
//   - XP bar, GOLD, KILLS
//   - GEAR row: 3 slots (weapon/armor/trinket)
//   - BAG grid: LEFT CLICK = equip (slot swap), RIGHT CLICK = SELL
//   - shop: POTION (heal), ATK+1 (scaling cost), BOX (random item)
//   - info line: hover any item to read stats + sell price
//
// CONTROLS: mouse + SPACE (pause). Park it in a corner. Let it live.
//
// TILING WM NOTE (AeroSpace etc.): the build wrapper names the app
// bundle "learn-<lesson>", so one floating rule covers every lesson:
//   [[on-window-detected]]
//       if.app-name-regex-substring = 'learn-'
//       run = 'layout floating'

package p06_idle_widget

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import sdtx  "../../../../sauce/sokol/debugtext"
import "base:runtime"
import "core:fmt"
import "core:math/rand"

W :: 340
H :: 460

// ---------- tiny geometry / drawing kit (t02 + t13) ----------

Rect :: struct {
	x, y, w, h: f32,
}

point_in_rect :: proc(px, py: f32, r: Rect) -> bool {
	return px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h
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
	sgl.v2f_c4b(r.x,       r.y,       cr, cg, cb, 255)
	sgl.v2f_c4b(r.x + r.w, r.y,       cr, cg, cb, 255)
	sgl.v2f_c4b(r.x + r.w, r.y + r.h, cr, cg, cb, 255)
	sgl.v2f_c4b(r.x,       r.y + r.h, cr, cg, cb, 255)
	sgl.v2f_c4b(r.x,       r.y,       cr, cg, cb, 255)
	sgl.end()
}

// text helper: position in PIXELS (sdtx wants 8x8 character cells)
text :: proc(x_px, y_px: f32, cr, cg, cb: u8, s: string, args: ..any) {
	sdtx.color3b(cr, cg, cb)
	sdtx.pos(x_px / 8, y_px / 8)
	sdtx.printf(s, ..args)
}

// ---------- game data (p05, trimmed for widget life) ----------

Slot :: enum {
	weapon,
	armor,
	trinket,
}

SLOT_NAME := [Slot]string{.weapon = "WEAPON", .armor = "ARMOR", .trinket = "TRINKET"}

Rarity :: enum {
	common,
	rare,
	epic,
}

RARITY_COLOR := [Rarity][3]u8{
	.common = {160, 160, 160},
	.rare   = {90, 150, 230},
	.epic   = {190, 100, 240},
}
RARITY_NAME := [Rarity]string{.common = "COMMON", .rare = "RARE", .epic = "EPIC"}
RARITY_MULT := [Rarity]int{.common = 1, .rare = 2, .epic = 4}

Item :: struct {
	slot:   Slot,
	rarity: Rarity,
	atk:    int,
	def:    int,
	hp:     int,
}

MONSTER_NAMES := [?]string{"RAT", "GOBLIN", "WOLF", "BANDIT", "OGRE", "WRAITH", "DRAKE"}

hero_level: int
hero_xp: int
hero_hp: int // current, persists between fights (potions matter!)
base_atk, base_def, base_max_hp: int
bonus_atk: int // whetstone upgrades
gold: int
kills: int
paused: bool

equipped:  [Slot]Maybe(Item)
inventory: [dynamic]Item
INV_COLS :: 6
INV_ROWS :: 2
INV_MAX :: INV_COLS * INV_ROWS

Monster :: struct {
	name:   string,
	level:  int,
	hp:     int,
	max_hp: int,
	atk:    int,
	def:    int,
}
monster: Monster

// juice: frames remaining of hit flash
hero_flash, monster_flash: int

frame_count: int
TICK :: 50 // frames between combat beats (~0.8s)

mouse_x, mouse_y: f32
clicked, rclicked: bool

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

// ---------- derived stats ----------

total_atk :: proc() -> int {
	t := base_atk + bonus_atk
	for s in Slot {
		if it, ok := equipped[s].?; ok {t += it.atk}
	}
	return t
}

total_def :: proc() -> int {
	t := base_def
	for s in Slot {
		if it, ok := equipped[s].?; ok {t += it.def}
	}
	return t
}

total_max_hp :: proc() -> int {
	t := base_max_hp
	for s in Slot {
		if it, ok := equipped[s].?; ok {t += it.hp}
	}
	return t
}

sell_value :: proc(it: Item) -> int {
	return it.atk + it.def + it.hp / 2 + 2 * RARITY_MULT[it.rarity]
}

// ---------- game logic ----------

spawn_monster :: proc() {
	lvl := max(1, hero_level + rand.int_max(3) - 1)
	tier := min(len(MONSTER_NAMES) - 1, lvl / 2)
	mhp := 14 + lvl * 6
	monster = Monster{
		name   = MONSTER_NAMES[rand.int_max(tier + 1)],
		level  = lvl,
		hp     = mhp,
		max_hp = mhp,
		atk    = 3 + lvl * 2,
		def    = 1 + lvl,
	}
}

make_item :: proc(rarity: Rarity) -> Item {
	slot := rand.choice_enum(Slot)
	mult := RARITY_MULT[rarity]
	it := Item{slot = slot, rarity = rarity}
	switch slot {
	case .weapon:  it.atk = (1 + hero_level / 2) * mult
	case .armor:   it.def = (1 + hero_level / 3) * mult; it.hp = 2 * mult
	case .trinket: it.hp = (2 + hero_level) * mult
	}
	return it
}

roll_drop :: proc() {
	roll := rand.float32()
	rarity: Rarity
	switch {
	case roll < 0.03: rarity = .epic
	case roll < 0.13: rarity = .rare
	case roll < 0.45: rarity = .common
	case:
		return // no drop
	}
	it := make_item(rarity)

	// empty slot? auto-equip. full inventory? auto-sell (idle games forgive).
	if _, has := equipped[it.slot].?; !has {
		equipped[it.slot] = it
	} else if len(inventory) < INV_MAX {
		append(&inventory, it)
	} else {
		gold += sell_value(it) // auto-sold
	}
}

damage :: proc(atk, def: int) -> int {
	base := max(1, atk - def / 2)
	return base + rand.int_max(max(1, base / 2))
}

combat_tick :: proc() {
	// hero strikes
	monster.hp -= damage(total_atk(), monster.def)
	monster_flash = 8
	if monster.hp <= 0 {
		kills += 1
		gold += 2 + monster.level
		hero_xp += 15 + monster.level * 10
		for hero_xp >= hero_level * 100 {
			hero_xp -= hero_level * 100
			hero_level += 1
			base_max_hp += 6
			base_atk += 2
			base_def += 1
			hero_hp = total_max_hp() // ding! full heal on level
		}
		roll_drop()
		spawn_monster()
		return
	}
	// monster strikes back
	hero_hp -= damage(monster.atk, total_def())
	hero_flash = 8
	if hero_hp <= 0 {
		// defeat: lose some gold, rest up, new monster
		gold = gold * 9 / 10
		hero_hp = total_max_hp()
		spawn_monster()
	}
}

// ---------- layout (no overlaps: each band gets its own y range) ----------

PAUSE_RECT :: Rect{264, 8, 60, 18}

HERO_RECT    :: Rect{40, 76, 56, 56}
MONSTER_RECT :: Rect{244, 76, 56, 56}

// bands: arena 28..140 / xp+gold 152..196 / gear 208..288 / bag 296..398
// info line 402..414 / shop 422..452
EQUIP_Y :: 226
INV_Y :: 312
CELL :: 40

equip_cell :: proc(s: Slot) -> Rect {
	return Rect{40 + f32(int(s)) * (CELL + 56), EQUIP_Y, CELL, CELL}
}

inv_cell :: proc(i: int) -> Rect {
	col := i % INV_COLS
	row := i / INV_COLS
	return Rect{18 + f32(col) * (CELL + 11), INV_Y + f32(row) * (CELL + 6), CELL, CELL}
}

POTION_RECT    :: Rect{16, 424, 96, 28}
WHETSTONE_RECT :: Rect{122, 424, 96, 28}
BOX_RECT       :: Rect{228, 424, 96, 28}

POTION_COST :: 15
whetstone_bought: int
whetstone_cost :: proc() -> int {return 25 + whetstone_bought * 15}
box_cost :: proc() -> int {return 20 + hero_level * 5}

// draw an item as rect art: rarity = border color, slot = inner shape
draw_item :: proc(cell: Rect, it: Item) {
	c := RARITY_COLOR[it.rarity]
	draw_rect(cell, 38, 40, 48)
	draw_outline(cell, c[0], c[1], c[2])
	switch it.slot {
	case .weapon: // tall blade
		draw_rect({cell.x + cell.w / 2 - 4, cell.y + 7, 8, cell.h - 14}, c[0], c[1], c[2])
	case .armor: // wide chest
		draw_rect({cell.x + 7, cell.y + cell.h / 2 - 7, cell.w - 14, 14}, c[0], c[1], c[2])
	case .trinket: // small gem
		draw_rect({cell.x + cell.w / 2 - 6, cell.y + cell.h / 2 - 6, 12, 12}, c[0], c[1], c[2])
	}
}

// ---------- input ----------

handle_click :: proc() {
	if point_in_rect(mouse_x, mouse_y, PAUSE_RECT) {
		paused = !paused
		return
	}
	// inventory: click item -> equip into its slot (swap)
	for it, i in inventory {
		if point_in_rect(mouse_x, mouse_y, inv_cell(i)) {
			if old, has := equipped[it.slot].?; has {
				inventory[i] = old
			} else {
				unordered_remove(&inventory, i)
			}
			equipped[it.slot] = it
			return
		}
	}
	// shop
	if point_in_rect(mouse_x, mouse_y, POTION_RECT) && gold >= POTION_COST && hero_hp < total_max_hp() {
		gold -= POTION_COST
		hero_hp = total_max_hp()
		return
	}
	if point_in_rect(mouse_x, mouse_y, WHETSTONE_RECT) && gold >= whetstone_cost() {
		gold -= whetstone_cost()
		bonus_atk += 1
		whetstone_bought += 1
		return
	}
	if point_in_rect(mouse_x, mouse_y, BOX_RECT) && gold >= box_cost() && len(inventory) < INV_MAX {
		gold -= box_cost()
		// box luck: better odds than monster drops
		roll := rand.float32()
		rarity: Rarity = roll < 0.08 ? .epic : (roll < 0.35 ? .rare : .common)
		append(&inventory, make_item(rarity))
		return
	}
}

handle_right_click :: proc() {
	// right click a bag item -> sell it
	for it, i in inventory {
		if point_in_rect(mouse_x, mouse_y, inv_cell(i)) {
			gold += sell_value(it)
			unordered_remove(&inventory, i)
			return
		}
	}
}

// ---------- sokol ----------

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x
		mouse_y = e.mouse_y
	case .MOUSE_DOWN:
		if e.mouse_button == .LEFT {clicked = true}
		if e.mouse_button == .RIGHT {rclicked = true}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .SPACE: paused = !paused
		}
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	sdtx.setup({fonts = {0 = sdtx.font_c64()}, logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.07, g = 0.08, b = 0.10, a = 1}}},
	}
	hero_level = 1
	base_max_hp = 40
	base_atk = 7
	base_def = 3
	hero_hp = base_max_hp
	spawn_monster()
	fmt.println("idle widget alive. park me in a corner. SPACE = pause.")
}

hp_bar :: proc(x, y, w: f32, cur, maxv: int, cr, cg, cb: u8) {
	draw_rect({x, y, w, 8}, 30, 32, 38)
	frac := f32(max(0, cur)) / f32(max(1, maxv))
	draw_rect({x, y, w * frac, 8}, cr, cg, cb)
}

frame :: proc "c" () {
	context = rt_ctx

	if !paused {
		frame_count += 1
		if frame_count >= TICK {
			frame_count = 0
			combat_tick()
		}
		if hero_flash > 0 {hero_flash -= 1}
		if monster_flash > 0 {monster_flash -= 1}
	}
	if clicked {
		clicked = false
		handle_click()
	}
	if rclicked {
		rclicked = false
		handle_right_click()
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// text canvas: 1 character cell = 8 px on our 340x460 window
	sdtx.canvas(W, H)
	sdtx.origin(0, 0)

	// --- header: pause button ---
	draw_rect(PAUSE_RECT, paused ? 70 : 45, paused ? 110 : 50, 60)
	draw_outline(PAUSE_RECT, paused ? 120 : 90, paused ? 200 : 100, 110)
	text(PAUSE_RECT.x + (paused ? 14 : 10), PAUSE_RECT.y + 5, 220, 225, 235, paused ? "GO" : "STOP")
	if paused {
		text(20, 12, 240, 210, 110, "PAUSED - MANAGE GEAR")
	}

	// --- arena ---
	text(HERO_RECT.x, 28, 200, 205, 215, "HERO LV %d", hero_level)
	text(MONSTER_RECT.x - 36, 28, 220, 140, 110, "%s LV %d", monster.name, monster.level)

	// hero: blue square, flashes red when hit
	if hero_flash > 0 {
		draw_rect(HERO_RECT, 220, 90, 90)
	} else {
		draw_rect(HERO_RECT, 90, 150, 220)
	}
	// monster: greener when weak, redder when strong vs you
	if monster_flash > 0 {
		draw_rect(MONSTER_RECT, 240, 240, 240)
	} else {
		danger := u8(clamp(120 + (monster.level - hero_level) * 40, 80, 240))
		draw_rect(MONSTER_RECT, danger, u8(200 - danger / 2), 80)
	}
	hp_bar(HERO_RECT.x, 44, HERO_RECT.w, hero_hp, total_max_hp(), 90, 200, 110)
	hp_bar(MONSTER_RECT.x, 44, MONSTER_RECT.w, monster.hp, monster.max_hp, 200, 90, 90)
	text(HERO_RECT.x, 56, 130, 180, 140, "%d/%d", hero_hp, total_max_hp())
	text(MONSTER_RECT.x, 56, 190, 130, 130, "%d/%d", max(0, monster.hp), monster.max_hp)

	text(150, 100, paused ? 240 : 90, paused ? 210 : 95, paused ? 110 : 105, paused ? "||" : "VS")
	text(HERO_RECT.x - 14, 140, 140, 145, 155, "ATK %d  DEF %d", total_atk(), total_def())

	// --- xp + gold + kills band ---
	text(20, 164, 200, 180, 240, "XP")
	draw_rect({48, 162, 196, 8}, 30, 32, 38)
	xp_frac := f32(hero_xp) / f32(max(1, hero_level * 100))
	draw_rect({48, 162, 196 * xp_frac, 8}, 160, 130, 230)
	text(252, 164, 150, 130, 200, "%d/%d", hero_xp, hero_level * 100)

	draw_rect({20, 184, 14, 14}, 230, 190, 70)
	text(42, 188, 230, 190, 70, "GOLD %d", gold)
	text(200, 188, 130, 135, 145, "KILLS %d", kills)

	// --- gear band ---
	text(20, 210, 170, 175, 185, "GEAR")
	for s in Slot {
		cell := equip_cell(s)
		draw_rect(cell, 28, 30, 36)
		draw_outline(cell, 70, 75, 85)
		if it, ok := equipped[s].?; ok {
			draw_item(cell, it)
		}
		// slot label under its cell, own band, nothing else at this y
		text(cell.x - 8, cell.y + cell.h + 8, 110, 115, 125, "%s", SLOT_NAME[s])
	}

	// --- bag band ---
	text(20, 296, 170, 175, 185, "BAG")
	text(62, 296, 110, 115, 125, "L=EQUIP R=SELL")
	text(252, 296, 110, 115, 125, "%d/%d", len(inventory), INV_MAX)
	for i in 0 ..< INV_MAX {
		cell := inv_cell(i)
		draw_rect(cell, 24, 26, 31)
		draw_outline(cell, 50, 54, 62)
	}
	hover_info: string
	for it, i in inventory {
		cell := inv_cell(i)
		draw_item(cell, it)
		if point_in_rect(mouse_x, mouse_y, cell) {
			draw_outline(cell, 240, 220, 90) // hover: clickable
			hover_info = fmt.tprintf(
				"%s %s +%dATK +%dDEF +%dHP SELL:%dG",
				RARITY_NAME[it.rarity], SLOT_NAME[it.slot], it.atk, it.def, it.hp, sell_value(it),
			)
		}
	}
	// hovering GEAR shows info too
	for s in Slot {
		if it, ok := equipped[s].?; ok {
			if point_in_rect(mouse_x, mouse_y, equip_cell(s)) {
				hover_info = fmt.tprintf(
					"%s %s +%dATK +%dDEF +%dHP (WORN)",
					RARITY_NAME[it.rarity], SLOT_NAME[it.slot], it.atk, it.def, it.hp,
				)
			}
		}
	}

	// --- info line (its own band, above the shop) ---
	if hover_info != "" {
		text(16, 408, 230, 220, 160, "%s", hover_info)
	}

	// --- shop band ---
	shop_button :: proc(r: Rect, enabled: bool, label: string, args: ..any) {
		draw_rect(r, 35, enabled ? 52 : 40, 44)
		draw_outline(r, enabled ? 150 : 70, enabled ? 160 : 75, enabled ? 120 : 85)
		sdtx.color3b(enabled ? 235 : 110, enabled ? 225 : 115, enabled ? 180 : 125)
		sdtx.pos((r.x + 8) / 8, (r.y + 10) / 8)
		sdtx.printf(label, ..args)
		if point_in_rect(mouse_x, mouse_y, r) {draw_outline(r, 240, 220, 90)}
	}
	shop_button(POTION_RECT, gold >= POTION_COST && hero_hp < total_max_hp(), "HEAL %dG", POTION_COST)
	shop_button(WHETSTONE_RECT, gold >= whetstone_cost(), "ATK+1 %dG", whetstone_cost())
	shop_button(BOX_RECT, gold >= box_cost() && len(inventory) < INV_MAX, "BOX %dG", box_cost())

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()
	sdtx.draw()
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	delete(inventory)
	sdtx.shutdown()
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
		window_title = "Idle Widget",
		logger = {func = slog.func},
	})
}
