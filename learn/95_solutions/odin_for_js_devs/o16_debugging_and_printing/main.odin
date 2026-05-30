package o16_debugging_and_printing

import "core:fmt"

Player :: struct {
	x, y:     f32,
	health:   i32,
	name:     string,
	is_alive: bool,
}

main :: proc() {
	player := Player{
		x = 100, y = 200,
		health = 85,
		name = "Hero",
		is_alive = true,
	}

	// === 1. println — like console.log ===
	fmt.println("=== println ===")
	fmt.println("  player:", player)
	fmt.println("  pos:", player.x, player.y)
	fmt.println("  name:", player.name, "hp:", player.health)

	// === 2. printf — formatted output ===
	fmt.println("\n=== printf ===")
	fmt.printf("  %s at (%.1f, %.1f) HP: %d alive: %v\n",
		player.name, player.x, player.y, player.health, player.is_alive)

	// %v prints any type in default format
	fmt.printf("  %%v struct: %v\n", player)

	// === 3. tprintf — temp allocated string ===
	fmt.println("\n=== tprintf ===")
	label := fmt.tprintf("[Debug] %s pos=(%.0f,%.0f)", player.name, player.x, player.y)
	fmt.println("  built string:", label)
	fmt.println("  (temp allocated — valid this frame only in game code)")

	// === 4. assert — crash on bad state ===
	fmt.println("\n=== assert ===")
	assert(player.health >= 0, "health must not be negative")
	assert(player.is_alive, "player should be alive here")
	fmt.println("  all assertions passed")
	// Uncomment to see crash:
	// assert(player.health > 1000, "this will fail!")

	// === 5. Conditional debug ===
	fmt.println("\n=== when ODIN_DEBUG ===")
	when ODIN_DEBUG {
		fmt.println("  [DEBUG] this only appears in debug builds")
		fmt.println("  [DEBUG] entity count: 42")
	}
	fmt.println("  (above prints only in -debug builds)")

	// === 6. Gated printing (frame count simulation) ===
	fmt.println("\n=== Gated Printing ===")
	fmt.println("  Simulating 300 frames, printing every 60th:")
	for frame in 0..<300 {
		if frame % 60 == 0 {
			fmt.printf("    frame %d: player at (%.0f, %.0f)\n", frame, player.x, player.y)
		}
	}

	// === 7. Print-then-crash pattern ===
	fmt.println("\n=== Print Then Crash Pattern ===")
	fmt.println("  (Demonstration — not actually crashing)")
	fmt.println("  Pattern:")
	fmt.println("    if entity == nil {")
	fmt.println("        fmt.println(\"BUG: entity not found\", handle)")
	fmt.println("        fmt.println(\"  count:\", len(entities))")
	fmt.println("        assert(false, \"entity lookup failed\")")
	fmt.println("    }")

	// === Key takeaways ===
	fmt.println("\n--- Takeaways ---")
	fmt.println("  fmt.println = console.log")
	fmt.println("  fmt.printf  = formatted output (needs \\n)")
	fmt.println("  fmt.tprintf = build temp string")
	fmt.println("  assert      = crash on programmer error")
	fmt.println("  when ODIN_DEBUG = compile-time debug gate")
	fmt.println("  Gate prints in loops to avoid terminal flood")
	fmt.println("  Print-debug is normal and productive in game dev")

	fmt.println("\n=== Track Complete ===")
	fmt.println("  You finished Odin for JS/TS Developers!")
	fmt.println("  Next: learn/fundamentals/t01_hello_window")
}
