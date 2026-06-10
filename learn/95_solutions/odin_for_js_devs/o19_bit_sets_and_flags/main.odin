package o19_bit_sets_and_flags

import "core:fmt"

Ability :: enum {
	double_jump,
	dash,
	wall_climb,
	glide,
}

Ability_Set :: bit_set[Ability]

main :: proc() {
	// --- Create, add, remove, test ---
	abilities: Ability_Set // empty
	abilities = {.double_jump} // set literal
	abilities += {.dash} // add one
	abilities += {.wall_climb, .glide} // add several
	fmt.println("abilities:", abilities)

	abilities -= {.glide} // remove
	fmt.println("after losing glide:", abilities)

	if .double_jump in abilities {
		fmt.println("can double jump")
	}
	if .glide not_in abilities {
		fmt.println("cannot glide")
	}

	// --- Set operations ---
	a := Ability_Set{.dash, .glide}
	b := Ability_Set{.glide, .wall_climb}
	fmt.println("\na =", a)
	fmt.println("b =", b)
	fmt.println("a + b (union):       ", a + b)
	fmt.println("a & b (intersection):", a & b)
	fmt.println("a - b (difference):  ", a - b)

	// --- Cardinality and clear ---
	fmt.println("\nflag count:", card(abilities))
	abilities = {}
	fmt.println("after clear:", abilities, "count:", card(abilities))

	// --- Subset / any-of checks ---
	unlocked := Ability_Set{.double_jump, .dash}
	required := Ability_Set{.dash, .wall_climb}
	fmt.println("\nhave of required:   ", unlocked & required)
	fmt.println("missing for route:  ", required - unlocked)
	fmt.println("can take route?     ", required <= unlocked)
	unlocked += {.wall_climb}
	fmt.println("after unlock, route?", required <= unlocked)

	// --- Input state: the Player_Intent shape (Ticket 075) ---
	Input_Action :: enum {
		left,
		right,
		jump,
	}
	Input_State :: bit_set[Input_Action; u8] // pinned to 1 byte for networking

	frames := [3]Input_State{{.right}, {.right, .jump}, {}}
	fmt.println("\nSimulating frames:")
	for held, i in frames {
		fmt.printf("  frame %d: ", i + 1)
		if .left in held || .right in held {
			fmt.print("moving ")
		}
		if .jump in held {
			fmt.print("jumping ")
		}
		if held == {} {
			fmt.print("idle")
		}
		fmt.println()
	}

	// --- Memory ---
	fmt.println("\n--- Memory ---")
	fmt.println("size_of(Ability_Set):", size_of(Ability_Set), "bytes for 4 flags")
	fmt.println("size_of(Input_State):", size_of(Input_State), "byte  — one memcpy to network")

	fmt.println("\n--- Takeaways ---")
	fmt.println("bit_set = typed flags in one integer.")
	fmt.println("in / not_in to test. += {} / -= {} to change.")
	fmt.println("+ & - <= card() = set algebra, single instructions.")
	fmt.println("Pin backing type (; u8) for serialized data.")
}
