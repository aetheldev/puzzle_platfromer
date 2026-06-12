// PRACTICE GAME 09 - Idle Auto-Battler
// ====================================
// GOAL: A screen-filling idle auto-battler. Hero on the left fights an
//       endless parade of monsters on the right. Waves scale, every 10th
//       wave is a BOSS, gold buys upgrades. The REAL lesson: idle games
//       live or die on FEEDBACK. Every number change must be SEEN —
//       floating damage text, hit flashes, particle bursts, coins that
//       physically fly to the gold counter. Never silently mutate a stat.
//
// CONCEPTS:
//   - Feedback pools: damage numbers, impact particles, hit flashes and
//     gold coins are ALL the same pattern — fixed pool + life timer
//     (t10's particles, four different costumes).
//   - One source of truth for combat math: dps = damage * speed. The UI
//     READS hero_dps(); it never computes its own version.
//   - Lagging HP bar: a white segment trails the real bar and drains
//     slowly, so you SEE what you just lost (classic juice trick).
//   - Coins ARE the transaction: gold only increments when a coin lands
//     on the counter. The feedback IS the state-change presentation.
//   - 7-segment digits built from rects: numbers with zero text modules,
//     zero font files. Pure sgl.
//
// TASKS FOR YOU:
//   [ ] Run it. Watch a full boss wave (wave 10) start to finish.
//   [ ] Buy each upgrade once; find the hover / dim / cost feedback.
//   [ ] Set CRIT_CHANCE to 0.5 and feel the shake budget break.
//   [ ] Let the hero die; watch the wave setback + revive countdown.
//   [ ] Add a 4th upgrade (gold find %) end to end: enum case + cost
//       table entry + button rect — note how little code that takes.
//
// CONTROLS: mouse only. R = full reset (debug).

package p09_idle_autobattler

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

GROUND_Y :: 400 // arena floor
PANEL_Y  :: 436 // upgrade panel starts here

HERO_X    :: 250 // hero anchor (center x)
MONSTER_X :: 690 // monster anchor (center x)

// combat feel
CRIT_CHANCE   :: 0.15
CRIT_MULT     :: 2.0
FLASH_TIME    :: 0.08 // victim flashes white this long
ANIM_TIME     :: 0.24 // full lunge + recoil
HERO_LUNGE    :: 52.0
MONSTER_LUNGE :: 44.0

// idle rules: dying is a setback, never a fail state
REVIVE_TIME   :: 3.0
DEATH_SETBACK :: 3
SPAWN_DELAY   :: 0.7

// upgrade economy
COST_GROWTH :: 1.15 // cost = base * 1.15^level

// hero stat tables (one source of truth — see hero_* procs below)
DAMAGE_BASE      :: 5.0
DAMAGE_PER_LEVEL :: 2.0
RATE_BASE        :: 1.0  // attacks per second
RATE_PER_LEVEL   :: 0.10
HP_BASE          :: 60.0
HP_PER_LEVEL     :: 20.0
REGEN_BASE       :: 1.0  // hp per second
REGEN_PER_LEVEL  :: 0.6

GOLD_PULSE_TIME :: 0.25
// where coins fly to: center of the gold icon in the top bar
GOLD_TX :: 30.0
GOLD_TY :: 26.0

// ---------- tiny geometry / drawing kit (t02 + t13) ----------

Rect :: struct {
	x, y, w, h: f32,
}

point_in_rect :: proc(px, py: f32, r: Rect) -> bool {
	return px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h
}

draw_rect :: proc(r: Rect, cr, cg, cb: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(r.x,       r.y,       cr, cg, cb, 255)
	sgl.v2f_c4b(r.x + r.w, r.y,       cr, cg, cb, 255)
	sgl.v2f_c4b(r.x + r.w, r.y + r.h, cr, cg, cb, 255)
	sgl.v2f_c4b(r.x,       r.y + r.h, cr, cg, cb, 255)
	sgl.end()
}

draw_rect_alpha :: proc(r: Rect, cr, cg, cb: u8, alpha: f32) {
	a := u8(clamp(alpha, 0, 1) * 255)
	sgl.begin_quads()
	sgl.v2f_c4b(r.x,       r.y,       cr, cg, cb, a)
	sgl.v2f_c4b(r.x + r.w, r.y,       cr, cg, cb, a)
	sgl.v2f_c4b(r.x + r.w, r.y + r.h, cr, cg, cb, a)
	sgl.v2f_c4b(r.x,       r.y + r.h, cr, cg, cb, a)
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

// dim a color channel for disabled-button rendering
shade :: proc(c: u8, f: f32) -> u8 {
	return u8(f32(c) * f)
}

// ---------- 7-segment digits (numbers from rects, zero text modules) ----------
//
//   .top.
//  tl   tr
//   .mid.
//  bl   br
//   .bot.

Seg :: enum {top, tl, tr, mid, bl, br, bot}
Seg_Set :: bit_set[Seg]

DIGIT_SEGS := [10]Seg_Set{
	{.top, .tl, .tr, .bl, .br, .bot},       // 0
	{.tr, .br},                             // 1
	{.top, .tr, .mid, .bl, .bot},           // 2
	{.top, .tr, .mid, .br, .bot},           // 3
	{.tl, .tr, .mid, .br},                  // 4
	{.top, .tl, .mid, .br, .bot},           // 5
	{.top, .tl, .mid, .bl, .br, .bot},      // 6
	{.top, .tr, .br},                       // 7
	{.top, .tl, .tr, .mid, .bl, .br, .bot}, // 8
	{.top, .tl, .tr, .mid, .br, .bot},      // 9
}

digit_w :: proc(h: f32) -> f32 {
	return h * 0.58
}

digit_gap :: proc(h: f32) -> f32 {
	return h * 0.18
}

draw_digit :: proc(x, y, h: f32, d: int, cr, cg, cb: u8, alpha: f32) {
	w := digit_w(h)
	t := h * 0.14
	half := (h - 3 * t) / 2 // vertical segment length (top half == bottom half)
	segs := DIGIT_SEGS[d]
	if .top in segs {draw_rect_alpha({x + t, y, w - 2 * t, t}, cr, cg, cb, alpha)}
	if .mid in segs {draw_rect_alpha({x + t, y + t + half, w - 2 * t, t}, cr, cg, cb, alpha)}
	if .bot in segs {draw_rect_alpha({x + t, y + h - t, w - 2 * t, t}, cr, cg, cb, alpha)}
	if .tl in segs {draw_rect_alpha({x, y + t, t, half}, cr, cg, cb, alpha)}
	if .tr in segs {draw_rect_alpha({x + w - t, y + t, t, half}, cr, cg, cb, alpha)}
	if .bl in segs {draw_rect_alpha({x, y + 2 * t + half, t, half}, cr, cg, cb, alpha)}
	if .br in segs {draw_rect_alpha({x + w - t, y + 2 * t + half, t, half}, cr, cg, cb, alpha)}
}

digit_count :: proc(value: int) -> int {
	n := 1
	v := value
	for v >= 10 {
		v /= 10
		n += 1
	}
	return n
}

number_width :: proc(value: int, h: f32) -> f32 {
	n := digit_count(max(value, 0))
	return f32(n) * digit_w(h) + f32(n - 1) * digit_gap(h)
}

// left-aligned
draw_number :: proc(x, y, h: f32, value: int, cr, cg, cb: u8, alpha: f32) {
	v := max(value, 0)
	n := digit_count(v)
	adv := digit_w(h) + digit_gap(h)
	for i := n - 1; i >= 0; i -= 1 {
		draw_digit(x + f32(i) * adv, y, h, v % 10, cr, cg, cb, alpha)
		v /= 10
	}
}

draw_number_centered :: proc(cx, y, h: f32, value: int, cr, cg, cb: u8, alpha: f32) {
	draw_number(cx - number_width(value, h) / 2, y, h, value, cr, cg, cb, alpha)
}

draw_number_right :: proc(right_x, y, h: f32, value: int, cr, cg, cb: u8, alpha: f32) {
	draw_number(right_x - number_width(value, h), y, h, value, cr, cg, cb, alpha)
}

// ---------- combat math: ONE source of truth ----------
// The UI reads these procs. Nothing else computes damage, rate or dps.

Upgrade :: enum {
	damage,   // +damage per hit
	speed,    // +attacks per second
	vitality, // +max hp and +regen
}

UPGRADE_COST_BASE := [Upgrade]f32{
	.damage   = 10,
	.speed    = 30,
	.vitality = 20,
}

upgrade_levels: [Upgrade]int

upgrade_cost :: proc(u: Upgrade) -> int {
	return int(UPGRADE_COST_BASE[u] * math.pow(f32(COST_GROWTH), f32(upgrade_levels[u])))
}

hero_damage :: proc() -> f32 {
	return DAMAGE_BASE + DAMAGE_PER_LEVEL * f32(upgrade_levels[.damage])
}

hero_attack_rate :: proc() -> f32 {
	return RATE_BASE * (1 + RATE_PER_LEVEL * f32(upgrade_levels[.speed]))
}

// dps = damage * speed. The top-bar readout calls THIS, not its own math.
hero_dps :: proc() -> f32 {
	return hero_damage() * hero_attack_rate()
}

hero_max_hp :: proc() -> f32 {
	return HP_BASE + HP_PER_LEVEL * f32(upgrade_levels[.vitality])
}

hero_regen :: proc() -> f32 {
	return REGEN_BASE + REGEN_PER_LEVEL * f32(upgrade_levels[.vitality])
}

// ---------- wave scaling ----------

is_boss_wave :: proc(w: int) -> bool {
	return w % 10 == 0
}

monster_max_hp_for :: proc(w: int) -> f32 {
	hp := 16 * math.pow(f32(1.17), f32(w - 1))
	if is_boss_wave(w) {hp *= 4.5}
	return hp
}

monster_damage_for :: proc(w: int) -> f32 {
	d := 4 * math.pow(f32(1.06), f32(w - 1))
	if is_boss_wave(w) {d *= 2}
	return d
}

monster_gold_for :: proc(w: int) -> int {
	g := int(4 * math.pow(f32(1.10), f32(w - 1)))
	if is_boss_wave(w) {g *= 5}
	return g
}

MONSTER_COLORS := [6][3]u8{
	{120, 200, 110},
	{205, 150, 90},
	{120, 150, 220},
	{200, 110, 180},
	{215, 200, 90},
	{160, 120, 200},
}

// ---------- entities ----------

Hero :: struct {
	hp:       f32,
	hp_lag:   f32, // trails hp downward — the white "recent damage" segment
	attack_t: f32, // countdown to next swing
	anim_t:   f32, // lunge animation, counts ANIM_TIME -> 0; idle when <= 0
	hit_done: bool, // damage applied at the lunge peak exactly once
	flash:    f32,
	dead:     bool,
	revive_t: f32,
}

Monster :: struct {
	alive:      bool,
	boss:       bool,
	hp:         f32,
	max_hp:     f32,
	hp_lag:     f32,
	damage:     f32,
	size:       f32,
	interval:   f32, // seconds between its attacks
	attack_t:   f32,
	anim_t:     f32,
	hit_done:   bool,
	flash:      f32,
	cr, cg, cb: u8,
}

hero: Hero
monster: Monster
wave: int
gold: int
spawn_t: f32 // delay between monster death and next wave

// ---------- feedback pools (all the same pattern: fixed pool + life) ----------

MAX_PARTICLES :: 256
Particle :: struct {
	active:   bool,
	x, y:     f32,
	vx, vy:   f32,
	size:     f32,
	life:     f32,
	max_life: f32,
	grav:     f32,
	r, g, b:  u8,
}
particles: [MAX_PARTICLES]Particle

MAX_FLOATS :: 32
Float_Num :: struct {
	active:   bool,
	x, y:     f32,
	value:    int,
	h:        f32, // digit height: crits are drawn bigger
	life:     f32,
	max_life: f32,
	r, g, b:  u8,
}
floats: [MAX_FLOATS]Float_Num

// Coins ARE the gold transaction: they scatter, then fly to the counter,
// and only on arrival does `gold` increment. Feedback = state change.
MAX_COINS :: 64
Coin_State :: enum {
	scatter, // physics pop off the corpse
	fly,     // eased flight to the gold counter
}

Coin :: struct {
	active:   bool,
	state:    Coin_State,
	x, y:     f32,
	vx, vy:   f32,
	t:        f32, // scatter: countdown / fly: 0..1 progress
	sx, sy:   f32, // flight start point (captured when scatter ends)
	fly_time: f32,
	value:    int,
}
coins: [MAX_COINS]Coin

// ---------- juice state ----------

shake_t, shake_time, shake_strength: f32
gold_pulse: f32
game_time: f32

// ---------- input / sokol plumbing ----------

mouse_x, mouse_y: f32
clicked: bool

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

// ---------- spawning feedback ----------

add_shake :: proc(strength, duration: f32) {
	remaining := shake_t > 0 ? shake_strength * (shake_t / max(shake_time, 0.001)) : 0
	if strength >= remaining {
		shake_strength = strength
		shake_time = duration
		shake_t = duration
	}
}

spawn_burst :: proc(x, y: f32, count: int, cr, cg, cb: u8, speed, grav: f32) {
	for _ in 0 ..< count {
		for &p in &particles {
			if p.active {continue}
			ang := rand.float32_range(0, math.TAU)
			sp := speed * rand.float32_range(0.4, 1.0)
			p.active = true
			p.x = x
			p.y = y
			p.vx = math.cos(ang) * sp
			p.vy = math.sin(ang) * sp
			p.size = rand.float32_range(3, 7)
			p.life = rand.float32_range(0.25, 0.55)
			p.max_life = p.life
			p.grav = grav
			p.r = cr
			p.g = cg
			p.b = cb
			break
		}
	}
}

spawn_float :: proc(x, y: f32, value: int, h: f32, cr, cg, cb: u8) {
	for &fl in &floats {
		if fl.active {continue}
		fl.active = true
		fl.x = x + rand.float32_range(-8, 8)
		fl.y = y
		fl.value = value
		fl.h = h
		fl.life = 0.8
		fl.max_life = fl.life
		fl.r = cr
		fl.g = cg
		fl.b = cb
		return
	}
}

spawn_coins :: proc(x, y: f32, total: int) {
	n := clamp(3 + total / 8, 3, 12)
	if n > total {n = max(1, total)}
	each := total / n
	rem := total - each * n
	for i in 0 ..< n {
		for &c in &coins {
			if c.active {continue}
			c.active = true
			c.state = .scatter
			c.x = x
			c.y = y
			c.vx = rand.float32_range(-140, 140)
			c.vy = rand.float32_range(-260, -120)
			c.t = rand.float32_range(0.25, 0.45)
			c.fly_time = rand.float32_range(0.40, 0.65)
			c.value = each + (i == 0 ? rem : 0)
			break
		}
	}
}

// ---------- game logic ----------

spawn_monster :: proc() {
	boss := is_boss_wave(wave)
	monster = Monster{
		alive    = true,
		boss     = boss,
		max_hp   = monster_max_hp_for(wave),
		damage   = monster_damage_for(wave),
		size     = boss ? 104 : 62,
		interval = boss ? 2.2 : 1.5,
		attack_t = boss ? 1.4 : 0.9,
	}
	monster.hp = monster.max_hp
	monster.hp_lag = monster.max_hp
	c := MONSTER_COLORS[(wave - 1) % len(MONSTER_COLORS)]
	if boss {c = {205, 75, 75}}
	monster.cr = c[0]
	monster.cg = c[1]
	monster.cb = c[2]
}

reset_game :: proc() {
	gold = 0
	wave = 1
	upgrade_levels = {}
	for &p in &particles {p.active = false}
	for &fl in &floats {fl.active = false}
	for &c in &coins {c.active = false}
	hero = {}
	hero.hp = hero_max_hp()
	hero.hp_lag = hero.hp
	shake_t = 0
	gold_pulse = 0
	spawn_t = 0
	spawn_monster()
	fmt.println("(full reset)")
}

hero_strike :: proc() {
	dmg := hero_damage()
	crit := rand.float32() < CRIT_CHANCE
	if crit {dmg *= CRIT_MULT}
	monster.hp -= dmg
	monster.flash = FLASH_TIME

	hit_x := f32(MONSTER_X) - monster.size / 2
	hit_y := f32(GROUND_Y) - monster.size * 0.6
	spawn_burst(hit_x, hit_y, 10, 255, 230, 150, 160, 500)
	if crit {
		// crits earn the bigger number, the gold color AND a tiny shake
		spawn_float(hit_x, hit_y - 30, int(dmg + 0.5), 26, 255, 205, 70)
		add_shake(4, 0.12)
	} else {
		spawn_float(hit_x, hit_y - 24, int(dmg + 0.5), 16, 235, 235, 235)
	}

	if monster.hp <= 0 {
		kill_monster()
	}
}

kill_monster :: proc() {
	monster.alive = false
	cx := f32(MONSTER_X)
	cy := f32(GROUND_Y) - monster.size / 2
	// the body bursts into its own color...
	spawn_burst(cx, cy, monster.boss ? 60 : 26, monster.cr, monster.cg, monster.cb, 240, 600)
	// ...and the bounty bursts into coins that fly to the counter
	spawn_coins(cx, cy, monster_gold_for(wave))
	if monster.boss {
		add_shake(16, 0.4)
	}
	spawn_t = SPAWN_DELAY
}

monster_strike :: proc() {
	dmg := monster.damage * rand.float32_range(0.85, 1.15)
	hero.hp -= dmg
	hero.flash = FLASH_TIME

	hit_x := f32(HERO_X) + 14
	hit_y := f32(GROUND_Y) - 40
	spawn_burst(hit_x, hit_y, 8, 240, 120, 100, 140, 500)
	spawn_float(hit_x, hit_y - 28, int(dmg + 0.5), 16, 240, 110, 100)
	if monster.boss {
		add_shake(9, 0.22) // boss hits rattle the screen
	}

	if hero.hp <= 0 {
		hero.hp = 0
		hero.dead = true
		hero.revive_t = REVIVE_TIME
		hero.anim_t = 0
		spawn_burst(f32(HERO_X), f32(GROUND_Y) - 32, 24, 120, 160, 230, 200, 550)
	}
}

buy :: proc(u: Upgrade) {
	cost := upgrade_cost(u)
	if gold < cost {return}
	gold -= cost
	upgrade_levels[u] += 1
	if u == .vitality {
		// buying hp also heals the new chunk (feels generous, idle-style)
		hero.hp = min(hero.hp + HP_PER_LEVEL, hero_max_hp())
	}
	r := BUTTON_RECTS[u]
	spawn_burst(r.x + r.w / 2, r.y, 10, 240, 220, 110, 120, 200)
}

// lag bar trails the real value downward; snaps up on heal
update_lag :: proc(lag: ^f32, hp, maxv, dt: f32) {
	if lag^ > hp {
		lag^ = max(hp, lag^ - maxv * 0.8 * dt)
	} else {
		lag^ = hp
	}
}

update_combat :: proc(dt: f32) {
	// hero swings
	if !hero.dead && monster.alive {
		hero.attack_t -= dt
		if hero.attack_t <= 0 && hero.anim_t <= 0 {
			hero.attack_t = 1.0 / hero_attack_rate()
			hero.anim_t = ANIM_TIME
			hero.hit_done = false
		}
	}
	if hero.anim_t > 0 {
		hero.anim_t -= dt
		phase := 1 - max(hero.anim_t, 0) / ANIM_TIME
		// damage lands at the lunge PEAK, not when the timer fired
		if !hero.hit_done && phase >= 0.5 && monster.alive {
			hero.hit_done = true
			hero_strike()
		}
	}

	// monster swings back
	if monster.alive && !hero.dead {
		monster.attack_t -= dt
		if monster.attack_t <= 0 && monster.anim_t <= 0 {
			monster.attack_t = monster.interval
			monster.anim_t = ANIM_TIME
			monster.hit_done = false
		}
	}
	if monster.anim_t > 0 {
		monster.anim_t -= dt
		phase := 1 - max(monster.anim_t, 0) / ANIM_TIME
		if !monster.hit_done && phase >= 0.5 && !hero.dead {
			monster.hit_done = true
			monster_strike()
		}
	}

	// regen + lag bars + flashes
	if !hero.dead {
		hero.hp = min(hero.hp + hero_regen() * dt, hero_max_hp())
	}
	update_lag(&hero.hp_lag, hero.hp, hero_max_hp(), dt)
	update_lag(&monster.hp_lag, monster.hp, monster.max_hp, dt)
	if hero.flash > 0 {hero.flash -= dt}
	if monster.flash > 0 {monster.flash -= dt}

	// next wave after a corpse pause
	if !monster.alive && !hero.dead {
		spawn_t -= dt
		if spawn_t <= 0 {
			wave += 1
			spawn_monster()
		}
	}

	// death is a setback, not a fail state
	if hero.dead {
		hero.revive_t -= dt
		if hero.revive_t <= 0 {
			hero.dead = false
			wave = max(1, wave - DEATH_SETBACK)
			hero.hp = hero_max_hp()
			hero.hp_lag = hero.hp
			hero.attack_t = 0.5
			spawn_monster()
		}
	}
}

update_pools :: proc(dt: f32) {
	for &p in &particles {
		if !p.active {continue}
		p.life -= dt
		if p.life <= 0 {
			p.active = false
			continue
		}
		p.vy += p.grav * dt
		p.x += p.vx * dt
		p.y += p.vy * dt
	}

	for &fl in &floats {
		if !fl.active {continue}
		fl.life -= dt
		if fl.life <= 0 {
			fl.active = false
			continue
		}
		fl.y -= 36 * dt
	}

	for &c in &coins {
		if !c.active {continue}
		switch c.state {
		case .scatter:
			c.vy += 600 * dt
			c.x += c.vx * dt
			c.y += c.vy * dt
			c.t -= dt
			if c.t <= 0 {
				c.state = .fly
				c.sx = c.x
				c.sy = c.y
				c.t = 0
			}
		case .fly:
			c.t += dt / c.fly_time
			e := c.t * c.t // ease-in: coins accelerate toward the counter
			c.x = math.lerp(c.sx, f32(GOLD_TX), e)
			c.y = math.lerp(c.sy, f32(GOLD_TY), e)
			if c.t >= 1 {
				// THE moment: gold changes exactly when the coin lands
				gold += c.value
				gold_pulse = GOLD_PULSE_TIME
				c.active = false
				spawn_burst(GOLD_TX, GOLD_TY, 4, 250, 220, 110, 60, 0)
			}
		}
	}

	if shake_t > 0 {shake_t -= dt}
	if gold_pulse > 0 {gold_pulse -= dt}
}

// ---------- upgrade panel layout ----------

BTN_Y :: 448
BTN_W :: 280
BTN_H :: 76

BUTTON_RECTS := [Upgrade]Rect{
	.damage   = {28, BTN_Y, BTN_W, BTN_H},
	.speed    = {340, BTN_Y, BTN_W, BTN_H},
	.vitality = {652, BTN_Y, BTN_W, BTN_H},
}

// ---------- rect-art icons (an icon system with zero image files) ----------

draw_icon_sword :: proc(x, y, s, f: f32) {
	draw_rect({x + s / 2 - 3, y + 4, 6, s - 22}, shade(205, f), shade(210, f), shade(220, f))
	draw_rect({x + s / 2 - 10, y + s - 18, 20, 5}, shade(170, f), shade(140, f), shade(90, f))
	draw_rect({x + s / 2 - 2, y + s - 13, 4, 10}, shade(130, f), shade(100, f), shade(70, f))
}

draw_icon_bolt :: proc(x, y, s, f: f32) {
	draw_rect({x + s / 2 - 1, y + 5, 9, s / 2 - 8}, shade(240, f), shade(210, f), shade(90, f))
	draw_rect({x + s / 2 - 8, y + s / 2 - 3, 16, 6}, shade(240, f), shade(210, f), shade(90, f))
	draw_rect({x + s / 2 - 8, y + s / 2 + 3, 9, s / 2 - 8}, shade(240, f), shade(210, f), shade(90, f))
}

draw_icon_plus :: proc(x, y, s, f: f32) {
	draw_rect({x + s / 2 - 4, y + 6, 8, s - 12}, shade(225, f), shade(90, f), shade(95, f))
	draw_rect({x + 6, y + s / 2 - 4, s - 12, 8}, shade(225, f), shade(90, f), shade(95, f))
}

draw_coin_icon :: proc(x, y, s, f: f32) {
	draw_rect({x, y, s, s}, shade(240, f), shade(205, f), shade(90, f))
	draw_rect({x + s * 0.25, y + s * 0.25, s * 0.5, s * 0.5}, shade(200, f), shade(160, f), shade(60, f))
}

// ---------- input ----------

handle_click :: proc() {
	for u in Upgrade {
		if point_in_rect(mouse_x, mouse_y, BUTTON_RECTS[u]) {
			buy(u)
			return
		}
	}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	#partial switch e.type {
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x
		mouse_y = e.mouse_y
	case .MOUSE_DOWN:
		if e.mouse_button == .LEFT {clicked = true}
	case .KEY_DOWN:
		#partial switch e.key_code {
		case .R: reset_game()
		}
	}
}

// ---------- drawing ----------

draw_hp_bar :: proc(x, y, w: f32, hp, lag, maxv: f32, cr, cg, cb: u8) {
	draw_rect({x - 1, y - 1, w + 2, 10}, 18, 20, 26)
	draw_rect({x, y, w, 8}, 45, 48, 55)
	lf := clamp(lag / max(maxv, 1), 0, 1)
	hf := clamp(hp / max(maxv, 1), 0, 1)
	// white lag segment first, real bar drawn over it: the visible white
	// sliver between them IS the damage you just took
	draw_rect({x, y, w * lf, 8}, 235, 235, 235)
	draw_rect({x, y, w * hf, 8}, cr, cg, cb)
}

draw_hero :: proc() {
	x := f32(HERO_X)
	y := f32(GROUND_Y)

	if hero.dead {
		// ghost + revive countdown (seconds, 7-seg)
		draw_rect_alpha({x - 14, y - 48, 28, 34}, 150, 160, 180, 0.25)
		draw_rect_alpha({x - 9, y - 64, 18, 15}, 150, 160, 180, 0.25)
		draw_number_centered(x, y - 110, 28, int(hero.revive_t) + 1, 150, 160, 180, 0.8)
		return
	}

	phase: f32 = 0
	if hero.anim_t > 0 {phase = 1 - hero.anim_t / ANIM_TIME}
	ox := math.sin(phase * math.PI) * HERO_LUNGE // out and back in one sine
	bob: f32 = 0
	if hero.anim_t <= 0 {bob = math.sin(game_time * 2.4) * 2.5} // idle breathing
	hx := x + ox
	hy := y + bob

	flash := hero.flash > 0
	br, bg_, bb: u8 = 90, 145, 225
	hr, hg, hb: u8 = 235, 205, 165
	if flash {
		br, bg_, bb = 255, 255, 255
		hr, hg, hb = 255, 255, 255
	}

	// legs / body / head
	draw_rect({hx - 12, hy - 14, 9, 14}, shade(br, 0.6), shade(bg_, 0.6), shade(bb, 0.6))
	draw_rect({hx + 3, hy - 14, 9, 14}, shade(br, 0.6), shade(bg_, 0.6), shade(bb, 0.6))
	draw_rect({hx - 14, hy - 48, 28, 34}, br, bg_, bb)
	draw_rect({hx - 9, hy - 64, 18, 15}, hr, hg, hb)

	// sword arm: blade extends a touch at the lunge peak
	ext := math.sin(phase * math.PI) * 12
	draw_rect({hx + 12, hy - 42, 10, 7}, hr, hg, hb)
	draw_rect({hx + 18, hy - 48, 5, 12}, 170, 140, 90)
	draw_rect({hx + 22, hy - 45, 30 + ext, 6}, 205, 210, 220)

	// hp bar anchored to the arena, not the bobbing body
	draw_hp_bar(x - 45, y - 96, 90, hero.hp, hero.hp_lag, hero_max_hp(), 95, 205, 115)
}

draw_monster :: proc() {
	if !monster.alive {return}

	phase: f32 = 0
	if monster.anim_t > 0 {phase = 1 - monster.anim_t / ANIM_TIME}
	ox := -math.sin(phase * math.PI) * MONSTER_LUNGE // lunges left, toward the hero
	s := monster.size
	x := f32(MONSTER_X) + ox
	y := f32(GROUND_Y)

	cr, cg, cb := monster.cr, monster.cg, monster.cb
	if monster.flash > 0 {cr, cg, cb = 255, 255, 255}

	body := Rect{x - s / 2, y - s, s, s}
	draw_rect(body, cr, cg, cb)

	// boss horns
	if monster.boss {
		draw_rect({body.x + 6, body.y - 14, 11, 14}, 230, 220, 200)
		draw_rect({body.x + s - 17, body.y - 14, 11, 14}, 230, 220, 200)
	}

	// eyes (red-eyed when boss)
	ew := s * 0.14
	ey := body.y + s * 0.28
	er, eg, eb: u8 = monster.boss ? 240 : 250, monster.boss ? 80 : 250, monster.boss ? 80 : 250
	draw_rect({x - s * 0.26, ey, ew, ew}, er, eg, eb)
	draw_rect({x + s * 0.26 - ew, ey, ew, ew}, er, eg, eb)
	draw_rect({x - s * 0.26 + ew * 0.3, ey + ew * 0.3, ew * 0.4, ew * 0.4}, 25, 25, 30)
	draw_rect({x + s * 0.26 - ew * 0.7, ey + ew * 0.3, ew * 0.4, ew * 0.4}, 25, 25, 30)

	bw: f32 = monster.boss ? 130 : 90
	draw_hp_bar(f32(MONSTER_X) - bw / 2, y - s - (monster.boss ? 42 : 26), bw,
		monster.hp, monster.hp_lag, monster.max_hp, 210, 80, 80)
}

draw_pools :: proc() {
	for p in particles {
		if !p.active {continue}
		alpha := p.life / p.max_life
		size := p.size * (0.5 + alpha)
		draw_rect_alpha({p.x - size / 2, p.y - size / 2, size, size}, p.r, p.g, p.b, alpha)
	}
	for fl in floats {
		if !fl.active {continue}
		alpha := fl.life / fl.max_life
		draw_number_centered(fl.x, fl.y, fl.h, fl.value, fl.r, fl.g, fl.b, alpha)
	}
}

draw_coins :: proc() {
	for c in coins {
		if !c.active {continue}
		size: f32 = c.state == .fly ? 10 - 3 * c.t : 10
		draw_rect({c.x - size / 2, c.y - size / 2, size, size}, 240, 205, 90)
		draw_rect({c.x - size * 0.2, c.y - size * 0.2, size * 0.4, size * 0.4}, 200, 160, 60)
	}
}

draw_top_bar :: proc() {
	draw_rect({0, 0, W, 44}, 16, 18, 24)
	draw_rect({0, 44, W, 2}, 50, 54, 64)

	// gold (left): icon + number; pulses bigger when a coin lands
	draw_coin_icon(20, 16, 20, 1)
	gh := 24 + 8 * max(gold_pulse, 0) / GOLD_PULSE_TIME
	draw_number(50, 15, gh, gold, 240, 205, 90, 1)

	// wave (center): flag icon + number; red on boss waves
	cx := f32(W) / 2
	wpx := number_width(wave, 24)
	draw_rect({cx - wpx / 2 - 28, 12, 4, 26}, 160, 165, 175) // flag pole
	if is_boss_wave(wave) {
		draw_rect({cx - wpx / 2 - 24, 12, 16, 10}, 235, 90, 90)
		draw_number(cx - wpx / 2, 15, 24, wave, 235, 90, 90, 1)
	} else {
		draw_rect({cx - wpx / 2 - 24, 12, 16, 10}, 110, 180, 230)
		draw_number(cx - wpx / 2, 15, 24, wave, 210, 215, 225, 1)
	}

	// dps (right): sword icon + number — READS hero_dps(), the one truth
	dps := int(hero_dps() + 0.5)
	dpx := number_width(dps, 24)
	draw_number(f32(W) - 24 - dpx, 15, 24, dps, 150, 200, 240, 1)
	draw_icon_sword(f32(W) - 24 - dpx - 34, 12, 28, 1)
}

draw_button :: proc(u: Upgrade) {
	r := BUTTON_RECTS[u]
	cost := upgrade_cost(u)
	afford := gold >= cost
	hover := point_in_rect(mouse_x, mouse_y, r)
	f: f32 = afford ? 1.0 : 0.45 // unaffordable = everything dims

	bg: u8 = hover && afford ? 56 : 42
	draw_rect(r, shade(bg, f), shade(bg + 4, f), shade(bg + 14, f))
	if hover && afford {
		draw_outline(r, 240, 220, 90)
	} else {
		draw_outline(r, shade(110, f), shade(118, f), shade(135, f))
	}

	// icon (left)
	switch u {
	case .damage:   draw_icon_sword(r.x + 12, r.y + 10, 56, f)
	case .speed:    draw_icon_bolt(r.x + 12, r.y + 10, 56, f)
	case .vitality: draw_icon_plus(r.x + 12, r.y + 10, 56, f)
	}

	// owned level (top right) + cost (coin + 7-seg, bottom)
	draw_number_right(r.x + r.w - 12, r.y + 10, 16, upgrade_levels[u],
		shade(200, f), shade(205, f), shade(215, f), 1)
	draw_coin_icon(r.x + 84, r.y + 46, 16, f)
	draw_number(r.x + 108, r.y + 44, 20, cost, shade(240, f), shade(205, f), shade(90, f), 1)
}

// ---------- sokol callbacks ----------

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.06, g = 0.07, b = 0.10, a = 1}}},
	}
	reset_game()
	fmt.println("p09 idle auto-battler: every number change must be SEEN. R = reset.")
}

frame :: proc "c" () {
	context = rt_ctx
	dt := min(f32(sapp.frame_duration()), 0.05)
	game_time += dt

	if clicked {
		clicked = false
		handle_click()
	}

	update_combat(dt)
	update_pools(dt)

	// background "breathing": slow color lerp on the clear color itself
	breath := (math.sin(game_time * 0.35) + 1) * 0.5
	pass_action.colors[0].clear_value = {
		r = 0.05 + 0.030 * breath,
		g = 0.06 + 0.015 * breath,
		b = 0.10 + 0.040 * breath,
		a = 1,
	}

	// screen shake offset (t10): decaying wobble
	shake_x, shake_y: f32
	if shake_t > 0 {
		strength := shake_strength * (shake_t / max(shake_time, 0.001))
		t := f32(sapp.frame_count()) * 0.45
		shake_x = math.sin(t * 3.1) * strength
		shake_y = math.cos(t * 4.2) * strength * 0.6
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)
	sgl.matrix_mode_modelview()
	sgl.push_matrix()
	sgl.translate(shake_x, shake_y, 0)

	// --- world (shaken): ground, fighters, particles, damage numbers ---
	draw_rect({0, GROUND_Y, W, PANEL_Y - GROUND_Y}, 40, 44, 52)
	draw_hero()
	draw_monster()
	draw_pools()

	sgl.pop_matrix()

	// --- screen space (NOT shaken): coins must hit a stable counter ---
	draw_coins()
	draw_top_bar()

	// upgrade panel
	draw_rect({0, PANEL_Y, W, H - PANEL_Y}, 24, 26, 32)
	draw_rect({0, PANEL_Y, W, 2}, 70, 75, 90)
	for u in Upgrade {
		draw_button(u)
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
		window_title = "P09 - Idle Auto-Battler",
		logger = {func = slog.func},
	})
}
