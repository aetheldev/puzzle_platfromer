package o02_variables_and_types

import "core:fmt"

main :: proc() {
	// --- Inference with := ---
	x := 42               // type inferred as `int`
	greeting := "hello"   // type inferred as `string`

	// --- Explicit types ---
	player_x : f32 = 100.0
	player_y : f32 = 200.0
	health : i32 = 100
	alpha : u8 = 255

	// --- Constants with :: ---
	SCREEN_WIDTH  :: 960
	SCREEN_HEIGHT :: 540

	// --- Casting ---
	speed : f32 = 3.5
	steps : i32 = 10
	total_distance := speed * f32(steps)   // must cast i32 -> f32
	fmt.println("Total distance:", total_distance)

	// --- Booleans ---
	is_alive := true
	has_key  := false
	can_open := is_alive && has_key

	// --- Print everything ---
	fmt.println("x:", x)
	fmt.println("greeting:", greeting)
	fmt.printf("player position: (%f, %f)\n", player_x, player_y)
	fmt.println("health:", health, "alpha:", alpha)
	fmt.println("screen:", SCREEN_WIDTH, "x", SCREEN_HEIGHT)
	fmt.println("pixels:", SCREEN_WIDTH * SCREEN_HEIGHT)
	fmt.println("alive:", is_alive, "key:", has_key, "can open:", can_open)

	// --- Reassignment ---
	player_x = 150.0     // ok: = reassigns existing variable
	fmt.println("moved to:", player_x)

	// --- Type sizes for game dev context ---
	fmt.println("---")
	fmt.println("u8  color (r,g,b,a) = 4 bytes per pixel")
	fmt.println("f32 color (r,g,b,a) = 16 bytes per pixel")
	fmt.println("For 1920x1080 pixels:")
	fmt.println("  u8  = ~8 MB")
	fmt.println("  f32 = ~33 MB")
	fmt.println("Type choice matters.")
}
