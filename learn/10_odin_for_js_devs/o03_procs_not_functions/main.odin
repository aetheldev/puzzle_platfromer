package o03_procs_not_functions

import "core:fmt"
main :: proc() {
	mul := multiply(5, 5)
	fmt.printfln("multiplied :", mul)

	result, ok := safe_divide(10, 3)
	fmt.println("divide(10, 3) =", result, "ok:", ok)

	bad_result, bad_ok := safe_divide(10, 0)
	fmt.println("divide(10, 0) =", bad_result, "ok:", bad_ok)


	apply_op :: proc(x, y: f32, op: proc(a, b: f32) -> f32) -> f32 {
		return op(x, y)
	}
	applied := apply_op(5, 7, multiply)
	fmt.println("apply_op(5, 7, add) =", applied)
}


multiply :: proc(x, y: f32) -> f32 {
	return x + y
}

safe_divide :: proc(a, b: f32) -> (f32, bool) {
	if b == 0 {
		return 0, false
	}

	return a / b, true
}

