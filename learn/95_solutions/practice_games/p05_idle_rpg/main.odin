// PRACTICE GAME 05 - Idle RPG (console, zero graphics)
// ====================================================
// GOAL: Pick a class. Hunt monsters that scale with your level.
//       Loot drops. Equip decisions. Numbers go up. The o-track
//       alone is enough to build a real game.
//
// WHAT THIS COMBINES:
//   - o04 structs (Stats, Item, Player, Monster)
//   - o05 enums + exhaustive switch (Class, Slot, Rarity)
//   - o06 dynamic arrays (inventory)
//   - o17 enumerated arrays ([Slot]..., [Rarity]..., [Class]...)
//   - o18 Maybe(T) (equipment slots can be empty)
//   - o12 loops, o16 rand + printing
//
// RUN: zsh build.sh   (menu: 1 = hunt, 2 = inventory, 3 = stats, q = quit)

package p05_idle_rpg

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"

// ---------- character data ----------

Class :: enum {
	warrior,
	mage,
	rogue,
	priest,
}

Stats :: struct {
	max_hp:  int,
	attack:  int,
	defense: int,
	speed:   int,
}

// base stats and per-level growth, per class (o17: enumerated arrays)
BASE := [Class]Stats{
	.warrior = {max_hp = 50, attack = 8, defense = 6, speed = 4},
	.mage    = {max_hp = 30, attack = 14, defense = 2, speed = 5},
	.rogue   = {max_hp = 38, attack = 10, defense = 3, speed = 9},
	.priest  = {max_hp = 42, attack = 6, defense = 4, speed = 5},
}
GROWTH := [Class]Stats{
	.warrior = {max_hp = 8, attack = 2, defense = 2, speed = 1},
	.mage    = {max_hp = 4, attack = 4, defense = 1, speed = 1},
	.rogue   = {max_hp = 5, attack = 3, defense = 1, speed = 2},
	.priest  = {max_hp = 6, attack = 2, defense = 1, speed = 1},
}

// ---------- items ----------

Slot :: enum {
	weapon,
	armor,
	trinket,
}

Rarity :: enum {
	common,
	rare,
	epic,
}

RARITY_NAME := [Rarity]string{.common = "Common", .rare = "RARE", .epic = "*EPIC*"}
RARITY_MULT := [Rarity]int{.common = 1, .rare = 2, .epic = 4}
DROP_CHANCE := [Rarity]f32{.common = 0.35, .rare = 0.10, .epic = 0.02}

ITEM_NAMES := [Slot][3]string{
	.weapon  = {"Rusty Blade", "Soldier's Sword", "Dragonfang"},
	.armor   = {"Cloth Vest", "Chainmail", "Aegis Plate"},
	.trinket = {"Bone Charm", "Silver Ring", "Phoenix Feather"},
}

Item :: struct {
	slot:     Slot,
	rarity:   Rarity,
	name_idx: int, // index into ITEM_NAMES[slot]
	bonus:    Stats,
}

item_label :: proc(it: Item) -> string {
	// temp allocator string — fine for immediate printing (o08)
	return fmt.tprintf(
		"[%v] %s (%v)  +%d hp +%d atk +%d def +%d spd",
		RARITY_NAME[it.rarity], ITEM_NAMES[it.slot][it.name_idx], it.slot,
		it.bonus.max_hp, it.bonus.attack, it.bonus.defense, it.bonus.speed,
	)
}

roll_item :: proc(player_level: int) -> (Item, bool) {
	roll := rand.float32()
	rarity: Rarity
	switch {
	case roll < DROP_CHANCE[.epic]:
		rarity = .epic
	case roll < DROP_CHANCE[.epic] + DROP_CHANCE[.rare]:
		rarity = .rare
	case roll < DROP_CHANCE[.epic] + DROP_CHANCE[.rare] + DROP_CHANCE[.common]:
		rarity = .common
	case:
		return {}, false // no drop
	}

	slot := rand.choice_enum(Slot)
	mult := RARITY_MULT[rarity]
	it := Item {
		slot     = slot,
		rarity   = rarity,
		name_idx = int(rarity), // nicer names at higher rarity
		bonus    = Stats{},
	}
	// each slot favors a stat; scaled by level and rarity
	switch slot {
	case .weapon:  it.bonus.attack = (1 + player_level/2) * mult
	case .armor:   it.bonus.defense = (1 + player_level/3) * mult; it.bonus.max_hp = 2 * mult
	case .trinket: it.bonus.speed = mult; it.bonus.max_hp = player_level * mult
	}
	return it, true
}

// ---------- player ----------

Player :: struct {
	class:     Class,
	level:     int,
	xp:        int,
	stats:     Stats, // base+growth only; gear added via total_stats
	equipped:  [Slot]Maybe(Item), // o18: slots can be empty
	inventory: [dynamic]Item,
	kills:     int,
}

total_stats :: proc(p: ^Player) -> Stats {
	t := p.stats
	for slot in Slot {
		if it, ok := p.equipped[slot].?; ok {
			t.max_hp += it.bonus.max_hp
			t.attack += it.bonus.attack
			t.defense += it.bonus.defense
			t.speed += it.bonus.speed
		}
	}
	return t
}

xp_to_level :: proc(level: int) -> int {
	return level * 100
}

gain_xp :: proc(p: ^Player, amount: int) {
	p.xp += amount
	for p.xp >= xp_to_level(p.level) {
		p.xp -= xp_to_level(p.level)
		p.level += 1
		g := GROWTH[p.class]
		p.stats.max_hp += g.max_hp
		p.stats.attack += g.attack
		p.stats.defense += g.defense
		p.stats.speed += g.speed
		fmt.println(">>> LEVEL UP! Now level", p.level)
	}
}

// ---------- monsters ----------

MONSTER_NAMES := [?]string{"Rat", "Goblin", "Wolf", "Bandit", "Ogre", "Wraith", "Drake"}

Monster :: struct {
	name:  string,
	level: int,
	hp:    int,
	stats: Stats,
}

spawn_monster :: proc(player_level: int) -> Monster {
	lvl := max(1, player_level + rand.int_max(3) - 1) // player level -1..+1
	tier := min(len(MONSTER_NAMES) - 1, lvl / 2)
	name := MONSTER_NAMES[rand.int_max(tier + 1)]
	s := Stats {
		max_hp  = 15 + lvl * 6,
		attack  = 3 + lvl * 2,
		defense = 1 + lvl,
		speed   = 3 + lvl/2,
	}
	return Monster{name = name, level = lvl, hp = s.max_hp, stats = s}
}

// ---------- combat ----------

damage :: proc(attack, defense: int) -> int {
	base := max(1, attack - defense/2)
	return base + rand.int_max(max(1, base/2)) // +0..50% variance
}

fight :: proc(p: ^Player) -> bool {
	m := spawn_monster(p.level)
	ps := total_stats(p)
	php := ps.max_hp

	fmt.printf("\nA level %d %s appears! (%d hp)\n", m.level, m.name, m.hp)

	player_turn := ps.speed >= m.stats.speed
	for php > 0 && m.hp > 0 {
		if player_turn {
			dmg := damage(ps.attack, m.stats.defense)
			// rogue crits: speed-based chance for double damage
			if p.class == .rogue && rand.float32() < 0.10 + f32(ps.speed) * 0.01 {
				dmg *= 2
				fmt.print("  CRIT! ")
			} else {
				fmt.print("  ")
			}
			m.hp -= dmg
			fmt.printf("you hit %s for %d (%d left)\n", m.name, dmg, max(0, m.hp))
		} else {
			dmg := damage(m.stats.attack, ps.defense)
			php -= dmg
			fmt.printf("  %s hits you for %d (%d left)\n", m.name, dmg, max(0, php))
		}
		player_turn = !player_turn
	}

	if php <= 0 {
		fmt.println("You were defeated... you wake at camp. (no xp this fight)")
		return false
	}

	p.kills += 1
	xp := 20 + m.level * 15
	fmt.printf("%s slain! +%d xp\n", m.name, xp)
	gain_xp(p, xp)

	// priest passive: tends wounds after battle (flavor — hp resets per fight here)
	if p.class == .priest {
		fmt.println("  (you say a quick prayer and bind your wounds)")
	}

	if it, dropped := roll_item(p.level); dropped {
		fmt.println("  DROP:", item_label(it))
		append(&p.inventory, it)
	}
	return true
}

// ---------- menus ----------

// returns (line, ok). ok=false means stdin closed (EOF) — treat as quit.
read_line :: proc(buf: []u8) -> (string, bool) {
	n, err := os.read(os.stdin, buf)
	if err != nil || n <= 0 {
		return "", false
	}
	s := string(buf[:n])
	// keep only the first line if more arrived (e.g. piped input)
	if nl := strings.index_byte(s, '\n'); nl >= 0 {
		s = s[:nl]
	}
	return strings.trim_space(s), true
}

show_stats :: proc(p: ^Player) {
	t := total_stats(p)
	fmt.printf(
		"\n== %v, level %d ==\nxp %d / %d   kills %d\nhp %d  atk %d  def %d  spd %d (gear included)\n",
		p.class, p.level, p.xp, xp_to_level(p.level), p.kills,
		t.max_hp, t.attack, t.defense, t.speed,
	)
	for slot in Slot {
		if it, ok := p.equipped[slot].?; ok {
			fmt.printf("  %v: %s\n", slot, item_label(it))
		} else {
			fmt.printf("  %v: (empty)\n", slot)
		}
	}
}

inventory_menu :: proc(p: ^Player, buf: []u8) {
	for {
		if len(p.inventory) == 0 {
			fmt.println("\nInventory empty. Go hunt.")
			return
		}
		fmt.println("\n== Inventory == (number = equip, b = back)")
		for it, i in p.inventory {
			fmt.printf("  %d) %s\n", i + 1, item_label(it))
		}
		input, ok := read_line(buf)
		if !ok || input == "b" || input == "" {
			return
		}
		idx := -1
		for it, i in p.inventory {
			_ = it
			if input == fmt.tprintf("%d", i + 1) {
				idx = i
				break
			}
		}
		if idx < 0 {
			fmt.println("?")
			continue
		}
		chosen := p.inventory[idx]
		// swap: old equipped item (if any) returns to inventory
		if old, ok := p.equipped[chosen.slot].?; ok {
			p.inventory[idx] = old
			fmt.println("Swapped out:", item_label(old))
		} else {
			unordered_remove(&p.inventory, idx)
		}
		p.equipped[chosen.slot] = chosen
		fmt.println("Equipped:", item_label(chosen))
	}
}

main :: proc() {
	buf: [256]u8

	fmt.println("==== IDLE RPG ====")
	fmt.println("Choose your class: 1) warrior  2) mage  3) rogue  4) priest")

	class: Class
	for {
		line, ok := read_line(buf[:])
		if !ok {
			return // stdin closed
		}
		switch line {
		case "1": class = .warrior
		case "2": class = .mage
		case "3": class = .rogue
		case "4": class = .priest
		case:
			fmt.println("1-4:")
			continue
		}
		break
	}

	p := Player {
		class = class,
		level = 1,
		stats = BASE[class],
	}
	defer delete(p.inventory)

	fmt.printf("\nYou are a %v. The hunt begins.\n", class)

	for {
		fmt.println("\n[1] hunt (5 fights)  [2] inventory  [3] stats  [q] quit")
		line, ok := read_line(buf[:])
		if !ok {
			line = "q" // stdin closed -> quit cleanly
		}
		switch line {
		case "1":
			for _ in 0 ..< 5 {
				if !fight(&p) {
					break // defeat ends the hunt early
				}
			}
		case "2":
			inventory_menu(&p, buf[:])
		case "3":
			show_stats(&p)
		case "q":
			fmt.printf("\nFinal: %v level %d, %d kills. Numbers went up.\n", p.class, p.level, p.kills)
			return
		case:
			fmt.println("?")
		}
	}
}
