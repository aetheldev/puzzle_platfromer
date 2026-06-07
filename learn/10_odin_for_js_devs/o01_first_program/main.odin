package o01_first_program

import "core:fmt"

main :: proc() {
	fmt.println("Hello from Odin!")

	name := "Aetheldev"

	fmt.printf("my name is %s\n", name)

	x := 5
	y := 5.4

	fmt.printf("x=%d, y=%f\n", x, y)
	fmt.println("Double of x:", x * 2)
}

