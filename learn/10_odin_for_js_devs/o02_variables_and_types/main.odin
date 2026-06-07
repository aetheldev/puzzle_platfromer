package o02_variables_and_types

import "core:fmt"

SCREEN_WIDTH :: 960
SCREEN_HEIGHT :: 540

main :: proc() {

	x: f32 = 3.4
	y: i32 = 34
	u: u8 = 255
	s: string = "wchttzcn"
	fmt.printf("%f,%d,%d,%s\n", x, y, u, s)

	a := 100
	b: f32 = 100
	c := cast(f32)a + b

	fmt.printf("total pixel: %d", SCREEN_WIDTH * SCREEN_HEIGHT)
}

