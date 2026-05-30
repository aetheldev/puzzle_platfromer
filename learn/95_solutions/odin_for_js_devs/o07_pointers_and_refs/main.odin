package o07_pointers_and_refs

import "core:fmt"

Vec2 :: struct { x, y: f32 }

// Takes VALUE — gets a copy, cannot modify original
print_vec :: proc(label: string, v: Vec2) {
	fmt.printf("  %s: (%f, %f)\n", label, v.x, v.y)
}

// Takes VALUE — doubles the COPY, original unchanged
double_copy :: proc(v: Vec2) {
	v := v   // shadow to make mutable local copy
	v.x *= 2
	v.y *= 2
	// changes are lost when proc returns
}

// Takes POINTER — doubles the ORIGINAL
double_real :: proc(v: ^Vec2) {
	v.x *= 2   // auto-dereferenced: same as v^.x *= 2
	v.y *= 2
}

main :: proc() {
	// --- Copy behavior ---
	fmt.println("=== Copy vs Pointer ===")
	a := Vec2{ 3, 4 }
	print_vec("before double_copy", a)
	double_copy(a)
	print_vec("after double_copy", a)     // unchanged!
	fmt.println("  ^ copy was modified, original untouched")

	fmt.println()
	b := Vec2{ 3, 4 }
	print_vec("before double_real", b)
	double_real(&b)                        // & = pass address
	print_vec("after double_real", b)      // changed!
	fmt.println("  ^ original modified through pointer")

	// --- Nil pointer ---
	fmt.println("\n=== Nil Pointer ===")
	p: ^Vec2 = nil
	if p != nil {
		fmt.println("  p has value:", p.x, p.y)
	} else {
		fmt.println("  p is nil — no data to access")
	}

	// Now point it at real data
	p = &b
	if p != nil {
		fmt.printf("  p now points to: (%f, %f)\n", p.x, p.y)
	}

	// --- Pointer to array element ---
	fmt.println("\n=== Array Element Pointer ===")
	vecs: [3]Vec2 = {
		{ 1, 1 },
		{ 2, 2 },
		{ 3, 3 },
	}
	fmt.println("  before:")
	for v, i in vecs { fmt.printf("    [%d] = (%f, %f)\n", i, v.x, v.y) }

	// Get pointer to element 1 and modify it
	second := &vecs[1]
	second.x = 999
	second.y = 888

	fmt.println("  after modifying element 1 through pointer:")
	for v, i in vecs { fmt.printf("    [%d] = (%f, %f)\n", i, v.x, v.y) }
	fmt.println("  ^ only [1] changed, others untouched")

	// --- Takeaways ---
	fmt.println("\n--- Takeaways ---")
	fmt.println("  ^T   = pointer type (holds address of a T)")
	fmt.println("  &x   = take address of x")
	fmt.println("  p.x  = access field through pointer (auto-deref)")
	fmt.println("  nil  = pointer to nothing, accessing it crashes")
	fmt.println("  Default = copy. Use ^ and & when you need mutation.")
}
