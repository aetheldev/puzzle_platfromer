package o04_structs_not_classes

import "core:fmt"
import "core:math"

Player :: struct {
	x, y:     f32,
	health:   i32,
	is_alive: bool,
}

move_player :: proc(p: ^Player, dx, dy: f32) {
	p.x += dx
	p.y += dy
}

take_damage :: proc(p: ^Player, amount: i32) {
	p.health -= amount
	if p.health <= 0 {
		p.is_alive = false
	}
}

print_player :: proc(label: string, p: Player) {
	fmt.printf("%s: pos=(%f, %f) hp=%d alive=%v\n", label, p.x, p.y, p.health, p.is_alive)
}

main :: proc() {
	// --- Create a player (stack allocated, no `new`, no GC) ---
	player := Player{
		x = 100,
		y = 200,
		health = 100,
		is_alive = true,
	}
	print_player("initial", player)

	// --- Copy behavior demo ---
	// In JS: const b = a; — b references same object
	// In Odin: b := a — b is a COMPLETE COPY
	copy := player
	copy.x = 999
	fmt.println("\nAfter copy.x = 999:")
	print_player("original", player)   // x still 100
	print_player("copy", copy)         // x is 999
	fmt.println("  ^ original unchanged because copy is separate data")

	// --- Pointer mutation demo ---
	// ^Player = pointer to Player
	// &player = address of player
	fmt.println("\nBefore move_player:")
	print_player("player", player)

	move_player(&player, 5, 0)         // modifies original through pointer
	take_damage(&player, 30)

	fmt.println("After move + damage:")
	print_player("player", player)     // x is 105, health is 70

	// --- Zero value demo ---
	empty := Player{}
	print_player("\nzero-value", empty)  // all fields are 0/false
	fmt.println("  ^ in Odin, uninitialized fields are zero, not undefined")

	// --- Factory proc (replaces constructor) ---
	make_player :: proc(x, y: f32) -> Player {
		return Player{
			x = x,
			y = y,
			health = 100,
			is_alive = true,
		}
	}

	p2 := make_player(300, 400)
	print_player("\nfactory-made", p2)

	// --- Vec2 example (common in game dev) ---
	Vec2 :: struct { x, y: f32 }

	vec := Vec2{ 3, 4 }
	length := math.sqrt(vec.x * vec.x + vec.y * vec.y)
	fmt.printf("\nVec2(%f, %f) length = %f\n", vec.x, vec.y, length)

	// --- Key takeaways ---
	fmt.println("\n---")
	fmt.println("Structs = plain data. No methods. No this.")
	fmt.println("Assignment copies entire struct.")
	fmt.println("Use ^ and & for mutation through pointers.")
	fmt.println("Zero-initialized by default. No undefined.")
}
