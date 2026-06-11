package o08_memory_without_gc

import "core:fmt"

Player :: struct {
	x, y:   f32,
	health: i32,
	active: bool,
}

main :: proc() {
	player := Player {
		x      = 100,
		y      = 200,
		health = 100,
		active = true,
	}
	fmt.printf("  stack player: pos=(%f,%f) hp=%d\n", player.x, player.y, player.health)
	fmt.println("  No new(). No free(). Dies when main() returns.")

	p := new(Player)
	defer free(p)

	p.x = 300
	p.y = 400
	p.health = 50
	p.active = true
	fmt.printf("  heap player: pos=(%f,%f) hp=%d\n", p.x, p.y, p.health)
	fmt.println("  Used new(). Will be freed by defer free(p).")

	fmt.println("\n=== Temp Allocator ===")
	label := fmt.tprintf("HP: %d / %d", 75, 100)
	fmt.println("  temp string:", label)
	fmt.println("  No free needed. Temp allocator clears at frame end.")
	fmt.println("  In game code, sauce/core_main.odin resets it each frame.")


  	// === 4. Fixed pool pattern (zero allocations) ===
	fmt.println("\n=== Fixed Pool Pattern ===")
	MAX :: 10
	pool: [MAX]Player

	// Activate 3 players
	pool[0] = { x = 10, y = 20, health = 100, active = true }
	pool[1] = { x = 30, y = 40, health = 80, active = true }
	pool[2] = { x = 50, y = 60, health = 60, active = true }
	// pool[3..9] stay zero-valued: active = false

	active_count := 0
	for p, i in pool {
		if p.active {
			fmt.printf("  pool[%d]: pos=(%f,%f) hp=%d\n", i, p.x, p.y, p.health)
			active_count += 1
		}
	}
	fmt.printf("  %d/%d active. Zero heap allocation. Array on stack.\n", active_count, MAX)

	// === 5. Size awareness ===
	fmt.println("\n=== Size Awareness ===")
	fmt.printf("  Player struct size: %d bytes\n", size_of(Player))
	fmt.printf("  Pool of %d players: %d bytes\n", MAX, MAX * size_of(Player))
	fmt.printf("  f32: %d bytes, i32: %d bytes, bool: %d byte\n",
		size_of(f32), size_of(i32), size_of(bool))
}

