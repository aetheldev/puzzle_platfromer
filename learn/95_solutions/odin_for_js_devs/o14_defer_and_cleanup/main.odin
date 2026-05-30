package o14_defer_and_cleanup

import "core:fmt"

main :: proc() {
	// === 1. Basic defer ===
	fmt.println("=== Basic Defer ===")
	fmt.println("  start")
	defer fmt.println("  end (deferred)")
	fmt.println("  middle")
	// Output: start, middle, end

	// === 2. LIFO order ===
	fmt.println("\n=== LIFO Order ===")
	defer fmt.println("  [A] first defer — runs LAST")
	defer fmt.println("  [B] second defer — runs SECOND")
	defer fmt.println("  [C] third defer — runs FIRST")
	fmt.println("  all three deferred above, now reaching end of main...")

	// === 3. Scoped defer ===
	fmt.println("\n=== Scoped Defer ===")
	{
		fmt.println("  inside block: start")
		defer fmt.println("  inside block: deferred cleanup")
		fmt.println("  inside block: working...")
	}
	fmt.println("  outside block: block defer already ran")

	// === 4. Dynamic array + defer delete ===
	fmt.println("\n=== Allocate + Defer Delete ===")
	scores: [dynamic]i32
	defer delete(scores)   // paired immediately!

	append(&scores, 10)
	append(&scores, 20)
	append(&scores, 30)
	append(&scores, 40)
	append(&scores, 50)

	fmt.print("  scores: ")
	for s in scores { fmt.printf("%d ", s) }
	fmt.println()
	fmt.println("  defer delete(scores) will run at proc exit")

	// === 5. Heap + defer free ===
	fmt.println("\n=== Heap + Defer Free ===")
	Vec2 :: struct { x, y: f32 }
	p := new(Vec2)
	defer free(p)

	p.x = 42
	p.y = 99
	fmt.printf("  heap Vec2: (%f, %f)\n", p.x, p.y)
	fmt.println("  defer free(p) will run at proc exit")

	// === Key takeaways ===
	fmt.println("\n--- Takeaways ---")
	fmt.println("  defer = run at scope exit, guaranteed")
	fmt.println("  LIFO order: last defer runs first")
	fmt.println("  Pair: new/free, make/delete, open/close")
	fmt.println("  Write defer immediately after acquisition")
	fmt.println("  No try/finally needed")
}
