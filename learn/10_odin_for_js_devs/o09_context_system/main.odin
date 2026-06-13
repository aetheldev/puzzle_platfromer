package o09_context_system

import "base:runtime"
import "core:fmt"


rt_ctx: runtime.Context

main :: proc() {
	// ex 1
	fmt.println("=== Context Is Implicit ===")
	fmt.println("  Default allocator:", context.allocator)
	fmt.println("  Temp allocator:", context.temp_allocator)
	fmt.println("  Every proc receives `context` automatically.")

	// ex 2
	fmt.println("\n=== Scoped Modification ===")
	fmt.println("  Outside scope — default allocator:", context.allocator.procedure)

	{
		fmt.println("  Inside scope — context can be changed here")
		fmt.println("  Any proc called here inherits the change")
	}

	fmt.println("  Outside scope again — original context restored")


	// ex 3
	fmt.println("\n=== Why Sokol Callbacks Need context = rt_ctx ===")

	rt_ctx = context

	simulate_c_callback :: proc "c" () {
		context = rt_ctx
		fmt.println("test")
	}
	simulate_c_callback()


  // ex 4
	fmt.println("\n=== Temp Allocator ===")
	s1 := fmt.tprintf("Score: %d", 100)
	s2 := fmt.tprintf("Level: %d", 3)
	s3 := fmt.tprintf("HP: %d/%d", 75, 100)
	fmt.println("  s1:", s1)
	fmt.println("  s2:", s2)
	fmt.println("  s3:", s3)
	fmt.println("  All temp-allocated. No free needed.")
	fmt.println("  In game code, temp allocator resets each frame.")
	fmt.println("  These strings would be invalid next frame.")
}

