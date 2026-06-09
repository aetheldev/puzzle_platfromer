package o07_pointers_and_refs

import "core:fmt"

Vec2 :: struct {
	x, y: f32,
}

print_vec :: proc(label: string, v: Vec2) {
	fmt.printf("  %s: (%f, %f)\n", label, v.x, v.y)
}


double_copy :: proc(v: Vec2) {
	v := v
	v.x *= 2
	v.y *= 2
}

double_real :: proc(v: ^Vec2) {
	v.x *= 2
	v.y *= 2
}


main :: proc() {
	a := Vec2{6, 4}
	print_vec("before double_copy", a)
	double_copy(a)
	print_vec("after double_copy", a)

	print_vec("before double_real", a)
	double_real(&a)
	print_vec("after double_real", a)

	p: ^Vec2 = nil
	if p != nil {
		fmt.println("  p has value:", p.x, p.y)
	} else {
		fmt.println("  p is nil — no data to access")
	}

	vecs: [3]Vec2 = {{1, 1}, {2, 2}, {3, 3}}
	fmt.println("  before:")
	for v, i in vecs {fmt.printf("    [%d] = (%f, %f)\n", i, v.x, v.y)}


	second := &vecs[1]
	second.x = 999
	second.y = 888

	fmt.println("  after modifying element 1 through pointer:")
	for v, i in vecs {fmt.printf("    [%d] = (%f, %f)\n", i, v.x, v.y)}
	fmt.println("  ^ only [1] changed, others untouched")
}

