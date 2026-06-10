package o17_maps_and_lookups

import "core:fmt"

Entity :: struct {
	hp: int,
}

main :: proc() {
	// --- Create a map (heap allocated — pairs with delete) ---
	names := make(map[int]string)
	defer delete(names)

	// --- Insert / update / lookup ---
	names[42] = "goblin"
	names[42] = "hobgoblin" // update, same syntax
	names[7] = "crate"

	name, ok := names[42]
	fmt.println("lookup 42:", name, "ok =", ok)

	missing, ok2 := names[999]
	fmt.printf("lookup 999: %q ok = %v  <- zero value, not undefined\n", missing, ok2)

	// --- `in` operator + delete_key ---
	if 7 in names {
		fmt.println("entity 7 exists")
	}
	delete_key(&names, 7)
	if 7 not_in names {
		fmt.println("entity 7 removed")
	}

	// --- Iteration (order is random!) ---
	for id, n in names {
		fmt.println("  entity", id, "->", n)
	}

	// --- Inventory: map[string]int ---
	inventory := make(map[string]int)
	defer delete(inventory)

	inventory["potion"] = 3
	inventory["key"] = 1
	inventory["potion"] += 1 // missing key would start from zero value 0

	fmt.println("\nInventory:")
	for item, count in inventory {
		fmt.printf("  %s x%d\n", item, count)
	}
	sword_count := inventory["sword"]
	fmt.println("swords (missing key, zero value):", sword_count)

	// --- Enumerated array: better than map for dense enum keys ---
	Sound :: enum {
		jump,
		land,
		win,
	}
	volumes := [Sound]f32{
		.jump = 0.8,
		.land = 1.0,
		.win  = 0.6,
	}
	// no make, no delete — fixed array, one slot per enum value
	fmt.println("\nVolumes:")
	for s in Sound {
		fmt.printf("  %v = %.1f\n", s, volumes[s])
	}

	// --- Mutating struct values inside a map ---
	entities := make(map[int]Entity)
	defer delete(entities)
	entities[1] = Entity{hp = 10}

	// WRONG: plain lookup copies — original unchanged
	e_copy := entities[1]
	e_copy.hp -= 4
	fmt.println("\nafter copy mutation, map hp =", entities[1].hp) // still 10

	// RIGHT: &m[k] gives a pointer into the map
	if e, ok3 := &entities[1]; ok3 {
		e.hp -= 4
	}
	fmt.println("after &-mutation, map hp =", entities[1].hp) // 6

	fmt.println("\n--- Takeaways ---")
	fmt.println("make pairs with delete. No GC.")
	fmt.println("Lookup = (value, ok). No undefined.")
	fmt.println("Dense enum keys -> [Enum]T array, not map.")
	fmt.println("Mutate in place with &m[k], plain lookup copies.")
}
