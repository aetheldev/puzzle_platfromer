package o11_error_handling

import "core:fmt"

// --- 1. Basic error return ---
safe_divide :: proc(a, b: f32) -> (result: f32, ok: bool) {
	if b == 0 {
		return 0, false
	}
	return a / b, true
}

// --- 2. Proc that might fail ---
load_level :: proc(name: string) -> (data: string, ok: bool) {
	if len(name) == 0 {
		return "", false
	}
	return fmt.tprintf("level data for '%s'", name), true
}

// --- 3. Chain pattern (simulating or_return with bool) ---
load_config :: proc() -> (string, bool) {
	return "config data", true
}

load_game :: proc() -> (string, bool) {
	config, config_ok := load_config()
	if !config_ok { return "", false }

	level, level_ok := load_level("world_1")
	if !level_ok { return "", false }

	return fmt.tprintf("loaded: %s + %s", config, level), true
}

// --- 4. Assert ---
apply_damage :: proc(health: i32, damage: i32) -> i32 {
	assert(damage >= 0, "damage should never be negative")
	result := health - damage
	if result < 0 { result = 0 }
	return result
}

main :: proc() {
	// === Safe divide ===
	fmt.println("=== Error Returns ===")
	result, ok := safe_divide(10, 3)
	fmt.println("  10/3:", result, "ok:", ok)

	bad_result, bad_ok := safe_divide(10, 0)
	fmt.println("  10/0:", bad_result, "ok:", bad_ok)

	// === Load level ===
	fmt.println("\n=== Load Level ===")
	data, load_ok := load_level("dungeon")
	if load_ok {
		fmt.println("  Loaded:", data)
	}

	empty_data, empty_ok := load_level("")
	if !empty_ok {
		fmt.println("  Empty name failed (expected)")
	}
	_ = empty_data

	// === Chain ===
	fmt.println("\n=== Chain Pattern ===")
	game_data, game_ok := load_game()
	if game_ok {
		fmt.println("  Game loaded:", game_data)
	} else {
		fmt.println("  Game load failed")
	}

	// === Assert ===
	fmt.println("\n=== Assert ===")
	hp := apply_damage(100, 30)
	fmt.println("  100 hp - 30 damage =", hp)

	hp2 := apply_damage(20, 50)
	fmt.println("  20 hp - 50 damage =", hp2, "(clamped to 0)")

	// Uncomment to see assert crash:
	// _ = apply_damage(100, -5)  // PANIC: damage should never be negative

	// === Key takeaways ===
	fmt.println("\n--- Takeaways ---")
	fmt.println("  No try/catch. Errors are return values.")
	fmt.println("  (value, ok) pattern for failable operations.")
	fmt.println("  or_return for clean chaining (in real error types).")
	fmt.println("  assert for programmer bugs, not user errors.")
	fmt.println("  You can see from the signature if a proc can fail.")
}
