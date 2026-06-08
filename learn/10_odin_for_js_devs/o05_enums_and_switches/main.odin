package o05_enums_and_switches

import "core:fmt"
Traffic_Lights :: enum {
	red,
	flashing_red,
	yellow,
	green,
}

Suit :: enum {
	hearts,
	diamonds,
	clubs,
	spades,
}

Tile_Kind :: enum u8 {
	empty,
	wall,
	spike,
	goal,
}

tile_char :: proc(t: Tile_Kind) -> u8 {
	switch t {
	case .empty:
		return '.'
	case .wall:
		return '#'
	case .goal:
		return 'G'
	case .spike:
		return '!'
	}
	return '?'
}


traffic_light :: proc(light: Traffic_Lights) {
	switch light {
	case .red:
		fmt.printfln("stop")
	case .flashing_red:
		fmt.printfln("stop, then go when safe")
	case .yellow:
		fmt.printfln("caution")
	case .green:
		fmt.printfln("go")
	}
}


main :: proc() {
	traffic_light(.red)
	traffic_light(.flashing_red)

	for item in Suit {
		fmt.println("Card:", item)
	}

	g_map := [3][3]Tile_Kind{{.wall, .wall, .wall}, {.wall, .empty, .spike}, {.wall, .wall, .wall}}
	for row in g_map {
		for tile in row {
			fmt.printf("%c ", tile_char(tile))
		}
		fmt.println()
	}

}
