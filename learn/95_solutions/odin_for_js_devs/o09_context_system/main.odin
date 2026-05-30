package o09_context_system

import "core:fmt"
import "base:runtime"

main :: proc() {
	// === 1. Context is always available ===
	fmt.println("=== Context Is Implicit ===")
	fmt.println("  Default allocator:", context.allocator)
	fmt.println("  Temp allocator:", context.temp_allocator)
	fmt.println("  Every proc receives `context` automatically.")

	// === 2. Scoped modification ===
	fmt.println("\n=== Scoped Modification ===")
	fmt.println("  Outside scope — default allocator:", context.allocator.procedure)

	{
		// Modify context inside a scope block
		// (We just demonstrate the concept — in real code you would swap allocator)
		fmt.println("  Inside scope — context can be changed here")
		fmt.println("  Any proc called here inherits the change")
	}

	fmt.println("  Outside scope again — original context restored")

	// === 3. Why "c" procs need context restoration ===
	fmt.println("\n=== Why Sokol Callbacks Need context = rt_ctx ===")

	// Simulate the pattern used in every game lesson:
	//
	//   rt_ctx: runtime.Context
	//
	//   main :: proc() {
	//       rt_ctx = context       // save before C takes over
	//       sapp.run(...)
	//   }
	//
	//   init :: proc "c" () {
	//       context = rt_ctx       // restore inside C callback
	//       // now fmt, new, etc. work
	//   }
	//
	// Without this, "c" procs have garbage context and crash.

	rt_ctx := context              // save context (simulating the real pattern)

	// Simulating what happens inside a "c" callback:
	simulate_c_callback :: proc "c" () {
		// context is INVALID here in a real "c" callback
		// We cannot even call fmt.println without restoring context
	}
	simulate_c_callback()

	// In real game code, the first line of every "c" callback is:
	//   context = rt_ctx
	fmt.println("  Saved context to rt_ctx. C callbacks restore it.")
	fmt.println("  Without this: fmt, new, assert all crash inside callbacks.")

	// === 4. Temp allocator ===
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

	// === Key takeaways ===
	fmt.println("\n--- Takeaways ---")
	fmt.println("  context = implicit parameter on every proc")
	fmt.println("  carries: allocator, temp_allocator, logger, assert handler")
	fmt.println("  scoped changes: { context.X = ...; call_stuff() }")
	fmt.println("  'c' procs: must restore with context = rt_ctx")
	fmt.println("  temp allocator: fast scratch, cleared per frame")
}
