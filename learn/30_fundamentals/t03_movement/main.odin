package t03

import sapp "../../../sauce/sokol/app"
import sdtx "../../../sauce/sokol/debugtext"
import sg "../../../sauce/sokol/gfx"
import sgl "../../../sauce/sokol/gl"
import sglue "../../../sauce/sokol/glue"
import slog "../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540
SPEED :: 300.0 // pixels per second

Player :: struct {
	x, y: f32, // top-left position
	w, h: f32, // size
}

player: Player

// Key state: true = currently held down
key_left, key_right, key_up, key_down: bool
key_sprint: bool

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	// sokol_gl must be set up after sokol_gfx
	sgl.setup({logger = {func = slog.func}})
	sdtx.setup({fonts = {0 = sdtx.font_kc853()}})
	sdtx.canvas(W, H)
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.1, g = 0.1, b = 0.15, a = 1}}},
	}

	player = {
		x = W / 2 - 20,
		y = H / 2 - 20,
		w = 40,
		h = 40,
	}
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_quads()
	sgl.c3f(f32(r) / 255, f32(g) / 255, f32(b) / 255)
	sgl.v2f(x, y)
	sgl.v2f(x + w, y)
	sgl.v2f(x + w, y + h)
	sgl.v2f(x, y + h)
	sgl.end()
}

frame :: proc "c" () {
	context = rt_ctx

	// --- delta time ---
	dt := f32(sapp.frame_duration()) // seconds since last frame (~0.016 at 60fps)

	// --- input → velocity ---
	vx: f32 = 0
	vy: f32 = 0
	if key_left {vx -= 1}
	if key_right {vx += 1}
	if key_up {vy -= 1}
	if key_down {vy += 1}

	// Normalise so diagonal speed == horizontal speed
	len := math.sqrt(vx * vx + vy * vy)
	if len > 0 {
		vx /= len
		vy /= len
	}

	//  === Ex 3 ===
	run: f32 = SPEED
	if key_sprint {run = SPEED * 2}
	sdtx.pos(5, 20)
	sdtx.printf("player speed: %v", run)

	// --- move player ---
	player.x += vx * run * dt
	player.y += vy * run * dt

	//  === Ex 2 ===
	player.x = clamp(player.x, 0, W - player.w)
	player.y = clamp(player.y, 0, H - player.h)
	sdtx.pos(5, 10)
	sdtx.printf("player x: %v", player.x)
	sdtx.pos(5, 15)
	sdtx.printf("player y: %v", player.y)
	//  === Ex 2 ===


	// --- draw ---
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// ground line
	sgl.begin_lines()
	sgl.c3f(100.0 / 255, 200.0 / 255, 100.0 / 255)
	sgl.v2f(0, H - 40)
	sgl.v2f(W, H - 40)
	sgl.end()

	// player rect
	draw_rect(player.x, player.y, player.w, player.h, 240, 200, 80)

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()
	sdtx.draw()
	sg.end_pass()
	sg.commit()
}

// sokol_app calls this for every input event (key, mouse, etc.)
event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type == .KEY_DOWN || e.type == .KEY_UP {
		held := e.type == .KEY_DOWN
		#partial switch e.key_code {
		case .A, .LEFT:
			key_left = held
		case .D, .RIGHT:
			key_right = held
		case .W, .UP:
			key_up = held
		case .S, .DOWN:
			key_down = held
		case .LEFT_SHIFT, .RIGHT_SHIFT:
			key_sprint = held
		case: // ignore other keys
		}
	}
}

cleanup :: proc "c" () {
	context = rt_ctx
	sdtx.shutdown()
	sgl.shutdown()
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run(
		{
			init_cb = init,
			frame_cb = frame,
			event_cb = event,
			cleanup_cb = cleanup,
			width = W,
			height = H,
			window_title = "T03 – Movement & Delta Time",
			logger = {func = slog.func},
		},
	)
}

