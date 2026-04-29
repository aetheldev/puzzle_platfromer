/*
Different-View Co-op Prototype
==============================
GOAL: first local co-op puzzle where each player has different collision truth.

RULES:
  - Red uses WASD
  - Blue uses arrow keys
  - Red can walk on red bridges, Blue cannot
  - Blue can walk on blue bridges, Red cannot
  - When both stand on their own pressure plates, central door opens forever
  - Then both must reach goal tiles to win

This is top-down on purpose.
It isolates co-op puzzle logic before platforming complexity.
*/

package prototype

import sapp  "../../../../../sauce/sokol/app"
import sg    "../../../../../sauce/sokol/gfx"
import sgl   "../../../../../sauce/sokol/gl"
import sglue "../../../../../sauce/sokol/glue"
import slog  "../../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540
TILE :: 48
COLS :: 14
ROWS :: 10

Tile :: enum u8 {
	empty,
	wall,
	bridge_red,
	bridge_blue,
	plate_red,
	plate_blue,
	door,
	goal,
}

Player :: struct {
	x, y: int,
	r, g, b: u8,
	uses_red: bool,
	reached_goal: bool,
}

tiles: [ROWS][COLS]Tile
red: Player
blue: Player
door_open: bool
won: bool

MAP :: [ROWS]string{
	"##############",
	"#R..r####b..B#",
	"#...r####b...#",
	"#...r####b...#",
	"#...A####C...#",
	"#......D.....#",
	"#.....GG.....#",
	"#............#",
	"#............#",
	"##############",
}

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(x,   y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
	sgl.v2f_c4b(x,   y+h, r, g, b, 255)
	sgl.end()
}

init_level :: proc() {
	map_data := MAP
	for row in 0..<ROWS {
		for col in 0..<COLS {
			ch := map_data[row][col]
			switch ch {
			case '#': tiles[row][col] = .wall
			case 'r': tiles[row][col] = .bridge_red
			case 'b': tiles[row][col] = .bridge_blue
			case 'A': tiles[row][col] = .plate_red
			case 'C': tiles[row][col] = .plate_blue
			case 'D': tiles[row][col] = .door
			case 'G': tiles[row][col] = .goal
			case 'R':
				red.x = col
				red.y = row
			case 'B':
				blue.x = col
				blue.y = row
			case:
				tiles[row][col] = .empty
			}
		}
	}
	red.r, red.g, red.b = 255, 100, 100
	red.uses_red = true
	blue.r, blue.g, blue.b = 100, 170, 255
	blue.uses_red = false
	door_open = false
	won = false
}

tile_blocks_player :: proc(tile: Tile, p: Player) -> bool {
	#partial switch tile {
	case .wall:
		return true
	case .bridge_red:
		return !p.uses_red
	case .bridge_blue:
		return p.uses_red
	case .door:
		return !door_open
	case:
		return false
	}
}

try_move :: proc(p: ^Player, dx, dy: int) {
	if won do return
	nx := p.x + dx
	ny := p.y + dy
	if nx < 0 || nx >= COLS || ny < 0 || ny >= ROWS { return }
	if tile_blocks_player(tiles[ny][nx], p^) { return }
	p.x = nx
	p.y = ny
}

update_game_state :: proc() {
	red_on_plate := tiles[red.y][red.x] == .plate_red
	blue_on_plate := tiles[blue.y][blue.x] == .plate_blue
	if red_on_plate && blue_on_plate {
		door_open = true
	}
	red.reached_goal = tiles[red.y][red.x] == .goal
	blue.reached_goal = tiles[blue.y][blue.x] == .goal
	won = door_open && red.reached_goal && blue.reached_goal
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN do return
	#partial switch e.key_code {
	case .W:     try_move(&red, 0, -1)
	case .S:     try_move(&red, 0, 1)
	case .A:     try_move(&red, -1, 0)
	case .D:     try_move(&red, 1, 0)
	case .UP:    try_move(&blue, 0, -1)
	case .DOWN:  try_move(&blue, 0, 1)
	case .LEFT:  try_move(&blue, -1, 0)
	case .RIGHT: try_move(&blue, 1, 0)
	case .R:     init_level()
	}
	update_game_state()
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.06, g = 0.07, b = 0.10, a = 1 } } },
	}
	init_level()
	update_game_state()
}

frame :: proc "c" () {
	context = rt_ctx
	offset_x := f32((W - COLS*TILE) / 2)
	offset_y := f32((H - ROWS*TILE) / 2)

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	for row in 0..<ROWS {
		for col in 0..<COLS {
			x := offset_x + f32(col*TILE)
			y := offset_y + f32(row*TILE)
			switch tiles[row][col] {
			case .wall:
				draw_rect(x, y, TILE, TILE, 70, 85, 100)
			case .bridge_red:
				draw_rect(x, y, TILE, TILE, 120, 55, 55)
			case .bridge_blue:
				draw_rect(x, y, TILE, TILE, 55, 85, 140)
			case .plate_red:
				draw_rect(x+10, y+10, TILE-20, TILE-20, 255, 110, 110)
			case .plate_blue:
				draw_rect(x+10, y+10, TILE-20, TILE-20, 110, 180, 255)
			case .door:
				if door_open {
					draw_rect(x+12, y+12, TILE-24, TILE-24, 120, 220, 120)
				} else {
					draw_rect(x, y, TILE, TILE, 170, 140, 70)
				}
			case .goal:
				draw_rect(x+10, y+10, TILE-20, TILE-20, 220, 220, 120)
			case .empty:
				draw_rect(x, y, TILE, TILE, 38, 42, 50)
			}
		}
	}

	draw_rect(offset_x + f32(red.x*TILE) + 8, offset_y + f32(red.y*TILE) + 8, TILE-16, TILE-16, red.r, red.g, red.b)
	draw_rect(offset_x + f32(blue.x*TILE) + 8, offset_y + f32(blue.y*TILE) + 8, TILE-16, TILE-16, blue.r, blue.g, blue.b)

	if red.reached_goal {
		draw_rect(24, 20, 40, 10, 255, 110, 110)
	}
	if blue.reached_goal {
		draw_rect(72, 20, 40, 10, 110, 180, 255)
	}
	if door_open {
		draw_rect(120, 20, 40, 10, 120, 220, 120)
	}
	if won {
		draw_rect(W/2 - 80, 20, 160, 16, 240, 230, 120)
	}

	sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
	sgl.draw()
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	sgl.shutdown()
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run({
		init_cb = init,
		frame_cb = frame,
		event_cb = event,
		cleanup_cb = cleanup,
		width = W,
		height = H,
		window_title = "Different-View Co-op Prototype",
		logger = { func = slog.func },
	})
}
