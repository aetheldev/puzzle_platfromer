package o01_first_program

import "core:fmt"

main :: proc() {
	// Basic print — like console.log in JS
	fmt.println("Hello from Odin!")

	// Variable with type inference — like `let name = "..."` in JS
	name := "game developer"

	// Formatted print — like printf or template literal
	// %s = string placeholder, \n = newline
	fmt.printf("Welcome, %s!\n", name)

	// Number variables
	x := 42
	y := 3.14

	// Print multiple types
	fmt.printf("integer: %d, float: %f\n", x, y)

	// Expression in print
	fmt.println("Double of x:", x * 2)

	// Multiple values in println — separated by spaces automatically
	fmt.println("x =", x, "  y =", y)
}
