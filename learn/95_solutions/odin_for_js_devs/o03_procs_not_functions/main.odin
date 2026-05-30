package o03_procs_not_functions

import "core:fmt"

add :: proc(a, b: f32) -> f32 {
	return a + b
}

greet :: proc(name: string) {
	fmt.printf("Hello, %s!\n", name)
}

divide :: proc(a, b: f32) -> (result: f32, ok: bool) {
	if b == 0 {
		return 0, false
	}
	return a / b, true
}

main :: proc() {
	sum := add(10, 3)
	fmt.println("add(10, 3) =", sum)

	greet("game developer")

	result, ok := divide(10, 3)
	fmt.println("divide(10, 3) =", result, "ok:", ok)

	bad_result, bad_ok := divide(10, 0)
	fmt.println("divide(10, 0) =", bad_result, "ok:", bad_ok)

	// --- Higher-order procedure ---
	// A proc that takes another proc as parameter
	apply_op :: proc(a, b: f32, op: proc(f32, f32) -> f32) -> f32 {
		return op(a, b)
	}

	applied := apply_op(5, 7, add)
	fmt.println("apply_op(5, 7, add) =", applied)

	// --- Proc stored in variable ---
	// := creates runtime variable holding proc value (not ::)
	my_op := add
	fmt.println("my_op(100, 200) =", my_op(100, 200))

	// --- About "c" calling convention ---
	// When Sokol (C library) calls your Odin code, you write:
	//   init :: proc "c" () { context = rt_ctx; ... }
	// The "c" tells compiler to use C-compatible calling convention.
	// We do NOT demonstrate "c" here because it requires Sokol.
	// Just know: you will see it in every game lesson starting from t01.

	fmt.println("---")
	fmt.println("Key takeaways:")
	fmt.println("  proc = Odin's function")
	fmt.println("  :: binds proc at compile time")
	fmt.println("  multiple returns: (f32, bool)")
	fmt.println("  no closures, no `this`")
	fmt.println("  pass data explicitly as parameters")
}
