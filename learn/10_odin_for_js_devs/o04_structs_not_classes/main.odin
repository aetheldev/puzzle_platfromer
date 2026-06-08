package o04_structs_not_classes

import "core:fmt"
import "core:math"

Vec2 :: struct {
	x, y: f32,
}

length :: proc(v: Vec2) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

scale :: proc(v: ^Vec2, factor: f32) {
	fmt.printfln("before %v", v)
	v.x *= factor
	v.y *= factor
	fmt.printfln("after %v", v)
}

main :: proc() {
	player := Vec2 {
		x = 3,
		y = 4,
	}

	fmt.printfln("player codinates: %v", player)
	fmt.printfln("player codinates length: %f", length(player))
	scale(&player, 5)
}

