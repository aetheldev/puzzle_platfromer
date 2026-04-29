/*
Sokoban Starter Project
======================
Goal: turn fundamentals into a full puzzle game.

Uses from fundamentals:
  - t03: input and frame loop
  - t07: tilemap thinking
  - t11: level editing mindset

Rules:
  - Push all boxes onto goal tiles.
  - You can push one box.
  - You cannot pull.

Controls:
  - WASD / arrows: move one grid step
  - R: reset level
  - N: next level
  - P: previous level
  - Enter: next level after win

Learning next:
  - add undo
  - add move counter
  - load many levels
  - add ice, switches, teleporters, one-way floors
*/

package sokoban

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"
import "core:strings"

W :: 960
H :: 540
TILE :: 48
COLS :: 12
ROWS :: 10

Cell :: enum u8 {
	empty,
	wall,
	goal,
}

cells: [ROWS][COLS]Cell
boxes: [ROWS][COLS]bool
player_x, player_y: int
move_count: int
won: bool
current_level: int

LEVELS :: [3]string{
	#load("levels/level_01.txt"),
	#load("levels/level_02.txt"),
	#load("levels/level_03.txt"),
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

load_level :: proc(index: int) {
	current_level = index
	levels := LEVELS
	for row in 0..<ROWS {
		for col in 0..<COLS {
			cells[row][col] = .empty
			boxes[row][col] = false
		}
	}
	level_text := levels[index]
	row := 0
	for line in strings.split_lines_iterator(&level_text) {
		if len(line) == 0 { continue }
		for ch, col in line {
			if row >= ROWS || col >= COLS { continue }
			switch ch {
			case '#': cells[row][col] = .wall
			case 'G': cells[row][col] = .goal
			case 'B': boxes[row][col] = true
			case 'P':
				player_x = col
				player_y = row
			}
		}
		row += 1
	}
	move_count = 0
	won = false
}

reset_level :: proc() {
	load_level(current_level)
}

change_level :: proc(dir: int) {
	count := len(LEVELS)
	new_index := (current_level + dir + count) % count
	load_level(new_index)
}

in_bounds :: proc(x, y: int) -> bool {
	return x >= 0 && x < COLS && y >= 0 && y < ROWS
}

is_blocked :: proc(x, y: int) -> bool {
	if !in_bounds(x, y) { return true }
	return cells[y][x] == .wall || boxes[y][x]
}

check_win :: proc() {
	for row in 0..<ROWS {
		for col in 0..<COLS {
			if cells[row][col] == .goal && !boxes[row][col] {
				won = false
				return
			}
		}
	}
	won = true
	fmt.println("Solved in", move_count, "moves")
}

try_move :: proc(dx, dy: int) {
	if won do return
	nx := player_x + dx
	ny := player_y + dy
	if !in_bounds(nx, ny) { return }

	if cells[ny][nx] == .wall { return }

	if boxes[ny][nx] {
		bx := nx + dx
		by := ny + dy
		if is_blocked(bx, by) { return }
		boxes[ny][nx] = false
		boxes[by][bx] = true
	}

	player_x = nx
	player_y = ny
	move_count += 1
	check_win()
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN do return
	#partial switch e.key_code {
	case .ENTER:
		if won {
			change_level(1)
		}
	case .W, .UP:    try_move(0, -1)
	case .S, .DOWN:  try_move(0, 1)
	case .A, .LEFT:  try_move(-1, 0)
	case .D, .RIGHT: try_move(1, 0)
	case .R:         reset_level()
	case .N:         change_level(1)
	case .P:         change_level(-1)
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.07, g = 0.08, b = 0.11, a = 1 } } },
	}
	load_level(0)
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

			switch cells[row][col] {
			case .wall:
				draw_rect(x, y, TILE, TILE, 70, 90, 110)
			case .goal:
				draw_rect(x+10, y+10, TILE-20, TILE-20, 90, 180, 110)
			case .empty:
				draw_rect(x, y, TILE, TILE, 40, 45, 55)
			}

			if boxes[row][col] {
				draw_rect(x+6, y+6, TILE-12, TILE-12, 210, 150, 70)
			}

			sgl.begin_lines()
			sgl.v2f_c4b(x, y, 28, 32, 40, 255)
			sgl.v2f_c4b(x+TILE, y, 28, 32, 40, 255)
			sgl.v2f_c4b(x+TILE, y, 28, 32, 40, 255)
			sgl.v2f_c4b(x+TILE, y+TILE, 28, 32, 40, 255)
			sgl.v2f_c4b(x+TILE, y+TILE, 28, 32, 40, 255)
			sgl.v2f_c4b(x, y+TILE, 28, 32, 40, 255)
			sgl.v2f_c4b(x, y+TILE, 28, 32, 40, 255)
			sgl.v2f_c4b(x, y, 28, 32, 40, 255)
			sgl.end()
		}
	}

	px := offset_x + f32(player_x*TILE)
	py := offset_y + f32(player_y*TILE)
	if won {
		draw_rect(px+8, py+8, TILE-16, TILE-16, 120, 240, 120)
	} else {
		draw_rect(px+8, py+8, TILE-16, TILE-16, 100, 180, 255)
	}

	// simple move counter bars, no text renderer needed
	for i in 0..<move_count {
		draw_rect(20 + f32(i*6), 20, 4, 12, 255, 220, 90)
	}

	// current level indicator
	for i in 0..<len(LEVELS) {
		if i == current_level {
			draw_rect(20 + f32(i*20), 40, 14, 10, 100, 180, 255)
		} else {
			draw_rect(20 + f32(i*20), 40, 14, 10, 70, 80, 95)
		}
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
		window_title = "Sokoban Starter",
		logger = { func = slog.func },
	})
}
