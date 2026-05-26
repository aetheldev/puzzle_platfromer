package o06_arrays_slices_dynamic

import "core:fmt"

main :: proc() {
	// --- 1. Fixed array ---
	fmt.println("=== Fixed Array ===")
	scores: [5]i32 = {10, 20, 30, 40, 50}
	for score, i in scores {
		fmt.printf("  scores[%d] = %d\n", i, score)
	}
	fmt.printf("  len = %d\n", len(scores))

	// --- 2. Slice from fixed array ---
	fmt.println("\n=== Slices ===")
	all := scores[:]       // slice of entire array
	first_three := scores[0:3]  // slice of first 3

	sum :: proc(values: []i32) -> i32 {
		total : i32 = 0
		for v in values {
			total += v
		}
		return total
	}
	fmt.println("  sum of all:", sum(all))
	fmt.println("  sum of [0:3]:", sum(first_three))

	// --- 3. Dynamic array ---
	fmt.println("\n=== Dynamic Array ===")
	names: [dynamic]string
	defer delete(names)   // cleaned up when main exits

	append(&names, "Alice")
	append(&names, "Bob")
	append(&names, "Charlie")
	for name, i in names {
		fmt.printf("  names[%d] = %s\n", i, name)
	}
	fmt.printf("  len = %d\n", len(names))

	// --- 4. Mutable iteration ---
	fmt.println("\n=== Mutable Iteration ===")
	values: [5]f32 = {1, 2, 3, 4, 5}
	fmt.print("  before: ")
	for v in values { fmt.printf("%.0f ", v) }
	fmt.println()

	for &v in &values {
		v *= 2   // modify in place
	}
	fmt.print("  after:  ")
	for v in values { fmt.printf("%.0f ", v) }
	fmt.println()

	// --- 5. 2D fixed array (tilemap shape) ---
	fmt.println("\n=== 2D Fixed Array (tilemap preview) ===")
	ROWS :: 3
	COLS :: 4
	grid: [ROWS][COLS]u8 = {
		{ '#', '#', '#', '#' },
		{ '#', '.', '.', '#' },
		{ '#', '#', '#', '#' },
	}
	for row in grid {
		fmt.print("  ")
		for cell in row {
			fmt.printf("%c ", cell)
		}
		fmt.println()
	}

	// --- Key takeaways ---
	fmt.println("\n--- Takeaways ---")
	fmt.println("  [N]T     = fixed, stack, fast, cannot grow")
	fmt.println("  []T      = slice, view into existing data, no allocation")
	fmt.println("  [dynamic]T = heap, growable, must delete")
	fmt.println("  for &v in &arr = mutable iteration")
	fmt.println("  len(x) works on all three types")
}
