package o12_for_loops_and_iteration

import "core:fmt"

main :: proc() {
	// === 1. Range loops ===
	fmt.println("=== Range Loops ===")
	fmt.print("  0..<5: ")
	for i in 0..<5 { fmt.printf("%d ", i) }
	fmt.println()

	fmt.print("  1..=5: ")
	for i in 1..=5 { fmt.printf("%d ", i) }
	fmt.println()

	// === 2. Array iteration (value + index) ===
	fmt.println("\n=== Array Iteration ===")
	names := [4]string{ "Alice", "Bob", "Charlie", "Diana" }
	for name, i in names {
		fmt.printf("  [%d] %s\n", i, name)
	}

	// === 3. Mutable iteration ===
	fmt.println("\n=== Mutable Iteration ===")
	values: [4]f32 = {1, 2, 3, 4}
	fmt.print("  before: ")
	for v in values { fmt.printf("%.0f ", v) }
	fmt.println()

	for &v in &values {
		v *= 2   // modifies in place
	}
	fmt.print("  after:  ")
	for v in values { fmt.printf("%.0f ", v) }
	fmt.println()

	// === 4. Dynamic array with reverse removal ===
	fmt.println("\n=== Reverse Removal ===")
	Entity :: struct { name: string, alive: bool }
	entities: [dynamic]Entity
	defer delete(entities)

	append(&entities, Entity{ "hero", true })
	append(&entities, Entity{ "ghost", false })
	append(&entities, Entity{ "goblin", true })
	append(&entities, Entity{ "zombie", false })
	append(&entities, Entity{ "dragon", true })

	fmt.println("  before removal:")
	for e in entities { fmt.printf("    %s (alive=%v)\n", e.name, e.alive) }

	#reverse for &e, i in &entities {
		if !e.alive {
			ordered_remove(&entities, i)
		}
	}

	fmt.println("  after removing dead:")
	for e in entities { fmt.printf("    %s (alive=%v)\n", e.name, e.alive) }

	// === 5. Nested loop with labeled break ===
	fmt.println("\n=== Nested Loop + Break ===")
	grid := [3][3]i32{
		{0, 0, 0},
		{0, 0, 42},
		{0, 0, 0},
	}
	outer: for row, r in grid {
		for cell, c in row {
			if cell == 42 {
				fmt.printf("  Found 42 at row=%d col=%d\n", r, c)
				break outer
			}
		}
	}

	// === 6. Condition loop (while) ===
	fmt.println("\n=== Condition Loop ===")
	x := 1
	for x < 100 {
		x *= 2
	}
	fmt.println("  x after doubling until >= 100:", x)

	// === 7. Sum pattern (replaces .reduce) ===
	fmt.println("\n=== Sum (no .reduce) ===")
	scores := [5]i32{10, 20, 30, 40, 50}
	total : i32 = 0
	for s in scores { total += s }
	fmt.println("  sum:", total)

	// === 8. Filter pattern (replaces .filter) ===
	fmt.println("\n=== Filter (no .filter) ===")
	active_count := 0
	for e in entities {
		if e.alive {
			active_count += 1
		}
	}
	fmt.println("  active entities:", active_count)

	// === Key takeaways ===
	fmt.println("\n--- Takeaways ---")
	fmt.println("  for i in 0..<N    range (exclusive end)")
	fmt.println("  for i in 0..=N    range (inclusive end)")
	fmt.println("  for v in array    iterate by copy")
	fmt.println("  for &v in &array  iterate by reference (mutable)")
	fmt.println("  for v, i in array iterate with index")
	fmt.println("  #reverse for      safe removal during iteration")
	fmt.println("  No .map/.filter/.reduce. Loops only.")
}
