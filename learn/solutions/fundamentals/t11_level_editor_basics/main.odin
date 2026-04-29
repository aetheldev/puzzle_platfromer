// TICKET 11 - Level Editor Basics
// ===============================
// GOAL: Build tiny in-game Sokoban editor. Paint walls, goals, boxes and spawn.
//       Export level text to console.
//
// WHAT THIS TEACHES:
//   - Mouse input from `sapp.Event`
//   - Screen grid -> tile coordinates
//   - Editing level data in memory
//   - Tool selection
//   - Very first step toward your own level editor
//
// CONTROLS:
//   - Left mouse: paint selected tile
//   - Right mouse: erase tile
//   - `1`: wall tool
//   - `2`: player spawn tool
//   - `3`: goal tool
//   - `4`: box tool
//   - `C`: clear map
//   - `Enter`: print level to terminal
//
// NOTES:
//   - `#` = wall
//   - `.` = empty
//   - `P` = player spawn
//   - `G` = goal
//   - `B` = box
//   - This format matches `learn/projects/sokoban/levels/*.txt`.

package t11

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"

W :: 960
H :: 540
TILE :: 40
COLS :: W / TILE
ROWS :: H / TILE

Tile :: enum u8 {
	empty,
	solid,
	spawn,
	goal,
	box,
}

tiles: [ROWS][COLS]Tile
selected_tool: Tile = .solid
mouse_x, mouse_y: f32
left_down, right_down: bool

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

clear_spawns :: proc() {
	for row in 0..<ROWS {
		for col in 0..<COLS {
			if tiles[row][col] == .spawn {
				tiles[row][col] = .empty
			}
		}
	}
}

clear_map :: proc() {
	for row in 0..<ROWS {
		for col in 0..<COLS {
			tiles[row][col] = .empty
		}
	}
}

print_level :: proc() {
	fmt.println("---- LEVEL START ----")
	for row in 0..<ROWS {
		line: [COLS]u8
		for col in 0..<COLS {
			switch tiles[row][col] {
			case .empty: line[col] = '.'
			case .solid: line[col] = '#'
			case .spawn: line[col] = 'P'
			case .goal:  line[col] = 'G'
			case .box:   line[col] = 'B'
			}
		}
		fmt.println(string(line[:]))
	}
	fmt.println("---- LEVEL END ----")
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	mouse_x = e.mouse_x
	mouse_y = e.mouse_y

	#partial switch e.type {
	case .MOUSE_DOWN:
		if e.mouse_button == .LEFT { left_down = true }
		if e.mouse_button == .RIGHT { right_down = true }
	case .MOUSE_UP:
		if e.mouse_button == .LEFT { left_down = false }
		if e.mouse_button == .RIGHT { right_down = false }
	case .MOUSE_MOVE:
		mouse_x = e.mouse_x
		mouse_y = e.mouse_y
	case .KEY_DOWN:
		#partial switch e.key_code {
		case ._1: selected_tool = .solid
		case ._2: selected_tool = .spawn
		case ._3: selected_tool = .goal
		case ._4: selected_tool = .box
		case .C:  clear_map()
		case .ENTER: print_level()
		}
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.08, g = 0.09, b = 0.12, a = 1 } } },
	}

	for col in 0..<COLS {
		tiles[ROWS-1][col] = .solid
	}
}

frame :: proc "c" () {
	context = rt_ctx

	col := int(mouse_x / TILE)
	row := int(mouse_y / TILE)
	if col >= 0 && col < COLS && row >= 0 && row < ROWS {
		if left_down {
			if selected_tool == .spawn {
				clear_spawns()
			}
			tiles[row][col] = selected_tool
		}
		if right_down {
			tiles[row][col] = .empty
		}
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	for y in 0..<ROWS {
		for x in 0..<COLS {
			tx := f32(x * TILE)
			ty := f32(y * TILE)
			switch tiles[y][x] {
			case .solid:
				draw_rect(tx, ty, TILE, TILE, 85, 135, 95)
			case .spawn:
				draw_rect(tx, ty, TILE, TILE, 80, 180, 255)
			case .goal:
				draw_rect(tx+8, ty+8, TILE-16, TILE-16, 90, 200, 110)
			case .box:
				draw_rect(tx+6, ty+6, TILE-12, TILE-12, 210, 150, 70)
			case .empty:
			}
		}
	}

	// grid lines
	for x in 0..=COLS {
		px := f32(x * TILE)
		sgl.begin_lines()
		sgl.v2f_c4b(px, 0, 45, 50, 60, 255)
		sgl.v2f_c4b(px, H, 45, 50, 60, 255)
		sgl.end()
	}
	for y in 0..=ROWS {
		py := f32(y * TILE)
		sgl.begin_lines()
		sgl.v2f_c4b(0, py, 45, 50, 60, 255)
		sgl.v2f_c4b(W, py, 45, 50, 60, 255)
		sgl.end()
	}

	// hover highlight
	if col >= 0 && col < COLS && row >= 0 && row < ROWS {
		draw_rect(f32(col*TILE)+2, f32(row*TILE)+2, TILE-4, TILE-4, 240, 220, 90)
	}

	// toolbar
	draw_rect(8, 8, 172, 28, 40, 45, 55)
	if selected_tool == .solid {
		draw_rect(12, 12, 24, 20, 85, 135, 95)
	} else {
		draw_rect(12, 12, 24, 20, 60, 70, 80)
	}
	if selected_tool == .spawn {
		draw_rect(42, 12, 24, 20, 80, 180, 255)
	} else {
		draw_rect(42, 12, 24, 20, 60, 70, 80)
	}
	if selected_tool == .goal {
		draw_rect(72, 12, 24, 20, 90, 200, 110)
	} else {
		draw_rect(72, 12, 24, 20, 60, 70, 80)
	}
	if selected_tool == .box {
		draw_rect(102, 12, 24, 20, 210, 150, 70)
	} else {
		draw_rect(102, 12, 24, 20, 60, 70, 80)
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
		window_title = "T11 - Level Editor Basics",
		logger = { func = slog.func },
	})
}
