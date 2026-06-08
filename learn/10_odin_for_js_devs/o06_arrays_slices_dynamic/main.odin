package o06_arrays_slices_dynamic

import "core:fmt"

sum :: proc(values: []i32) -> i32 {
	total: i32 = 0
	for v in values {
		total += v
	}
	return total
}

main :: proc() {
	scores: [5]i32 = {10, 20, 30, 40, 50}

	for score, i in scores {
		fmt.println("index: ", i, "value: ", score)
	}

	fmt.println("sum of scores[:]: ", sum(scores[:]), "sum of scores[1:3]: ", sum(scores[1:3]))

	names: [dynamic]string
	defer (delete(names))
	append(&names, "game")
	append(&names, "dev")
	append(&names, "wchttzcn")

	for name in names {
		fmt.println("name", name)
	}

	values: [5]f32 = {1, 2, 3, 4, 5}

	for v in values {
		fmt.println("v", v)
	}
	fmt.println("Doubled ")
	for &v in &values {
		v *= 2
	}
	for v in values {
		fmt.println("v", v)
	}
}

