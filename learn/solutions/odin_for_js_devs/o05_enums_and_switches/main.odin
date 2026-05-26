package o05_enums_and_switches

import "core:fmt"

Direction :: enum {
	up,
	down,
	left,
	right,
}

describe_direction :: proc(dir: Direction) {
	switch dir {
	case .up:    fmt.println("  Moving up")
	case .down:  fmt.println("  Moving down")
	case .left:  fmt.println("  Moving left")
	case .right: fmt.println("  Moving right")
	}
}

Tile_Kind :: enum u8 {
	empty,
	wall,
	goal,
	spike,
}

tile_char :: proc(t: Tile_Kind) -> u8 {
	switch t {
	case .empty: return '.'
	case .wall:  return '#'
	case .goal:  return 'G'
	case .spike: return '!'
	}
	return '?'
}

Game_State :: enum {
	menu,
	playing,
	paused,
	game_over,
}

Entity_Kind :: enum { player, enemy, box }

Entity :: struct {
	kind: Entity_Kind,
	x, y: f32,
	name: string,
}

describe_entity :: proc(e: Entity) {
	switch e.kind {
	case .player: fmt.printf("  Player '%s' at (%f, %f)\n", e.name, e.x, e.y)
	case .enemy:  fmt.printf("  Enemy '%s' at (%f, %f)\n", e.name, e.x, e.y)
	case .box:    fmt.printf("  Box '%s' at (%f, %f)\n", e.name, e.x, e.y)
	}
}

main :: proc() {
	// --- Basic enum usage ---
	fmt.println("Directions:")
	dir := Direction.up
	describe_direction(dir)
	describe_direction(.left)

	// --- Iterate over enum ---
	fmt.println("\nAll directions:")
	for d in Direction {
		fmt.println(" ", d)
	}

	// --- Tile grid using enum u8 ---
	fmt.println("\nTile grid (3x3):")
	grid := [3][3]Tile_Kind{
		{ .wall,  .wall,  .wall },
		{ .wall,  .goal,  .empty },
		{ .wall,  .spike, .wall },
	}
	for row in grid {
		for tile in row {
			fmt.printf("%c ", tile_char(tile))
		}
		fmt.println()
	}

	// --- Game state ---
	state := Game_State.playing
	#partial switch state {
	case .playing: fmt.println("\nGame is running")
	case .paused:  fmt.println("\nGame is paused")
	}

	// --- Entity with enum kind ---
	fmt.println("\nEntities:")
	entities := [3]Entity{
		{ kind = .player, x = 100, y = 200, name = "hero" },
		{ kind = .enemy,  x = 300, y = 150, name = "goblin" },
		{ kind = .box,    x = 200, y = 200, name = "crate" },
	}
	for e in entities {
		describe_entity(e)
	}

	// --- Key size demo ---
	fmt.println("\n--- Memory ---")
	fmt.printf("Tile_Kind (u8 enum):  %d byte per value\n", size_of(Tile_Kind))
	fmt.printf("Direction (int enum): %d bytes per value\n", size_of(Direction))
	fmt.println("For 10000 tiles:")
	fmt.printf("  u8  enum = %d bytes\n", 10000 * size_of(Tile_Kind))
	fmt.printf("  int enum = %d bytes\n", 10000 * size_of(Direction))

	fmt.println("\n--- Takeaways ---")
	fmt.println("Enums = finite named sets. Compiler enforces completeness.")
	fmt.println("switch = exhaustive by default. #partial = opt out.")
	fmt.println("No fall-through. No break needed. No string comparison.")
}
