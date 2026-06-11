// PRACTICE GAME 01 - Snake
// ========================
// GOAL: Complete classic snake. Eat food, grow, don't bite yourself.
//
// WHAT THIS COMBINES (nothing new!):
//   - t01: window + clear color
//   - t02: drawing rects
//   - t03: keyboard input
//   - t07: grid thinking
//   - o06: dynamic array (the snake body IS one)
//   - o05: enum + switch (direction)
//
// CONTROLS:
//   - Arrows / WASD: turn
//   - R: restart after game over
//
// DESIGN NOTES:
//   - Snake moves on a TIMER (every N frames), not every frame.
//     Input is sampled continuously, applied on move ticks.
//   - Body is [dynamic]Cell. Move = insert new head, pop tail.
//     Eat = insert new head, KEEP tail (that's the growth!).
//   - Speed increases as you eat.

package p01_snake

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"
import "core:math/rand"

W :: 960
H :: 540
TILE :: 30
COLS :: W / TILE // 32
ROWS :: H / TILE // 18

Cell :: struct {
	x, y: int,
}

Dir :: enum {
	up,
	down,
	left,
	right,
}

snake: [dynamic]Cell // index 0 = head
dir: Dir
next_dir: Dir // buffered input; applied on move tick
food: Cell
score: int
game_over: bool

frame_count: int
move_every: int // frames per move tick; lower = faster

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

spawn_food :: proc() {
	// keep rolling until food is not on the snake
	outer: for {
		food = Cell{rand.int_max(COLS), rand.int_max(ROWS)}
		for seg in snake {
			if seg == food {
				continue outer
			}
		}
		return
	}
}

reset :: proc() {
	clear(&snake)
	append(&snake, Cell{COLS / 2, ROWS / 2})
	append(&snake, Cell{COLS / 2 - 1, ROWS / 2})
	append(&snake, Cell{COLS / 2 - 2, ROWS / 2})
	dir = .right
	next_dir = .right
	score = 0
	move_every = 9
	game_over = false
	spawn_food()
	fmt.println("snake ready. arrows/WASD. eat.")
}

move_snake :: proc() {
	// reversing into yourself is not a turn — ignore it
	opposite := [Dir]Dir{.up = .down, .down = .up, .left = .right, .right = .left}
	if next_dir != opposite[dir] {
		dir = next_dir
	}

	head := snake[0]
	switch dir {
	case .up:    head.y -= 1
	case .down:  head.y += 1
	case .left:  head.x -= 1
	case .right: head.x += 1
	}

	// walls kill
	if head.x < 0 || head.x >= COLS || head.y < 0 || head.y >= ROWS {
		game_over = true
		fmt.println("hit the wall. score:", score, "- R to restart")
		return
	}
	// your own body kills
	for seg in snake {
		if seg == head {
			game_over = true
			fmt.println("bit yourself. score:", score, "- R to restart")
			return
		}
	}

	// new head in front...
	inject_at(&snake, 0, head)

	if head == food {
		// ...keep tail = grow by one
		score += 1
		if score % 3 == 0 && move_every > 3 {
			move_every -= 1 // speed up every 3 food
		}
		spawn_food()
	} else {
		// ...pop tail = same length, snake "moved"
		pop(&snake)
	}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN {
		return
	}
	#partial switch e.key_code {
	case .UP, .W:    next_dir = .up
	case .DOWN, .S:  next_dir = .down
	case .LEFT, .A:  next_dir = .left
	case .RIGHT, .D: next_dir = .right
	case .R:
		if game_over {
			reset()
		}
	}
}

draw_cell :: proc(c: Cell, r, g, b: u8, inset: f32 = 2) {
	x := f32(c.x * TILE) + inset
	y := f32(c.y * TILE) + inset
	s := f32(TILE) - inset * 2
	sgl.begin_quads()
	sgl.v2f_c4b(x,     y,     r, g, b, 255)
	sgl.v2f_c4b(x + s, y,     r, g, b, 255)
	sgl.v2f_c4b(x + s, y + s, r, g, b, 255)
	sgl.v2f_c4b(x,     y + s, r, g, b, 255)
	sgl.end()
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	sgl.setup({logger = {func = slog.func}})
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.06, g = 0.08, b = 0.07, a = 1}}},
	}
	reset()
}

frame :: proc "c" () {
	context = rt_ctx

	if !game_over {
		frame_count += 1
		if frame_count >= move_every {
			frame_count = 0
			move_snake()
		}
	}

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// food
	draw_cell(food, 220, 90, 80, 5)

	// snake: head bright, body darker toward tail
	for seg, i in snake {
		if game_over {
			draw_cell(seg, 120, 70, 70)
		} else if i == 0 {
			draw_cell(seg, 130, 230, 120)
		} else {
			fade := u8(max(60, 180 - i * 6))
			draw_cell(seg, 60, fade, 70)
		}
	}

	// score pips along the top
	for i in 0 ..< min(score, 30) {
		x := f32(8 + i * 12)
		sgl.begin_quads()
		sgl.v2f_c4b(x,   4, 230, 200, 90, 255)
		sgl.v2f_c4b(x+8, 4, 230, 200, 90, 255)
		sgl.v2f_c4b(x+8, 10, 230, 200, 90, 255)
		sgl.v2f_c4b(x,   10, 230, 200, 90, 255)
		sgl.end()
	}

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	delete(snake)
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
		window_title = "P01 - Snake",
		logger = {func = slog.func},
	})
}
